defmodule CircuitsSim.Tools do
  @moduledoc false

  @spec hex_byte(byte()) :: String.t()
  def hex_byte(x) when x >= 0 and x <= 255 do
    Integer.to_string(div(x, 16), 16) <> Integer.to_string(rem(x, 16), 16)
  end
end
