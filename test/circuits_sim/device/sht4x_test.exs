defmodule CircuitsSim.Device.SHT4XTest do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CDevice

  test "measurement" do
    {:ok, sht_pid} = SHT4X.start_link(bus_name: "i2c-1")
    assert {:ok, measurement} = SHT4X.measure(sht_pid)
    assert_in_delta measurement.temperature_c, 27.4, 0.1
    assert_in_delta measurement.humidity_rh, 47.2, 0.1
  end
end
