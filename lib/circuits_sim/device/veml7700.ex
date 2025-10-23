# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.VEML7700 do
  @moduledoc """
  Vishay VEML7700 ambient light sensors. This sim works for VEML6030 as well.

  VEML7700 sensors are at address 0x10; VEML6030 typically at 0x48.
  See the [datasheet](https://www.vishay.com/docs/84286/veml7700.pdf) for details.

  Call `set_state/3` to change the state of the sensor.
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer

  defstruct als_config: 0x0000,
            als_threshold_high: 0x0000,
            als_threshold_low: 0x0000,
            als_power_saving: 0x0000,
            als_output: 0x0000,
            white_output: 0x0000,
            interrupt_status: 0x0000

  @type t() :: %__MODULE__{
          als_config: 0..0xFFFF,
          als_threshold_high: 0..0xFFFF,
          als_threshold_low: 0..0xFFFF,
          als_power_saving: 0..0xFFFF,
          als_output: 0..0xFFFF,
          white_output: 0..0xFFFF,
          interrupt_status: 0..0xFFFF
        }

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    I2CServer.child_spec_helper(device, args)
  end

  @spec new(keyword) :: t()
  def new(_options \\ []) do
    %__MODULE__{}
  end

  @spec set_state(String.t(), Circuits.I2C.address(), keyword()) :: :ok
  def set_state(bus_name, address, kv) do
    I2CServer.send_message(bus_name, address, {:set_state, kv})
  end

  ## protocol implementation

  defimpl I2CDevice do
    @cmd_als_config 0
    @cmd_als_threshold_high 1
    @cmd_als_threshold_low 2
    @cmd_als_power_saving 3
    @cmd_als_output 4
    @cmd_white_output 5
    @cmd_interrupt_status 6

    @impl I2CDevice
    def read(state, count) do
      {{:ok, :binary.copy(<<0>>, count)}, state}
    end

    @impl I2CDevice
    def write(state, <<@cmd_als_config, value::little-16>>) do
      %{state | als_config: value}
    end

    def write(state, <<@cmd_als_threshold_high, data::little-16>>) do
      %{state | als_threshold_high: data}
    end

    def write(state, <<@cmd_als_threshold_low, data::little-16>>) do
      %{state | als_threshold_low: data}
    end

    def write(state, <<@cmd_als_power_saving, data::little-16>>) do
      %{state | als_power_saving: data}
    end

    def write(state, _), do: state

    @impl I2CDevice
    def write_read(state, <<@cmd_als_config>>, read_count) do
      result = <<state.als_config::little-16>> |> trim_pad(read_count)
      {{:ok, result}, state}
    end

    def write_read(state, <<@cmd_als_threshold_high>>, read_count) do
      result = <<state.als_threshold_high>> |> trim_pad(read_count)
      {{:ok, result}, state}
    end

    def write_read(state, <<@cmd_als_threshold_low>>, read_count) do
      result = <<state.als_threshold_low::little-16>> |> trim_pad(read_count)
      {{:ok, result}, state}
    end

    def write_read(state, <<@cmd_als_power_saving>>, read_count) do
      result = <<state.als_power_saving::little-16>> |> trim_pad(read_count)
      {{:ok, result}, state}
    end

    def write_read(state, <<@cmd_als_output>>, read_count) do
      result = <<state.als_output::little-16>> |> trim_pad(read_count)
      {{:ok, result}, state}
    end

    def write_read(state, <<@cmd_white_output>>, read_count) do
      result = <<state.white_output::little-16>> |> trim_pad(read_count)
      {{:ok, result}, state}
    end

    def write_read(state, <<@cmd_interrupt_status>>, read_count) do
      result = <<state.interrupt_status::little-16>> |> trim_pad(read_count)
      {{:ok, result}, state}
    end

    def write_read(state, _to_write, read_count) do
      {{:ok, :binary.copy(<<0>>, read_count)}, state}
    end

    defp trim_pad(x, count) when byte_size(x) >= count, do: :binary.part(x, 0, count)
    defp trim_pad(x, count), do: x <> :binary.copy(<<0>>, count - byte_size(x))

    @impl I2CDevice
    def render(state) do
      state
    end

    @impl I2CDevice
    @spec handle_message(struct, {:set_state, keyword}) :: {:ok, struct}
    def handle_message(state, {:set_state, kv}) do
      {:ok, struct!(state, kv)}
    end
  end

  defimpl String.Chars do
    @spec to_string(CircuitsSim.Device.VEML7700.t()) :: String.t()
    def to_string(state) do
      "Ambient light sensor raw output: #{state.als_output}"
    end
  end
end
