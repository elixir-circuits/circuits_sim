defmodule CircuitsSim.Device.TM1620 do
  @moduledoc """
  TM1620 LED Driver

  See the [datasheet](https://github.com/fhunleth/binary_clock/blob/main/datasheets/TM1620-English.pdf) for details.
  Many features aren't implemented.
  """

  alias CircuitsSim.SPI.SPIDevice
  alias CircuitsSim.SPI.SPIServer

  @typedoc """
  Render mode is how to pretty print the expected LED output

  Modes:

  * `:grid` - a grid of LEDs. Grid dimensions depend on the TM1620 mode
  * `:seven_segment` - render LEDs like they're hooked up to a 7 segment display
  * `:binary_clock` - render LEDs like the Nerves binary clock
  """
  @type render_mode() :: :grid | :seven_segment | :binary_clock

  defstruct digits: 4,
            mode: :auto,
            pulse16: 0,
            data: :binary.copy(<<0>>, 0xB),
            render: :grid

  @type t() :: %__MODULE__{}

  def child_spec(args) do
    device = __MODULE__.new()
    SPIServer.child_spec_helper(device, args)
  end

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @doc """
  Process a TM1620 command
  """
  @spec command(binary(), t()) :: t()
  def command(data, state)

  # Display mode
  def command(<<0::2, _::4, 0::2, _::binary>>, state), do: %{state | digits: 4}
  def command(<<0::2, _::4, 1::2, _::binary>>, state), do: %{state | digits: 5}
  def command(<<0::2, _::4, 2::2, _::binary>>, state), do: %{state | digits: 6}

  # Data command
  def command(<<1::2, _::2, _::2, 0::2, _::binary>>, state), do: %{state | mode: :auto}

  # Display control
  def command(<<2::2, _::2, 0::1, _::3, _::binary>>, state), do: %{state | pulse16: 0}
  def command(<<2::2, _::2, 1::1, 0::3, _::binary>>, state), do: %{state | pulse16: 1}
  def command(<<2::2, _::2, 1::1, 1::3, _::binary>>, state), do: %{state | pulse16: 2}
  def command(<<2::2, _::2, 1::1, 2::3, _::binary>>, state), do: %{state | pulse16: 4}
  def command(<<2::2, _::2, 1::1, 3::3, _::binary>>, state), do: %{state | pulse16: 10}
  def command(<<2::2, _::2, 1::1, 4::3, _::binary>>, state), do: %{state | pulse16: 11}
  def command(<<2::2, _::2, 1::1, 5::3, _::binary>>, state), do: %{state | pulse16: 12}
  def command(<<2::2, _::2, 1::1, 6::3, _::binary>>, state), do: %{state | pulse16: 13}
  def command(<<2::2, _::2, 1::1, 7::3, _::binary>>, state), do: %{state | pulse16: 14}

  # Address command
  def command(<<3::2, _::2, address::4, data::binary>>, state) when address < 12 do
    %{state | data: update_data(state.data, address, data)}
  end

  # Ignore anything else
  def command(_other, state), do: state

  defp update_data(data, _address, <<>>), do: data
  defp update_data(data, address, _updates) when address > 0xB, do: data

  defp update_data(data, address, <<b, rest::binary>>) do
    new_data = put_byte(data, address, b)
    update_data(new_data, address + 1, rest)
  end

  defp put_byte(data, index, value) do
    <<pre::binary-size(index), _, post::binary>> = data
    <<pre::binary, value, post::binary>>
  end

  @doc """
  Draw out 7-segment display digits using TM1620 data
  """
  @spec seven_segment(binary()) :: IO.ANSI.ansidata()
  def seven_segment(data) do
    for row <- 0..2 do
      [
        for <<grid::2-bytes <- data>> do
          for col <- 0..3, do: seg({row, col}, grid)
        end,
        ?\n
      ]
    end
  end

  # Bits are reversed in Elixir from how they're shown in the datasheet.
  # I.e., Elixir goes bit 7 on the left to bit 0 on the right. The datasheet
  # counts up.

  #      ----a----
  #     |         |
  #    f|         |b
  #     |         |
  #      ----g----
  #     |         |
  #    e|         |c
  #     |         |
  #      ----d----   . dp

  # Seg1, bit 0 --> a
  # ..
  # Seg8, bit 7 --> dp
  defp seg({0, 1}, <<_::1, _::1, _::1, _::1, _::1, _::1, _::1, 1::1, _>>), do: "_"
  defp seg({1, 0}, <<_::1, _::1, 1::1, _::1, _::1, _::1, _::1, _::1, _>>), do: "|"
  defp seg({1, 1}, <<_::1, 1::1, _::1, _::1, _::1, _::1, _::1, _::1, _>>), do: "_"
  defp seg({1, 2}, <<_::1, _::1, _::1, _::1, _::1, _::1, 1::1, _::1, _>>), do: "|"
  defp seg({2, 0}, <<_::1, _::1, _::1, 1::1, _::1, _::1, _::1, _::1, _>>), do: "|"
  defp seg({2, 1}, <<_::1, _::1, _::1, _::1, 1::1, _::1, _::1, _::1, _>>), do: "_"
  defp seg({2, 2}, <<_::1, _::1, _::1, _::1, _::1, 1::1, _::1, _::1, _>>), do: "|"
  defp seg({2, 3}, <<1::1, _::1, _::1, _::1, _::1, _::1, _::1, _::1, _>>), do: "."
  defp seg(_, _), do: " "

  @doc """
  Display registers as a grid
  """
  @spec grid(4..6, binary()) :: IO.ANSI.ansidata()
  def grid(digits, data) do
    valid_data = :binary.part(data, 0, digits * 2)
    for <<row_data::2-bytes <- valid_data>>, do: grid_row(digits, row_data)
  end

  defp grid_row(4, <<h::1, g::1, f::1, e::1, d::1, c::1, b::1, a::1, _::4, j::1, i::1, _::2>>) do
    [led(a), led(b), led(c), led(d), led(e), led(f), led(g), led(h), led(i), led(j), ?\n]
  end

  defp grid_row(5, <<h::1, g::1, f::1, e::1, d::1, c::1, b::1, a::1, _::5, i::1, _::2>>) do
    [led(a), led(b), led(c), led(d), led(e), led(f), led(g), led(h), led(i), ?\n]
  end

  defp grid_row(6, <<h::1, g::1, f::1, e::1, d::1, c::1, b::1, a::1, _>>) do
    [led(a), led(b), led(c), led(d), led(e), led(f), led(g), led(h), ?\n]
  end

  defp led(0), do: 0x20
  defp led(1), do: ?*

  # The binary clock board has the TM1620 hooked up in 6x8 mode. Each segment
  # is another binary digit in the order hhmmss. Seg 0 is the tens digit of hours.
  #
  # Row 0:       3          3          3
  # Row 1:       2          2          2
  # Row 2:  1    1     1    1     1    1
  # Row 3:  0    0     0    0     0    0
  #        Seg0 Seg1  Seg2 Seg3  Seg4 Seg5
  #          Hours     Minutes    Seconds
  @spec binary_clock(binary()) :: IO.ANSI.ansidata()
  def binary_clock(data) do
    m = leds_to_map(6, data)

    [
      [" ", c(m, 1, 3), "  ", c(m, 3, 3), "  ", c(m, 5, 3), ?\n],
      [" ", c(m, 1, 2), "  ", c(m, 3, 2), "  ", c(m, 5, 2), ?\n],
      [c(m, 0, 1), c(m, 1, 1), " ", c(m, 2, 1), c(m, 3, 1), " ", c(m, 4, 1), c(m, 5, 1), ?\n],
      [c(m, 0, 0), c(m, 1, 0), " ", c(m, 2, 0), c(m, 3, 0), " ", c(m, 4, 0), c(m, 5, 0), ?\n]
    ]
  end

  defp c(m, seg, bit) do
    case m[{seg, bit}] do
      0 -> "."
      1 -> "o"
    end
  end

  defp leds_to_map(digits, data) do
    for segment <- 0..(digits - 1), reduce: %{} do
      acc ->
        row_data = :binary.part(data, segment * 2, 2)
        led_status(acc, digits, segment, row_data)
    end
  end

  # Not used yet. Comment out to avoid Dialyzer warnings
  # defp led_status(acc, 4, segment, <<_::8, _::4, j::1, _::3>> = data) do
  #   acc |> led_status(5, segment, data) |> Map.put({segment, 9}, j)
  # end

  # defp led_status(acc, 5, segment, <<_::8, _::5, i::1, _::2>> = data) do
  #   acc |> led_status(6, segment, data) |> Map.put({segment, 8}, i)
  # end

  defp led_status(acc, 6, segment, <<h::1, g::1, f::1, e::1, d::1, c::1, b::1, a::1, _::8>>) do
    Map.merge(
      acc,
      %{
        {segment, 0} => a,
        {segment, 1} => b,
        {segment, 2} => c,
        {segment, 3} => d,
        {segment, 4} => e,
        {segment, 5} => f,
        {segment, 6} => g,
        {segment, 7} => h
      }
    )
  end

  defimpl SPIDevice do
    alias CircuitsSim.Device.TM1620

    @impl SPIDevice
    def transfer(state, data) do
      # The device is write only, so just return zeros.
      result = :binary.copy(<<0>>, byte_size(data))
      {result, TM1620.command(data, state)}
    end

    @impl SPIDevice
    def render(state) do
      [
        "Mode: #{state.digits} digits, #{14 - state.digits} segments\n",
        "Brightness: #{state.pulse16}/16\n",
        case state.render do
          :grid -> TM1620.grid(state.digits, state.data)
          :seven_segment -> TM1620.seven_segment(state.data)
          :binary_clock -> TM1620.binary_clock(state.data)
        end
      ]
    end

    @impl SPIDevice
    def handle_message(state, _message) do
      {:unimplemented, state}
    end
  end
end
