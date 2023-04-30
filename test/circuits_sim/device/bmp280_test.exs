defmodule CircuitsSim.Device.BMP280Test do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Device.BMP280, as: BMP280Sim

  @i2c_address 0x77

  test "setting BMP280 state", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({BMP280Sim, bus_name: i2c_bus, address: @i2c_address, sensor_type: :bme680})

    rendered = I2CServer.render(i2c_bus, @i2c_address)
    assert rendered == "Sensor type: bme680\n"
  end

  describe "BMP280 package" do
    setup context do
      i2c_bus = to_string(context.test)

      start_supervised!(
        {BMP280Sim, bus_name: i2c_bus, address: @i2c_address, sensor_type: context.sensor_type}
      )

      bmp_pid =
        start_supervised!({BMP280, bus_name: i2c_bus, address: @i2c_address, name: context.test})

      {:ok, bmp_pid: bmp_pid}
    end

    @tag sensor_type: :bmp180
    test "supports bmp180", %{bmp_pid: bmp_pid} do
      :ok = BMP280.force_altitude(bmp_pid, 100)
      {:ok, measurement} = BMP280.measure(bmp_pid)
      assert_in_delta measurement.temperature_c, 22.3, 0.1
      assert_in_delta measurement.pressure_pa, 101_132, 1
      assert measurement.humidity_rh == :unknown
      assert measurement.dew_point_c == :unknown
      assert measurement.gas_resistance_ohms == :unknown
    end

    @tag sensor_type: :bmp280
    test "supports bmp280", %{bmp_pid: bmp_pid} do
      :ok = BMP280.force_altitude(bmp_pid, 100)
      {:ok, measurement} = BMP280.measure(bmp_pid)
      assert_in_delta measurement.temperature_c, 26.7, 0.1
      assert_in_delta measurement.pressure_pa, 100_391, 1
      assert measurement.humidity_rh == :unknown
      assert measurement.dew_point_c == :unknown
      assert measurement.gas_resistance_ohms == :unknown
    end

    @tag sensor_type: :bme280
    test "supports bme280", %{bmp_pid: bmp_pid} do
      :ok = BMP280.force_altitude(bmp_pid, 100)
      {:ok, measurement} = BMP280.measure(bmp_pid)
      assert_in_delta measurement.temperature_c, 26.7, 0.1
      assert_in_delta measurement.pressure_pa, 100_391, 1
      assert_in_delta measurement.humidity_rh, 59.2, 0.1
      assert_in_delta measurement.dew_point_c, 18.1, 0.1
      assert measurement.gas_resistance_ohms == :unknown
    end

    @tag sensor_type: :bme680
    test "supports bme680", %{bmp_pid: bmp_pid} do
      :ok = BMP280.force_altitude(bmp_pid, 100)
      {:ok, measurement} = BMP280.measure(bmp_pid)
      assert_in_delta measurement.temperature_c, 19.3, 0.1
      assert_in_delta measurement.pressure_pa, 100_977, 1
      assert_in_delta measurement.humidity_rh, 25.2, 0.1
      assert_in_delta measurement.dew_point_c, -1.1, 0.1
      assert_in_delta measurement.gas_resistance_ohms, 3503.6, 0.1
    end
  end
end
