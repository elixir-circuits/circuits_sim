# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.B5ZE do
  @moduledoc """
  Abracon AB-RTCMC-32.768kHz-IBO5-S3 RTC

  Typically found at 0x68

  See the [datasheet](https://abracon.com/Support/AppsManuals/Precisiontiming/Application%20Manual%20AB-RTCMC-32.768kHz-IBO5-S3.pdf) for details.
  """
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.I2C.SimpleI2CDevice
  alias CircuitsSim.Tools

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    I2CServer.child_spec_helper(device, args)
  end

  defstruct registers: %{}

  @type t() :: %__MODULE__{registers: map()}

  @spec new() :: t()
  def new() do
    %__MODULE__{registers: for(r <- 0x00..0x13, into: %{}, do: {r, <<0>>})}
  end

  defimpl SimpleI2CDevice do
    @impl SimpleI2CDevice
    def write_register(state, reg, value), do: put_in(state.registers[reg], <<value>>)

    @impl SimpleI2CDevice
    def read_register(state, reg), do: {state.registers[reg], state}

    @impl SimpleI2CDevice
    def render(state) do
      for {reg, data} <- state.registers do
        [
          "  ",
          Tools.hex_byte(reg),
          ": ",
          for(<<b::1 <- data>>, do: to_string(b)),
          " (",
          reg_name(reg),
          ")\n"
        ]
      end
    end

    @impl SimpleI2CDevice
    def handle_message(state, _message) do
      state
    end

    defp reg_name(0x00), do: "Control 1"
    defp reg_name(0x01), do: "Control 2"
    defp reg_name(0x02), do: "Control 3"
    defp reg_name(0x03), do: "Seconds"
    defp reg_name(0x04), do: "Minutes"
    defp reg_name(0x05), do: "Hours"
    defp reg_name(0x06), do: "Days"
    defp reg_name(0x07), do: "Weekdays"
    defp reg_name(0x08), do: "Months"
    defp reg_name(0x09), do: "Years"
    defp reg_name(0x0A), do: "Minute Alarm"
    defp reg_name(0x0B), do: "Hour Alarm"
    defp reg_name(0x0C), do: "Day Alarm"
    defp reg_name(0x0D), do: "Weekday Alarm"
    defp reg_name(0x0E), do: "Frequency Offset"
    defp reg_name(0x0F), do: "Timer & CLKOUT"
    defp reg_name(0x10), do: "Timer A Clock"
    defp reg_name(0x11), do: "Timer A"
    defp reg_name(0x12), do: "Timer B Clock"
    defp reg_name(0x13), do: "Timer B"
  end
end
