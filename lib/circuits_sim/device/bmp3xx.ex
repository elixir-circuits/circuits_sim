# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.BMP3XX do
  @moduledoc """
  Bosch BMP3XX sensors.

  Most sensors are at address 0x77, but some are at 0x76.
  See the [datasheet](https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf) for details.
  Many features aren't implemented.
  """
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.I2C.SimpleI2CDevice

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device_options = Keyword.take(args, [:sensor_type])
    device = __MODULE__.new(device_options)
    I2CServer.child_spec_helper(device, args)
  end

  defstruct registers: %{}, sensor_type: nil

  @type sensor_type() :: :bmp380 | :bmp390 | :bmp180 | :bmp280 | :bme280 | :bme680
  @type options() :: [sensor_type: sensor_type()]
  @type t() :: %__MODULE__{registers: map(), sensor_type: sensor_type()}

  @spec new(options()) :: t()
  def new(options \\ []) do
    sensor_type = options[:sensor_type] || :bmp380
    %__MODULE__{registers: default_registers(sensor_type), sensor_type: sensor_type}
  end

  @spec default_registers(atom) :: %{byte => byte}
  def default_registers(sensor_type) do
    for(r <- 0x00..0xFF, into: %{}, do: {r, 0})
    |> Map.merge(sensor_type_register(sensor_type))
    |> Map.merge(calibration_registers(sensor_type))
    |> Map.merge(measurement_registers(sensor_type))
  end

  defp sensor_type_register(:bmp380), do: %{0x00 => 0x50}
  defp sensor_type_register(:bmp390), do: %{0x00 => 0x60}
  defp sensor_type_register(:bmp180), do: %{0xD0 => 0x55}
  defp sensor_type_register(:bmp280), do: %{0xD0 => 0x58}
  defp sensor_type_register(:bme280), do: %{0xD0 => 0x60}
  defp sensor_type_register(:bme680), do: %{0xD0 => 0x61}

  @spec calibration_registers(atom) :: %{byte => byte}
  def calibration_registers(sensor_type) when sensor_type in [:bmp380, :bmp390] do
    <<0x236B5849F65CFFCEF42300EA636E79F3F6AA4312C4::8*21>>
    |> binary_to_address_byte_map({0x31, 21})
  end

  def calibration_registers(:bmp180) do
    <<0x1926FBB9C8C885D5644C3F81197300288000D1F60968::8*22>>
    |> binary_to_address_byte_map({0xAA, 22})
  end

  def calibration_registers(:bmp280) do
    <<0x1D6EAD6632001B8F38D6D00B542B0FFFF9FF0C3020D18813::8*24>>
    |> binary_to_address_byte_map({0x88, 24})
  end

  def calibration_registers(:bme280) do
    calib00 =
      <<0x1D6EAD6632001B8F38D6D00B542B0FFFF9FF0C3020D18813004B::8*26>>
      |> binary_to_address_byte_map({0x88, 26})

    calib26 =
      <<82, 1, 0, 23, 44, 3, 30>>
      |> binary_to_address_byte_map({0xE1, 7})

    Map.merge(calib00, calib26)
  end

  def calibration_registers(:bme680) do
    coeff1 =
      <<0xB2660310438A5BD75800E4128AFF1A1E000003FDD9F21E::8*23>>
      |> binary_to_address_byte_map({0x8A, 23})

    coeff2 =
      <<63, 221, 44, 0, 45, 20, 120, 156, 83, 102, 175, 232, 226, 18>>
      |> binary_to_address_byte_map({0xE1, 14})

    coeff3 =
      <<50, 170, 22, 74, 19>>
      |> binary_to_address_byte_map({0x00, 5})

    coeff1 |> Map.merge(coeff2) |> Map.merge(coeff3)
  end

  @spec measurement_registers(atom, any) :: %{byte => byte}
  def measurement_registers(_sensor_type, _options \\ nil)

  def measurement_registers(sensor_type, _) when sensor_type in [:bmp380, :bmp390] do
    <<151, 159, 109, 115, 216, 133>>
    |> binary_to_address_byte_map({0x04, 6})
  end

  def measurement_registers(:bmp180, :temperature) do
    <<95, 16, 0>>
    |> binary_to_address_byte_map({0xF6, 3})
  end

  def measurement_registers(:bmp180, :pressure) do
    <<161, 135, 0>>
    |> binary_to_address_byte_map({0xF6, 3})
  end

  def measurement_registers(:bmp180, _) do
    temperature = measurement_registers(:bmp180, :temperature)
    pressure = measurement_registers(:bmp180, :pressure)
    Map.merge(temperature, pressure)
  end

  def measurement_registers(:bmp280, _) do
    <<69, 89, 64, 130, 243, 0>>
    |> binary_to_address_byte_map({0xF7, 6})
  end

  def measurement_registers(:bme280, _) do
    <<69, 89, 64, 130, 243, 0, 137, 109>>
    |> binary_to_address_byte_map({0xF7, 8})
  end

  def measurement_registers(:bme680, _) do
    pres_msb =
      <<96, 30, 144, 117, 93, 192, 65, 180>>
      |> binary_to_address_byte_map({0x1F, 8})

    gas_r_msb =
      <<166, 139>>
      |> binary_to_address_byte_map({0x2A, 2})

    Map.merge(pres_msb, gas_r_msb)
  end

  defp binary_to_address_byte_map(data, {address, how_many}) do
    addresses = address..(address + how_many - 1)
    bytes = for(<<r::8 <- data>>, do: r)
    Enum.zip(addresses, bytes) |> Map.new()
  end

  ## protocol implementation

  defimpl SimpleI2CDevice do
    alias CircuitsSim.Device.BMP3XX, as: BMP3Sim

    # https://cdn-shop.adafruit.com/datasheets/BST-BMP180-DS000-09.pdf
    @bmp180_reg_control_measurement 0xF4
    @bmp180_pressure_measurement 0x34
    @bmp180_temperature_measurement 0x2E
    @bme680_reg_status0 0x1D

    @impl SimpleI2CDevice
    def write_register(state, @bmp180_reg_control_measurement, @bmp180_pressure_measurement)
        when state.sensor_type == :bmp180 do
      registers = Map.merge(state.registers, BMP3Sim.measurement_registers(:bmp180, :pressure))
      %{state | registers: registers}
    end

    def write_register(state, @bmp180_reg_control_measurement, @bmp180_temperature_measurement)
        when state.sensor_type == :bmp180 do
      registers = Map.merge(state.registers, BMP3Sim.measurement_registers(:bmp180, :temperature))
      %{state | registers: registers}
    end

    def write_register(state, reg, value) do
      put_in(state.registers[reg], value)
    end

    @impl SimpleI2CDevice
    def read_register(state, @bme680_reg_status0) when state.sensor_type == :bme680 do
      registers = Map.merge(state.registers, BMP3Sim.measurement_registers(:bme680))

      new_data = 1
      result = <<new_data::1, 0::7>>
      {result, %{state | registers: registers}}
    end

    def read_register(state, reg) do
      {state.registers[reg], state}
    end

    @impl SimpleI2CDevice
    def snapshot(state) do
      state
    end

    @impl SimpleI2CDevice
    def handle_message(state, _message) do
      {:not_implemented, state}
    end
  end

  defimpl String.Chars do
    @spec to_string(CircuitsSim.Device.BMP3XX.t()) :: String.t()
    def to_string(state) do
      "Sensor type: #{state.sensor_type}"
    end
  end
end
