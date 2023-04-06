defmodule CircuitsSim do
  @moduledoc """
  Circuits Simulator
  """

  alias CircuitsSim.DeviceRegistry

  @doc """
  Show information about all simulated devices
  """
  @spec info() :: :ok
  def info() do
    [i2c_info(), spi_info()]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  defp i2c_info() do
    DeviceRegistry.bus_names(:i2c)
    |> Enum.map(&i2c_bus_info/1)
  end

  defp i2c_bus_info(bus_name) do
    case CircuitsSim.I2C.Backend.open(bus_name, []) do
      {:ok, i2c} ->
        result = CircuitsSim.I2C.Bus.render(i2c)
        Circuits.I2C.close(i2c)
        ["=== ", bus_name, " ===\n", result]

      _ ->
        []
    end
  end

  defp spi_info() do
    DeviceRegistry.bus_names(:spi)
    |> Enum.map(&spi_bus_info/1)
  end

  defp spi_bus_info(bus_name) do
    case CircuitsSim.SPI.Backend.open(bus_name, []) do
      {:ok, spi} ->
        result = CircuitsSim.SPI.Bus.render(spi)
        Circuits.SPI.close(spi)
        ["=== ", bus_name, " ===\n", result]

      _ ->
        []
    end
  end
end
