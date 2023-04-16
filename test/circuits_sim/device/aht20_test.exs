defmodule CircuitsSim.Device.AHT20Test do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer

  test "simple usage" do
    device = CircuitsSim.Device.AHT20.new()
    init_arg = [bus_name: "i2c-1", address: 0x38, device: device]
    I2CServer.start_link(init_arg)

    I2CServer.send_message("i2c-1", 0x38, {:set_humidity_rh, 12.3})
    I2CServer.send_message("i2c-1", 0x38, {:set_temperature_c, 32.1})
    assert I2CServer.render("i2c-1", 0x38) == "Temperature: 32.1°C, Relative humidity: 12.3%"

    I2CServer.send_message("i2c-1", 0x38, {:set_humidity_rh, 50.0})
    I2CServer.send_message("i2c-1", 0x38, {:set_temperature_c, 20.0})
    assert I2CServer.render("i2c-1", 0x38) == "Temperature: 20.0°C, Relative humidity: 50.0%"
  end

  test "supports AHT20 package" do
    {:ok, aht_pid} = AHT20.start_link(bus_name: "i2c-1")

    I2CServer.send_message("i2c-1", 0x38, {:set_humidity_rh, 33.3})
    I2CServer.send_message("i2c-1", 0x38, {:set_temperature_c, 11.1})

    {:ok, measurement} = AHT20.measure(aht_pid)
    assert_in_delta measurement.humidity_rh, 33.3, 0.1
    assert_in_delta measurement.temperature_c, 11.1, 0.1
  end
end
