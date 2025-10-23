# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.SHT4XTest do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Device.SHT4X, as: SHT4XSim

  @i2c_address 0x44

  test "setting SHT4X state", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({SHT4XSim, bus_name: i2c_bus, address: @i2c_address})

    SHT4XSim.set_humidity_rh(i2c_bus, @i2c_address, 12.3)
    SHT4XSim.set_temperature_c(i2c_bus, @i2c_address, 32.1)

    assert to_string(I2CServer.snapshot(i2c_bus, @i2c_address)) ==
             "Temperature: 32.1°C, Relative humidity: 12.3%"
  end

  test "supports SHT4X package", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({SHT4XSim, bus_name: i2c_bus, address: @i2c_address})

    sht_pid =
      start_supervised!({SHT4X, bus_name: i2c_bus, address: @i2c_address, name: test_name})

    SHT4XSim.set_temperature_c(i2c_bus, @i2c_address, 11.1)
    SHT4XSim.set_humidity_rh(i2c_bus, @i2c_address, 33.3)

    measurement = SHT4X.get_sample(sht_pid)
    assert_in_delta measurement.humidity_rh, 33.3, 0.1
    assert_in_delta measurement.temperature_c, 11.1, 0.1
  end
end
