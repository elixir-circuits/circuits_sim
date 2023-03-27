defmodule CircuitsSim.Device.ADS7138Test do
  use ExUnit.Case

  alias CircuitsSim.Device.ADS7138
  alias CircuitsSim.I2C.I2CDevice

  test "supports empty writes" do
    device = ADS7138.new()

    # Test that it doesn't crash
    assert _ = I2CDevice.write(device, <<>>)
  end
end
