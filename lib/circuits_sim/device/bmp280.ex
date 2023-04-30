defmodule CircuitsSim.Device.BMP280 do
  @moduledoc """
  Bosch BMP280, BME280, and BME680 sensors

  Most sensors are at address 0x77, but some are at 0x76.
  See the [datasheet](https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf) for details.
  Many features aren't implemented.
  """
  alias CircuitsSim.Device.BMP280.Register
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.I2C.SimpleI2CDevice

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device_options = Keyword.take(args, [:sensor_type])
    device = __MODULE__.new(device_options)
    I2CServer.child_spec_helper(device, args)
  end

  defstruct registers: %{}, sensor_type: nil

  @type sensor_type() :: :bmp180 | :bmp280 | :bme280 | :bme680
  @type options() :: [sensor_type: sensor_type()]
  @type t() :: %__MODULE__{registers: map(), sensor_type: sensor_type()}

  @spec new(options()) :: t()
  def new(options \\ []) do
    sensor_type = options[:sensor_type] || :bme280
    registers = Register.default_registers(sensor_type)
    %__MODULE__{registers: registers, sensor_type: sensor_type}
  end

  ## protocol implementation

  defimpl SimpleI2CDevice do
    @bmp180_reg_control_measurement 0xF4
    @bmp180_set_pressure_reading 0x34
    @bmp180_set_temperature_reading 0x2E
    @bmp280_reg_control_measurement 0xF4
    @bme280_reg_control_measurement 0xF4
    @bme680_reg_status0 0x1D

    @impl SimpleI2CDevice
    def write_register(
          %{sensor_type: :bmp180} = state,
          @bmp180_reg_control_measurement = reg,
          @bmp180_set_pressure_reading = value
        ) do
      registers =
        state.registers
        |> Map.put(reg, value)
        |> Map.merge(Register.measurement_registers(:bmp180, :pressure))

      %{state | registers: registers}
    end

    def write_register(
          %{sensor_type: :bmp180} = state,
          @bmp180_reg_control_measurement = reg,
          @bmp180_set_temperature_reading = value
        ) do
      registers =
        state.registers
        |> Map.put(reg, value)
        |> Map.merge(Register.measurement_registers(:bmp180, :temperature))

      %{state | registers: registers}
    end

    def write_register(
          %{sensor_type: :bmp280} = state,
          @bmp280_reg_control_measurement = reg,
          value
        ) do
      registers =
        state.registers
        |> Map.put(reg, value)
        |> Map.merge(Register.measurement_registers(:bmp280))

      %{state | registers: registers}
    end

    def write_register(
          %{sensor_type: :bme280} = state,
          @bme280_reg_control_measurement = reg,
          value
        ) do
      registers =
        state.registers
        |> Map.put(reg, value)
        |> Map.merge(Register.measurement_registers(:bme280))

      %{state | registers: registers}
    end

    def write_register(state, reg, value) do
      put_in(state.registers[reg], value)
    end

    @impl SimpleI2CDevice
    def read_register(
          %{sensor_type: :bme680} = state,
          @bme680_reg_status0
        ) do
      registers =
        state.registers
        |> Map.merge(Register.measurement_registers(:bme680))

      new_data = 1
      result = <<new_data::1, 0::7>>
      {result, %{state | registers: registers}}
    end

    def read_register(state, reg), do: {state.registers[reg], state}

    @impl SimpleI2CDevice
    def render(state) do
      "Sensor type: #{state.sensor_type}\n"
    end

    @impl SimpleI2CDevice
    def handle_message(state, _message) do
      {:not_implemented, state}
    end
  end
end
