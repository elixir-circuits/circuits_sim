defmodule CircuitsSim.Device.ADS7138Test do
  use ExUnit.Case

  alias CircuitsSim.Device.ADS7138

  test "supports empty writes" do
    ads = start_supervised!({ADS7138, bus_name: "i2c-2", address: 0x10})

    assert :ok = GenServer.call(ads, {:write, <<>>})
  end
end
