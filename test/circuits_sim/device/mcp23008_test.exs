# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.MCP23008Test do
  use ExUnit.Case

  alias CircuitsSim.Device.MCP23008
  alias CircuitsSim.I2C.SimpleI2CDevice

  test "reads and writes GPIOs" do
    mcp23008 = MCP23008.new()

    # Set the low 4 I/Os to output mode (reg 0)
    mcp23008 = SimpleI2CDevice.write_register(mcp23008, 0, 0xF0)
    {result, mcp23008} = SimpleI2CDevice.read_register(mcp23008, 0)
    assert result == 0xF0

    # Set the low GPIOs (reg 9) and bogusly set one of the inputs
    mcp23008 = SimpleI2CDevice.write_register(mcp23008, 9, 0x55)
    {result, _mcp23008} = SimpleI2CDevice.read_register(mcp23008, 9)
    assert result == 0x05
  end

  test "renders" do
    mcp23008 =
      MCP23008.new()
      |> SimpleI2CDevice.write_register(0, 0xF0)
      |> SimpleI2CDevice.write_register(9, 0x05)

    actual = SimpleI2CDevice.render(mcp23008) |> IO.ANSI.format(false) |> IO.chardata_to_string()

    expected = """
         Pin: 76543210
       IODIR: IIIIOOOO
        GPIO: 00000101
    """

    assert expected == actual
  end
end
