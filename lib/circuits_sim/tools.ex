# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Tools do
  @moduledoc false

  @spec hex_byte(byte()) :: String.t()
  def hex_byte(x) when x >= 0 and x <= 255 do
    Integer.to_string(div(x, 16), 16) <> Integer.to_string(rem(x, 16), 16)
  end
end
