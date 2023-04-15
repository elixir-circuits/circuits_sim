defmodule CircuitsSim.Device.BMP280Test do
  use ExUnit.Case

  test "simple usage" do
    {:ok, bmp_pid} = BMP280.start_link(bus_name: "i2c-1", bus_address: 0x77)
    assert :ok = BMP280.force_altitude(bmp_pid, 100)
    assert {:ok, measurement} = BMP280.measure(bmp_pid)
    assert_in_delta measurement.temperature_c, 26.7, 0.1
    assert_in_delta measurement.humidity_rh, 59.2, 0.1
    assert_in_delta measurement.pressure_pa, 100_391, 1
  end
end
