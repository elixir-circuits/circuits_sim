# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.I2C.Bus do
  @moduledoc false

  alias Circuits.I2C.Bus
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Tools

  defstruct [:bus_name]
  @type t() :: %__MODULE__{bus_name: String.t()}

  @spec render(t()) :: String.t()
  def render(%__MODULE__{} = bus) do
    for address <- 0..127 do
      info = I2CServer.render(bus.bus_name, address)
      hex_addr = Tools.hex_byte(address)
      if info != [], do: ["Device 0x#{hex_addr}: \n", info, "\n"], else: []
    end
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
  end

  defimpl Bus do
    @impl Bus
    def flags(%CircuitsSim.I2C.Bus{}) do
      [:supports_empty_write]
    end

    @impl Bus
    def read(%CircuitsSim.I2C.Bus{} = bus, address, count, _options) do
      I2CServer.read(bus.bus_name, address, count)
    end

    @impl Bus
    def write(%CircuitsSim.I2C.Bus{} = bus, address, data, _options) do
      I2CServer.write(bus.bus_name, address, data)
    end

    @impl Bus
    def write_read(
          %CircuitsSim.I2C.Bus{} = bus,
          address,
          write_data,
          read_count,
          _options
        ) do
      I2CServer.write_read(bus.bus_name, address, write_data, read_count)
    end

    @impl Bus
    def close(%CircuitsSim.I2C.Bus{}), do: :ok
  end
end
