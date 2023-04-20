defmodule CircuitsSim.Device.SHT4XTest do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer

  test "simple usage" do
    device = CircuitsSim.Device.SHT4X.new()
    init_arg = [bus_name: "i2c-1", address: 0x44, device: device]
    I2CServer.start_link(init_arg)

    I2CServer.send_message("i2c-1", 0x44, {:set_humidity_rh, 12.3})
    I2CServer.send_message("i2c-1", 0x44, {:set_temperature_c, 32.1})
    assert I2CServer.render("i2c-1", 0x44) == "Humidity RH: 12.3, Temperature C: 32.1"

    I2CServer.send_message("i2c-1", 0x44, {:set_humidity_rh, 50.0})
    I2CServer.send_message("i2c-1", 0x44, {:set_temperature_c, 20.0})
    assert I2CServer.render("i2c-1", 0x44) == "Humidity RH: 50.0, Temperature C: 20.0"
  end

  test "supports SHT4X package" do
    {:ok, sht_pid} = SHT4X.start_link(bus_name: "i2c-1")

    I2CServer.send_message("i2c-1", 0x44, {:set_humidity_rh, 33.3})
    I2CServer.send_message("i2c-1", 0x44, {:set_temperature_c, 11.1})

    {:ok, measurement} = SHT4X.measure(sht_pid)
    assert_in_delta measurement.humidity_rh, 33.3, 0.1
    assert_in_delta measurement.temperature_c, 11.1, 0.1
  end
end
