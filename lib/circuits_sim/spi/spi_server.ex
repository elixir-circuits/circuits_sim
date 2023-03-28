defmodule CircuitsSim.SPI.SPIServer do
  @moduledoc false

  use GenServer

  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.SPI.SPIDevice

  defstruct [:device]

  @type init_args :: [bus_name: String.t()]

  @doc """
  Helper for creating child_specs for simple I2C implementations
  """
  @spec child_spec_helper(SPIDevice.t(), init_args()) :: %{
          :id => __MODULE__,
          :start => {__MODULE__, :start_link, [[any()], ...]}
        }
  def child_spec_helper(device, args) do
    bus_name = Keyword.fetch!(args, :bus_name)

    combined_args = Keyword.merge([device: device, name: via_name(bus_name)], args)

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [combined_args]}
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(init_args) do
    bus_name = Keyword.fetch!(init_args, :bus_name)

    GenServer.start_link(__MODULE__, init_args, name: via_name(bus_name))
  end

  # Helper for constructing the via_name for SPIDevice servers
  defp via_name(bus_name) do
    DeviceRegistry.via_name(bus_name, 0)
  end

  # Helper for calling GenServer.call/2 for SPIDevice servers
  #
  # If the server is down, return an error rather than raise so
  # functions can blindly poll.
  defp gen_call(bus_name, message) do
    GenServer.call(via_name(bus_name), message)
  catch
    :exit, {:noproc, _} -> {:error, :not_running}
  end

  @doc """
  Transfer data to a simulated SPI device

  This returns junk on errors just like a normal SPI device would.
  """
  @spec transfer(String.t(), iodata()) :: {:ok, binary()}
  def transfer(bus_name, data) do
    GenServer.call(via_name(bus_name), {:transfer, data})
  catch
    :exit, {:noproc, _} ->
      junk = :binary.copy(<<0>>, IO.iodata_length(data))
      {:ok, junk}
  end

  @spec render(String.t()) :: IO.ANSI.ansidata()
  def render(bus_name) do
    gen_call(bus_name, :render)
  end

  @impl GenServer
  def init(init_args) do
    device = Keyword.fetch!(init_args, :device)

    {:ok, %__MODULE__{device: device}}
  end

  @impl GenServer
  def handle_call({:transfer, data}, _from, state) do
    {result, new_device} = SPIDevice.transfer(state.device, data)
    {:reply, result, %{state | device: new_device}}
  end

  def handle_call(:render, _from, state) do
    {:reply, SPIDevice.render(state.device), state}
  end
end
