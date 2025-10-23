# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.AT24C02 do
  @moduledoc """
  This is a 2 Kb (256 byte) I2C EEPROM

  This does not implementing the paging, so it's forgiving of writes across
  EEPROM write pages. If you use a real AT24C02, make sure not to cross 8-byte
  boundaries when writing more than one byte.
  """
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.I2C.SimpleI2CDevice
  alias CircuitsSim.Tools

  defstruct [:contents]

  # There's got to be a better way to type a 256-tuple
  @type t() :: %__MODULE__{
          contents:
            {:_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
             :_, :_, :_, :_}
        }

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    I2CServer.child_spec_helper(device, args)
  end

  @spec new() :: t()
  def new() do
    %__MODULE__{contents: Tuple.duplicate(0xFF, 256)}
  end

  defimpl SimpleI2CDevice do
    @impl SimpleI2CDevice
    def write_register(state, reg, value) do
      %{state | contents: put_elem(state.contents, reg, value)}
    end

    @impl SimpleI2CDevice
    def read_register(state, reg) do
      {elem(state.contents, reg), state}
    end

    @impl SimpleI2CDevice
    def snapshot(state) do
      state
    end

    @impl SimpleI2CDevice
    def handle_message(state, _message) do
      state
    end
  end

  defimpl String.Chars do
    alias CircuitsSim.Tools

    @spec to_string(CircuitsSim.Device.AT24C02.t()) :: String.t()
    def to_string(state) do
      header = for i <- 0..15, do: ["  ", Integer.to_string(i, 16)]

      [
        "   ",
        header,
        "\n",
        for i <- 0..255 do
          front = if rem(i, 16) == 0, do: [Tools.hex_byte(i), ": "], else: []
          v = elem(state.contents, i)
          term = if rem(i, 16) == 15, do: "\n", else: " "
          [front, Tools.hex_byte(v), term]
        end
      ]
      |> IO.iodata_to_binary()
    end
  end
end
