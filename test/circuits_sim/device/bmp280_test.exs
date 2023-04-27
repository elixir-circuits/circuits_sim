defmodule CircuitsSim.Device.BMP280Test do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Device.BMP280, as: BMP280Sim

  @i2c_address 0x77

  test "setting BMP280 state", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({BMP280Sim, bus_name: i2c_bus, address: @i2c_address})

    BMP280Sim.set_sensor_type(i2c_bus, @i2c_address, :bme680)
    assert I2CServer.render(i2c_bus, @i2c_address) == "Sensor type: bme680"
  end

  test "supports BMP280 package", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({BMP280Sim, bus_name: i2c_bus, address: @i2c_address})

    bmp_pid =
      start_supervised!({BMP280, bus_name: i2c_bus, address: @i2c_address, name: test_name})

    {:ok, measurement} = BMP280.measure(bmp_pid)
    assert_in_delta measurement.humidity_rh, 59.2, 0.1
    assert_in_delta measurement.temperature_c, 26.7, 0.1
    assert_in_delta measurement.pressure_pa, 100_391, 1
  end
end
