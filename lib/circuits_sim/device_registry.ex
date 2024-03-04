defmodule CircuitsSim.DeviceRegistry do
  @moduledoc false

  alias Circuits.GPIO
  alias Circuits.I2C

  @type type() :: :i2c | :spi | :gpio | :all

  @spec via_name(type(), String.t() | GPIO.gpio_spec(), I2C.address()) ::
          {:via, Registry, tuple()}
  def via_name(type, bus, address) do
    {:via, Registry, {CircuitSim.DeviceRegistry, {type, bus, address}}}
  end

  @spec bus_names(type()) :: [String.t() | GPIO.gpio_spec()]
  def bus_names(type) do
    # The select returns [{{:i2c, "i2c-0", 32}}]
    Registry.select(CircuitSim.DeviceRegistry, [{{:"$1", :_, :_}, [], [{{:"$1"}}]}])
    |> Enum.filter(fn {{bus_type, _, _}} -> bus_type == type or type == :all end)
    |> Enum.map(&extract_bus_name/1)
    |> Enum.uniq()
  end

  defp extract_bus_name({{_type, bus_name, _address}}), do: bus_name
end
