# SPDX-FileCopyrightText: 2023 Eric Oestrich
# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.VCNL4040 do
  @moduledoc """
  VCNL4040 ambient light and proximity sensor

  Typically found at 0x60
  See the [datasheet](https://www.vishay.com/docs/84274/vcnl4040.pdf)
  Many configuration options aren't implemented.

  Call `set_proximity/3`, `set_ambient_light/3`, and `set_white_light/3` to
  change the state of the sensor.
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer

  defstruct als_config: 0x0000,
            als_low_threshold: 0x0000,
            als_high_threshold: 0x0000,
            ps_low_threshold: 0x0000,
            ps_high_threshold: 0x0000,
            ps_config_1: 0x0000,
            ps_config_2: 0x0000,
            ps_cancellation_level: 0x0000,
            proximity_raw: 0,
            ambient_light_raw: 0,
            white_light_raw: 0

  @type t() :: %__MODULE__{
          als_config: 0..0xFFFF,
          als_low_threshold: 0..0xFFFF,
          als_high_threshold: 0..0xFFFF,
          ps_low_threshold: 0..0xFFFF,
          ps_high_threshold: 0..0xFFFF,
          ps_config_1: 0..0xFFFF,
          ps_config_2: 0..0xFFFF,
          ps_cancellation_level: 0..0xFFFF,
          proximity_raw: 0..0xFFFF,
          ambient_light_raw: 0..0xFFFF,
          white_light_raw: 0..0xFFFF
        }

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new(Keyword.get(args, :state, []))
    I2CServer.child_spec_helper(device, args)
  end

  @spec new(keyword) :: t()
  def new(options \\ []) do
    struct!(__MODULE__, options)
  end

  @spec set_proximity(String.t(), Circuits.I2C.address(), number()) :: :ok
  def set_proximity(bus_name, address, value) do
    I2CServer.send_message(bus_name, address, {:set_proximity, value})
  end

  @spec set_ambient_light(String.t(), Circuits.I2C.address(), number()) :: :ok
  def set_ambient_light(bus_name, address, value) do
    I2CServer.send_message(bus_name, address, {:set_ambient_light, value})
  end

  @spec set_white_light(String.t(), Circuits.I2C.address(), number()) :: :ok
  def set_white_light(bus_name, address, value) do
    I2CServer.send_message(bus_name, address, {:set_white_light, value})
  end

  defimpl I2CDevice do
    require Logger

    # read/write
    @als_config_register 0x00
    @als_high_threshold_register 0x01
    @als_low_threshold_register 0x02
    @ps_config_register_1 0x03
    @ps_config_register_2 0x04
    @ps_cancellation_register 0x05
    @ps_low_threshold_register 0x06
    @ps_high_threshold_register 0x07

    # read only
    @ps_data_register 0x08
    @als_data_register 0x09
    @white_data_register 0x0A
    @als_ps_interrupt_flag_register 0x0B
    @cmd_device_id 0x0C

    @impl I2CDevice
    def read(state, count) do
      {{:ok, :binary.copy(<<0>>, count)}, state}
    end

    @impl I2CDevice
    # second byte is reserved and should always be 0b0000_0000
    def write(state, <<@als_config_register, config, 0>>) do
      <<time::2, 0::2, interrupt_persistence::2, interrupt::1, power::1>> = <<config>>

      config = %{
        integration_time: time,
        interrupt_persistence: interrupt_persistence,
        interrupt_enable: interrupt,
        power_enable: power
      }

      Logger.debug("[VCNL4040] Ambient Light Sensor Config - #{inspect(config)}")

      %{state | als_config: config}
    end

    def write(state, <<@als_high_threshold_register, high::little-16>>) do
      Logger.debug("[VCNL4040] Ambient Light Sensor High Threshold - #{high}")
      %{state | als_high_threshold: high}
    end

    def write(state, <<@als_low_threshold_register, low::little-16>>) do
      Logger.debug("[VCNL4040] Ambient Light Sensor Low Threshold - #{low}")
      %{state | als_low_threshold: low}
    end

    def write(state, <<@ps_config_register_1, low, high>>) do
      <<duty::2, interrupt_persistence::2, time::3, power::1>> = <<low>>
      <<0::4, output_bits::1, 0::1, interrupt::2>> = <<high>>

      config = %{
        duty_ratio: duty,
        interrupt_persistence: interrupt_persistence,
        interrupt_enabled: interrupt,
        integration_time: time,
        output_bits: output_bits,
        power_enable: power
      }

      Logger.debug("[VCNL4040] Proximity Sensor Config - #{inspect(config)}")

      %{state | ps_config_1: config}
    end

    def write(state, <<@ps_config_register_2, low, high>>) do
      <<0::1, proximity_mps::2, smart_persistence::1, af::1, af_trigger::1, 0::1, sunlight::1>> =
        <<low>>

      <<white_channel::1, proximity::1, 0::3, led::3>> = <<high>>

      config = %{
        proximity_mps: proximity_mps,
        smart_persistence: smart_persistence,
        active_force_mode: af,
        active_force_trigger: af_trigger,
        sunlight_cancel_enabled: sunlight,
        white_channel_enabled: white_channel,
        proximity_mode: proximity,
        led_current: led
      }

      Logger.debug("[VCNL4040] Proximity Sensor Config 2 - #{inspect(config)}")

      %{state | ps_config_2: config}
    end

    def write(state, <<@ps_cancellation_register, level::little-16>>) do
      Logger.debug("[VCNL4040] Proximity Sensor Cancellation Level - #{level}")
      %{state | ps_cancellation_level: level}
    end

    def write(state, <<@ps_low_threshold_register, low::little-16>>) do
      Logger.debug("[VCNL4040] Proximity Sensor Low Threshold - #{low}")
      %{state | ps_low_threshold: low}
    end

    def write(state, <<@ps_high_threshold_register, high::little-16>>) do
      Logger.debug("[VCNL4040] Proximity Sensor High Threshold - #{high}")
      %{state | ps_high_threshold: high}
    end

    def write(state, data) do
      Logger.debug("[VCNL4040] Unknown write - #{inspect(data)}")
      state
    end

    @impl I2CDevice
    def write_read(state, <<@ps_data_register>>, 2) do
      {{:ok, <<state.proximity_raw::little-16>>}, state}
    end

    def write_read(state, <<@als_data_register>>, 2) do
      {{:ok, <<state.ambient_light_raw::little-16>>}, state}
    end

    def write_read(state, <<@white_data_register>>, 2) do
      {{:ok, <<state.white_light_raw::little-16>>}, state}
    end

    def write_read(state, <<@als_ps_interrupt_flag_register>>, 2) do
      {{:ok, <<0x00, 0x00>>}, state}
    end

    def write_read(state, <<@cmd_device_id>>, 2) do
      {{:ok, <<0x86, 0x01>>}, state}
    end

    def write_read(state, _value, read_count) do
      {{:ok, :binary.copy(<<0>>, read_count)}, state}
    end

    @impl I2CDevice
    def render(state) do
      state
    end

    @impl I2CDevice
    def handle_message(state, {:set_proximity, value}) do
      {:ok, %{state | proximity_raw: value}}
    end

    def handle_message(state, {:set_ambient_light, value}) do
      {:ok, %{state | ambient_light_raw: value}}
    end

    def handle_message(state, {:set_white_light, value}) do
      {:ok, %{state | white_light_raw: value}}
    end
  end

  defimpl String.Chars do
    @spec to_string(CircuitsSim.Device.VCNL4040.t()) :: String.t()
    def to_string(state) do
      """
      Ambient light sensor output

      Proximity: #{state.proximity_raw}
      Ambient Light: #{state.ambient_light_raw}
      White Light: #{state.white_light_raw}
      """
    end
  end
end
