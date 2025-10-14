# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.AHT20Test do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Device.AHT20, as: AHT20Sim

  @i2c_address 0x38

  test "setting AHT20 state", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({AHT20Sim, bus_name: i2c_bus, address: @i2c_address})

    AHT20Sim.set_humidity_rh(i2c_bus, @i2c_address, 12.3)
    AHT20Sim.set_temperature_c(i2c_bus, @i2c_address, 32.1)

    assert to_string(I2CServer.render(i2c_bus, @i2c_address)) ==
             "Temperature: 32.1°C, Relative humidity: 12.3%"
  end

  test "supports AHT20 package", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({AHT20Sim, bus_name: i2c_bus, address: @i2c_address})

    aht_pid =
      start_supervised!({AHT20, bus_name: i2c_bus, address: @i2c_address, name: test_name})

    AHT20Sim.set_temperature_c(i2c_bus, @i2c_address, 11.1)
    AHT20Sim.set_humidity_rh(i2c_bus, @i2c_address, 33.3)

    {:ok, measurement} = AHT20.measure(aht_pid)
    assert_in_delta measurement.humidity_rh, 33.3, 0.1
    assert_in_delta measurement.temperature_c, 11.1, 0.1
  end
end
