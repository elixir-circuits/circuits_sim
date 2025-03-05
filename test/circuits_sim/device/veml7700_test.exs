# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.VEML7700Test do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Device.VEML7700, as: VEML7700Sim

  @i2c_address 0x48
  @cmd_config 0x00
  @cmd_light 0x04

  setup context do
    i2c_bus = to_string(context.test)
    start_supervised!({VEML7700Sim, bus_name: i2c_bus, address: @i2c_address})

    [i2c_bus: i2c_bus]
  end

  test "setting VEML7700 state", %{i2c_bus: i2c_bus} do
    VEML7700Sim.set_state(i2c_bus, @i2c_address, als_output: 123)
    assert I2CServer.render(i2c_bus, @i2c_address) == "Ambient light sensor raw output: 123"
  end

  test "reads and writes registers", %{i2c_bus: i2c_bus} do
    VEML7700Sim.set_state(i2c_bus, @i2c_address, als_config: 0, als_output: 440)

    # read ambient light sensor settings
    assert {:ok, <<0, 0>>} = I2CServer.write_read(i2c_bus, @i2c_address, <<@cmd_config>>, 2)

    # write ambient light sensor settings
    config = 0b0001100000000000
    assert :ok = I2CServer.write(i2c_bus, @i2c_address, <<@cmd_config, config::little-16>>)

    # read ambient light sensor settings
    assert {:ok, <<0, 24>>} = I2CServer.write_read(i2c_bus, @i2c_address, <<@cmd_config>>, 2)

    # read ambient light sensor output data
    assert {:ok, <<440::little-16>>} =
             I2CServer.write_read(i2c_bus, @i2c_address, <<@cmd_light>>, 2)
  end
end
