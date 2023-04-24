defmodule CircuitsSim.Device.AHT20Test do
  use ExUnit.Case

  test "simple usage", %{test: test_name} do
    alias CircuitsSim.I2C.I2CServer
    alias CircuitsSim.Device.AHT20

    init_arg = [bus_name: "i2c-1", address: 0x38, device: AHT20.new(), name: test_name]
    start_supervised({I2CServer, init_arg})

    AHT20.set_humidity_rh("i2c-1", 0x38, 12.3)
    AHT20.set_temperature_c("i2c-1", 0x38, 32.1)
    assert I2CServer.render("i2c-1", 0x38) == "Temperature: 32.1°C, Relative humidity: 12.3%"

    AHT20.set_humidity_rh("i2c-1", 0x38, 50.0)
    AHT20.set_temperature_c("i2c-1", 0x38, 20.0)
    assert I2CServer.render("i2c-1", 0x38) == "Temperature: 20.0°C, Relative humidity: 50.0%"
  end

  test "supports AHT20 package", %{test: test_name} do
    init_arg = [bus_name: "i2c-1", address: 0x38, name: test_name]
    start_supervised({AHT20, init_arg})

    {:ok, measurement} = AHT20.measure(test_name)
    assert_in_delta measurement.humidity_rh, 50.0, 0.1
    assert_in_delta measurement.temperature_c, 20.0, 0.1
  end
end
