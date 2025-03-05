# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Jon Carstens
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2024 Filipe Alves
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.I2C.I2CServer do
  @moduledoc false

  use GenServer

  alias Circuits.I2C
  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.SimpleI2CDevice

  defstruct [:device, :protocol, :register]

  @type init_args :: [bus_name: String.t(), address: Circuits.I2C.address()]

  @doc """
  Helper for creating child_specs for simple I2C implementations
  """
  @spec child_spec_helper(I2CDevice.t() | SimpleI2CDevice.t(), init_args()) :: %{
          :id => __MODULE__,
          :start => {__MODULE__, :start_link, [[any()], ...]}
        }
  def child_spec_helper(device, args) do
    bus_name = Keyword.fetch!(args, :bus_name)
    address = Keyword.fetch!(args, :address)

    combined_args = Keyword.merge([device: device, name: via_name(bus_name, address)], args)

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [combined_args]}
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(init_args) do
    bus_name = Keyword.fetch!(init_args, :bus_name)
    address = Keyword.fetch!(init_args, :address)

    GenServer.start_link(__MODULE__, init_args, name: via_name(bus_name, address))
  end

  # Helper for constructing the via_name for I2CDevice servers
  defp via_name(bus_name, address) do
    DeviceRegistry.via_name(:i2c, bus_name, address)
  end

  # Helper for calling GenServer.call/2 for I2CDevice servers
  #
  # If the server is down, it naks just like a broken I2C device would
  defp gen_call(bus_name, address, message) do
    GenServer.call(via_name(bus_name, address), message)
  catch
    :exit, {:noproc, _} -> {:error, :nak}
  end

  @spec read(String.t(), I2C.address(), non_neg_integer()) ::
          {:ok, binary()} | {:error, any()}
  def read(bus_name, address, count) do
    gen_call(bus_name, address, {:read, count})
  end

  @spec write(String.t(), I2C.address(), iodata()) :: :ok | {:error, any()}
  def write(bus_name, address, data) do
    gen_call(bus_name, address, {:write, data})
  end

  @spec write_read(String.t(), I2C.address(), iodata(), non_neg_integer()) ::
          {:ok, binary()} | {:error, any()}
  def write_read(bus_name, address, data, read_count) do
    gen_call(bus_name, address, {:write_read, data, read_count})
  end

  @spec render(String.t(), I2C.address()) :: IO.ANSI.ansidata()
  def render(bus_name, address) do
    case gen_call(bus_name, address, :render) do
      {:error, _} -> []
      info -> info
    end
  end

  @spec send_message(String.t(), I2C.address(), any()) :: any()
  def send_message(bus_name, address, message) do
    GenServer.call(via_name(bus_name, address), {:send_message, message})
  end

  @impl GenServer
  def init(init_args) do
    device = Keyword.fetch!(init_args, :device)
    protocol = protocol_for(device)

    {:ok, %__MODULE__{device: device, protocol: protocol, register: 0}}
  end

  # Seems like there ought to have been a better way to write this...
  defp protocol_for(s) do
    known_protocols = [I2CDevice, SimpleI2CDevice]

    protocol =
      Enum.find(known_protocols, fn p ->
        impl = Module.concat(p, s.__struct__)
        {:module, impl} == Code.ensure_loaded(impl)
      end)

    protocol ||
      raise "Was expecting #{inspect(s.__struct__)} to implement one of #{inspect(known_protocols)}"
  end

  @impl GenServer
  def handle_call({:read, count}, _from, state) do
    {result, new_state} = do_read(state, count)
    {:reply, result, new_state}
  end

  def handle_call({:write, data}, _from, state) do
    new_state = do_write(state, IO.iodata_to_binary(data))
    {:reply, :ok, new_state}
  end

  def handle_call({:write_read, data, read_count}, _from, state) do
    {result, new_state} = do_write_read(state, IO.iodata_to_binary(data), read_count)
    {:reply, result, new_state}
  end

  def handle_call(:render, _from, state) do
    {:reply, do_render(state), state}
  end

  def handle_call({:send_message, message}, _from, state) do
    {result, new_device} = do_send_message(state, message)
    {:reply, result, %{state | device: new_device}}
  end

  defp do_read(%{protocol: I2CDevice} = state, count) do
    {result, new_device} = I2CDevice.read(state.device, count)
    {result, %{state | device: new_device}}
  end

  defp do_read(%{protocol: SimpleI2CDevice} = state, count) do
    simple_read(state, count, [])
  end

  defp do_write(%{protocol: I2CDevice} = state, data) do
    new_device = I2CDevice.write(state.device, data)
    %{state | device: new_device}
  end

  defp do_write(%{protocol: SimpleI2CDevice} = state, data) do
    simple_write(state, data)
  end

  defp do_write_read(%{protocol: I2CDevice} = state, data, read_count) do
    {result, new_device} = I2CDevice.write_read(state.device, data, read_count)
    {result, %{state | device: new_device}}
  end

  defp do_write_read(%{protocol: SimpleI2CDevice} = state, data, read_count) do
    state |> simple_write(data) |> simple_read(read_count, [])
  end

  defp do_render(%{protocol: I2CDevice} = state) do
    I2CDevice.render(state.device)
  end

  defp do_render(%{protocol: SimpleI2CDevice} = state) do
    SimpleI2CDevice.render(state.device)
  end

  defp do_send_message(%{protocol: I2CDevice} = state, message) do
    I2CDevice.handle_message(state.device, message)
  end

  defp do_send_message(%{protocol: SimpleI2CDevice} = state, message) do
    SimpleI2CDevice.handle_message(state.device, message)
  end

  defp simple_read(state, 0, acc) do
    result = acc |> Enum.reverse() |> :binary.list_to_bin()
    {{:ok, result}, state}
  end

  defp simple_read(state, count, acc) do
    reg = state.register

    {v, device} = SimpleI2CDevice.read_register(state.device, reg)
    new_state = %{state | device: device, register: inc8(reg)}

    simple_read(new_state, count - 1, [v | acc])
  end

  defp simple_write(state, <<>>), do: state
  defp simple_write(state, <<reg>>), do: %{state | register: reg}

  defp simple_write(state, <<reg, value>>) do
    device = SimpleI2CDevice.write_register(state.device, reg, value)
    %{state | device: device, register: inc8(reg)}
  end

  defp simple_write(state, <<reg, value, values::binary>>) do
    device = SimpleI2CDevice.write_register(state.device, reg, value)
    register = inc8(reg)

    new_state = %{state | device: device, register: register}

    do_write(new_state, <<register, values::binary>>)
  end

  defp inc8(255), do: 0
  defp inc8(x), do: x + 1
end
