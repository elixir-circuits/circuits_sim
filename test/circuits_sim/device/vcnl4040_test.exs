# SPDX-FileCopyrightText: 2023 Eric Oestrich
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.VCNL4040Test do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Device.VCNL4040, as: VCNL4040Sim

  @i2c_address 0x60
  @ps_data 0x08
  @als_data 0x09
  @wl_data 0x0A

  test "rendering the sensor", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({VCNL4040Sim, bus_name: i2c_bus, address: @i2c_address})

    rendered = I2CServer.render(i2c_bus, @i2c_address)

    assert to_string(rendered) ==
             "Ambient light sensor output\n\nProximity: 0\nAmbient Light: 0\nWhite Light: 0\n"
  end

  test "supports VCNL4040 package", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({VCNL4040Sim, bus_name: i2c_bus, address: @i2c_address})

    VCNL4040Sim.set_proximity(i2c_bus, @i2c_address, 10)
    VCNL4040Sim.set_ambient_light(i2c_bus, @i2c_address, 50)
    VCNL4040Sim.set_white_light(i2c_bus, @i2c_address, 40)

    assert {:ok, <<10::little-16>>} = I2CServer.write_read(i2c_bus, @i2c_address, <<@ps_data>>, 2)

    assert {:ok, <<50::little-16>>} =
             I2CServer.write_read(i2c_bus, @i2c_address, <<@als_data>>, 2)

    assert {:ok, <<40::little-16>>} = I2CServer.write_read(i2c_bus, @i2c_address, <<@wl_data>>, 2)
  end
end
