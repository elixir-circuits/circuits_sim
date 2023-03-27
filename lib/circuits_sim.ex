defmodule CircuitsSim do
  @moduledoc """
  Circuits Simulator
  """

  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.I2C.Backend
  alias CircuitsSim.I2C.Bus

  @doc """
  Show information about all simulated devices
  """
  @spec info() :: :ok
  def info() do
    DeviceRegistry.bus_names()
    |> Enum.map(&bus_info/1)
    |> IO.ANSI.format()
    |> IO.puts()
  end

  defp bus_info(bus_name) do
    case Backend.open(bus_name, []) do
      {:ok, i2c} ->
        result = Bus.render(i2c)
        Circuits.I2C.close(i2c)
        ["=== ", bus_name, " ===\n", result]

      _ ->
        []
    end
  end
end
