# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.GPIO.GPIOServer do
  @moduledoc false

  use GenServer

  alias Circuits.GPIO
  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.GPIO.GPIODevice

  require Logger

  defstruct gpio_spec: nil,
            device: nil,
            direction: :input,
            pull_mode: :none,
            cached_value: 0,
            interrupt_receiver: nil,
            interrupt_trigger: :none

  @type init_args :: [gpio_spec: GPIO.gpio_spec()]

  @doc """
  Helper for creating child_specs for simple I2C implementations
  """
  @spec child_spec_helper(GPIODevice.t(), init_args()) :: %{
          :id => __MODULE__,
          :start => {__MODULE__, :start_link, [[any()], ...]}
        }
  def child_spec_helper(device, args) do
    gpio_spec = Keyword.fetch!(args, :gpio_spec)

    combined_args = Keyword.merge([device: device, name: via_name(gpio_spec)], args)

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [combined_args]}
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(init_args) do
    gpio_spec = Keyword.fetch!(init_args, :gpio_spec)

    GenServer.start_link(__MODULE__, init_args, name: via_name(gpio_spec))
  end

  # Helper for constructing the via_name for GPIODevice servers
  defp via_name(gpio_spec) do
    DeviceRegistry.via_name(:gpio, gpio_spec, 0)
  end

  @spec write(GPIO.gpio_spec(), GPIO.value()) :: :ok
  def write(gpio_spec, value) do
    GenServer.call(via_name(gpio_spec), {:write, value})
  end

  @spec read(GPIO.gpio_spec()) :: GPIO.value()
  def read(gpio_spec) do
    GenServer.call(via_name(gpio_spec), :read)
  end

  @spec set_direction(GPIO.gpio_spec(), GPIO.direction()) :: :ok | {:error, atom()}
  def set_direction(gpio_spec, direction) do
    GenServer.call(via_name(gpio_spec), {:set_direction, direction})
  end

  @spec set_interrupts(GPIO.gpio_spec(), GPIO.trigger(), GPIO.interrupt_options()) ::
          :ok | {:error, atom()}
  def set_interrupts(gpio_spec, trigger, options) do
    receiver = options[:receiver] || self()
    GenServer.call(via_name(gpio_spec), {:set_interrupts, trigger, receiver})
  end

  @spec set_pull_mode(GPIO.gpio_spec(), GPIO.pull_mode()) :: :ok | {:error, atom()}
  def set_pull_mode(gpio_spec, pull_mode) do
    GenServer.call(via_name(gpio_spec), {:set_pull_mode, pull_mode})
  end

  @spec render(GPIO.gpio_spec()) :: IO.ANSI.ansidata()
  def render(gpio_spec) do
    GenServer.call(via_name(gpio_spec), :render)
  end

  @spec send_message(GPIO.gpio_spec(), any()) :: any()
  def send_message(gpio_spec, message) do
    GenServer.call(via_name(gpio_spec), {:send_message, message})
  end

  @impl GenServer
  def init(init_args) do
    gpio_spec = Keyword.fetch!(init_args, :gpio_spec)
    device = Keyword.fetch!(init_args, :device)

    {:ok, %__MODULE__{gpio_spec: gpio_spec, device: device}}
  end

  @impl GenServer
  def handle_call({:write, value}, _from, state) do
    case state.direction do
      :output ->
        new_device = GPIODevice.write(state.device, value)
        handle_gpio_change(state, state.cached_value, value)

        {:reply, :ok, %{state | device: new_device, cached_value: value}}

      :input ->
        Logger.warning("Ignoring write to input GPIO #{inspect(state.gpio_spec)}")
        {:reply, :ok, state}
    end
  end

  def handle_call(:read, _from, state) do
    {value, new_state} = do_read(state)
    {:reply, value, new_state}
  end

  def handle_call({:set_direction, direction}, _from, state) do
    {:reply, :ok, %{state | direction: direction}}
  end

  def handle_call({:set_pull_mode, mode}, _from, state) do
    {:reply, :ok, %{state | pull_mode: mode}}
  end

  def handle_call({:set_interrupts, trigger, receiver}, _from, state) do
    new_state = %{state | interrupt_receiver: receiver, interrupt_trigger: trigger}

    {:reply, :ok, new_state}
  end

  def handle_call(:render, _from, state) do
    {:reply, GPIODevice.render(state.device), state}
  end

  def handle_call({:send_message, message}, _from, state) do
    {result, new_device} = GPIODevice.handle_message(state.device, message)
    state = %{state | device: new_device}

    # Perform a read just in case the state changed and interrupt messages
    # need to be sent.
    {_value, state} = do_read(state)

    {:reply, result, state}
  end

  @impl GenServer
  def handle_info(message, state) do
    new_device = GPIODevice.handle_info(state.device, message)
    state = %{state | device: new_device}

    # Perform a read just in case the state changed and interrupt messages
    # need to be sent.
    {_value, state} = do_read(state)

    {:noreply, state}
  end

  defp do_read(state) do
    case state.direction do
      :output ->
        {state.cached_value, state}

      :input ->
        raw_value = GPIODevice.read(state.device)
        value = process_read(state, raw_value)
        handle_gpio_change(state, state.cached_value, value)
        {value, %{state | cached_value: value}}
    end
  end

  defp process_read(_state, value) when is_integer(value), do: value
  defp process_read(%{pull_mode: :pullup}, :hi_z), do: 1
  defp process_read(%{pull_mode: :pulldown}, :hi_z), do: 0

  defp process_read(state, :hi_z) do
    Logger.warning(
      "GPIO #{inspect(state.gpio_spec)} is in high impedance state. Set pull mode to reliably read."
    )

    0
  end

  defp handle_gpio_change(%{interrupt_receiver: nil}, _old_value, _value), do: :ok

  defp handle_gpio_change(%{interrupt_trigger: :both} = state, old_value, value)
       when old_value != value do
    send_interrupt_message(state, value)
  end

  defp handle_gpio_change(%{interrupt_trigger: :rising} = state, old_value, value)
       when old_value < value do
    send_interrupt_message(state, value)
  end

  defp handle_gpio_change(%{interrupt_trigger: :falling} = state, old_value, value)
       when old_value > value do
    send_interrupt_message(state, value)
  end

  defp handle_gpio_change(_state, _old_value, _value), do: :ok

  defp send_interrupt_message(state, value) do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_ns = uptime_ms * 1_000_000
    send(state.interrupt_receiver, {:circuits_gpio, state.gpio_spec, uptime_ns, value})
  end
end
