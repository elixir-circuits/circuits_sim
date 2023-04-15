defmodule CircuitsSim.Device.BMP280 do
  @moduledoc """
  Bosch BMP280, BME280, and BME680 sensors

  Most sensors are at address 0x77, but some are at 0x76.
  See the [datasheet](https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf) for details.
  Many features aren't implemented.
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
    %__MODULE__{registers: default_registers()}
  end

  defp default_registers() do
    for(r <- 0x00..0xFF, into: %{}, do: {r, <<0>>})
    |> put_sensor_type_register()
    |> put_calibration_registers()
    |> put_raw_sample_registers()
  end

  defp put_sensor_type_register(%{} = registers) do
    registers |> put_in([reg(:sensor_type)], sensor_type_value(:bme280))
  end

  defp reg(:sensor_type), do: 0xD0
  defp sensor_type_value(:bmp180), do: <<0x55>>
  defp sensor_type_value(:bmp280), do: <<0x58>>
  defp sensor_type_value(:bme280), do: <<0x60>>
  defp sensor_type_value(:bme680), do: <<0x61>>

  defp put_calibration_registers(%{} = registers) do
    [
      # calib00: 26 bytes from 0x88
      {0x88, <<29>>},
      {0x89, <<110>>},
      {0x8A, <<173>>},
      {0x8B, <<102>>},
      {0x8C, <<50>>},
      {0x8D, <<0>>},
      {0x8E, <<27>>},
      {0x8F, <<143>>},
      {0x90, <<56>>},
      {0x91, <<214>>},
      {0x92, <<208>>},
      {0x93, <<11>>},
      {0x94, <<84>>},
      {0x95, <<43>>},
      {0x96, <<15>>},
      {0x97, <<255>>},
      {0x98, <<249>>},
      {0x99, <<255>>},
      {0x9A, <<12>>},
      {0x9B, <<48>>},
      {0x9C, <<32>>},
      {0x9D, <<209>>},
      {0x9E, <<136>>},
      {0x9F, <<19>>},
      {0xA0, <<0>>},
      {0xA1, <<75>>},
      # calib26: 7 bytes from 0xE1
      {0xE1, <<82>>},
      {0xE2, <<1>>},
      {0xE3, <<0>>},
      {0xE4, <<23>>},
      {0xE5, <<44>>},
      {0xE6, <<3>>},
      {0xE7, <<30>>}
    ]
    |> Enum.into(registers)
  end

  defp put_raw_sample_registers(%{} = registers) do
    [
      # press_msb: 8 bytes from 0xF7
      {0xF7, <<69>>},
      {0xF8, <<89>>},
      {0xF9, <<64>>},
      {0xFA, <<130>>},
      {0xFB, <<243>>},
      {0xFC, <<0>>},
      {0xFD, <<137>>},
      {0xFE, <<109>>}
    ]
    |> Enum.into(registers)
  end

  ## protocol implementation

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
          "\n"
        ]
      end
    end

    @impl SimpleI2CDevice
    def handle_message(state, _message), do: state
  end
end
