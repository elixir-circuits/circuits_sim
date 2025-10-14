# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.TM1620Test do
  use ExUnit.Case

  alias CircuitsSim.Device.TM1620
  alias CircuitsSim.SPI.SPIDevice

  test "simple usage" do
    leds = TM1620.new(render: :binary_clock)

    # Initialize and display 12:34:56 on the clock
    {_, leds} = SPIDevice.transfer(leds, <<0b00000010>>)
    {_, leds} = SPIDevice.transfer(leds, <<0x40>>)
    {_, leds} = SPIDevice.transfer(leds, <<0xC0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0>>)
    {_, leds} = SPIDevice.transfer(leds, <<0x88>>)

    actual =
      SPIDevice.render(leds)
      |> to_string()

    expected =
      [
        "Mode: 6 digits, 8 segments\n",
        "Brightness: 1/16\n",
        " .  .  .\n",
        " .  o  o\n",
        ".o o. .o\n",
        "o. o. o.\n"
      ]
      |> IO.chardata_to_string()

    assert actual == expected
  end

  describe "seven segment ascii art" do
    test "each segment" do
      # Light up all LEDs except a, b, c, ..., g, dp.
      actual =
        TM1620.seven_segment(
          <<0xFE, 0, 0xFD, 0, 0xFB, 0, 0xF7, 0, 0xEF, 0, 0xDF, 0, 0xBF, 0, 0x7F, 0>>
        )
        |> IO.ANSI.format(false)
        |> IO.chardata_to_string()

      expected =
        [
          "     _   _   _   _   _   _   _  \n",
          "|_| |_  |_| |_| |_|  _| | | |_| \n",
          "|_|.|_|.|_ .| |. _|.|_|.|_|.|_| \n"
        ]
        |> IO.chardata_to_string()

      assert actual == expected
    end

    test "numbers" do
      # Light up all LEDs as numbers
      actual =
        TM1620.seven_segment(
          #    0        1        2        3        4        5        6        7        8        9
          <<0x3F, 0, 0x06, 0, 0x5B, 0, 0x4F, 0, 0x66, 0, 0x6D, 0, 0x7D, 0, 0x07, 0, 0x7F, 0, 0x6F,
            0>>
        )
        |> IO.ANSI.format(false)
        |> IO.chardata_to_string()

      expected =
        [
          " _       _   _       _   _   _   _   _  \n",
          "| |   |  _|  _| |_| |_  |_    | |_| |_| \n",
          "|_|   | |_   _|   |  _| |_|   | |_|  _| \n"
        ]
        |> IO.chardata_to_string()

      assert actual == expected
    end
  end

  describe "grid ascii art" do
    test "10x4" do
      actual =
        TM1620.grid(4, <<0xAA, 0x08, 0x55, 0x04, 0xAA, 0x08, 0x55, 0x04, 0xFF, 0xFF, 0xFF, 0xFF>>)
        |> IO.ANSI.format(false)
        |> IO.chardata_to_string()

      expected =
        [" * * * * *\n", "* * * * * \n", " * * * * *\n", "* * * * * \n"]
        |> IO.chardata_to_string()

      assert actual == expected
    end

    test "9x5" do
      actual =
        TM1620.grid(5, <<0xAA, 0xFB, 0x55, 0x04, 0xAA, 0xFB, 0x55, 0x04, 0xAA, 0xFB, 0xFF, 0xFF>>)
        |> IO.ANSI.format(false)
        |> IO.chardata_to_string()

      expected =
        [" * * * * \n", "* * * * *\n", " * * * * \n", "* * * * *\n", " * * * * \n"]
        |> IO.chardata_to_string()

      assert actual == expected
    end

    test "8x6" do
      actual =
        TM1620.grid(6, <<0xAA, 0xFF, 0x55, 0xFF, 0xAA, 0xFF, 0x55, 0xFF, 0xAA, 0xFF, 0x55, 0xFF>>)
        |> IO.ANSI.format(false)
        |> IO.chardata_to_string()

      expected =
        [" * * * *\n", "* * * * \n", " * * * *\n", "* * * * \n", " * * * *\n", "* * * * \n"]
        |> IO.chardata_to_string()

      assert actual == expected
    end
  end

  test "binary clock ascii art" do
    actual =
      TM1620.binary_clock(<<1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0>>)
      |> IO.ANSI.format(false)
      |> IO.chardata_to_string()

    expected = """
     .  .  .
     .  o  o
    .o o. .o
    o. o. o.
    """

    assert actual == expected
  end
end
