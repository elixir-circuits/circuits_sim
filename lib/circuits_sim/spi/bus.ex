defmodule CircuitsSim.SPI.Bus do
  @moduledoc false

  alias Circuits.SPI.Bus
  alias CircuitsSim.SPI.SPIServer

  defstruct [:bus_name, :config]
  @type t() :: %__MODULE__{bus_name: String.t(), config: Circuits.SPI.spi_option_map()}

  @spec render(t()) :: String.t()
  def render(%__MODULE__{} = bus) do
    SPIServer.render(bus.bus_name)
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
  end

  defimpl Bus do
    @impl Bus
    def config(%CircuitsSim.SPI.Bus{} = bus) do
      {:ok, bus.config}
    end

    @impl Bus
    def transfer(%CircuitsSim.SPI.Bus{} = bus, data) do
      SPIServer.transfer(bus.bus_name, data)
    end

    @impl Bus
    def close(%CircuitsSim.SPI.Bus{}), do: :ok

    @impl Bus
    def max_transfer_size(%CircuitsSim.SPI.Bus{}), do: 1024
  end
end
