defmodule CircuitsSim.Device.BMP280 do
  @moduledoc """
  Bosch BMP280, BME280, and BME680 sensors

  Most sensors are at address 0x77, but some are at 0x76.
  See the [datasheet](https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf) for details.
  Many features aren't implemented.
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer

  defstruct sensor_type: :bme280

  @type t() :: %__MODULE__{sensor_type: atom()}

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device_options = Keyword.take(args, [:sensor_type])
    device = __MODULE__.new(device_options)
    I2CServer.child_spec_helper(device, args)
  end

  @type options() :: [sensor_type: atom()]

  @spec new(options()) :: %__MODULE__{sensor_type: atom()}
  def new(options \\ []) do
    sensor_type = options[:sensor_type] || :bme280
    %__MODULE__{sensor_type: sensor_type}
  end

  @spec set_sensor_type(String.t(), Circuits.I2C.address(), atom()) :: :ok
  def set_sensor_type(bus_name, address, value) when is_atom(value) do
    I2CServer.send_message(bus_name, address, {:set_sensor_type, value})
  end

  ## protocol implementation

  defimpl I2CDevice do
    @reg_sensor_type 0xD0
    @reg_calib00 0x88
    @reg_calib26 0xE1
    @reg_press_msb 0xF7

    @impl I2CDevice
    def read(%{sensor_type: _any} = state, count) do
      {:binary.copy(<<0>>, count), state}
    end

    @impl I2CDevice
    def write(state, _), do: state

    @impl I2CDevice
    def write_read(%{sensor_type: _any} = state, <<@reg_sensor_type>>, read_count) do
      result = binary_for_sensor_type(state) |> trim_pad(read_count)
      {result, state}
    end

    def write_read(%{sensor_type: :bme280} = state, <<@reg_calib00>>, read_count) do
      result = binary_for_calib00(state) |> trim_pad(read_count)
      {result, state}
    end

    def write_read(%{sensor_type: :bme280} = state, <<@reg_calib26>>, read_count) do
      result = binary_for_calib26(state) |> trim_pad(read_count)
      {result, state}
    end

    def write_read(%{sensor_type: :bme280} = state, <<@reg_press_msb>>, read_count) do
      result = binary_for_press_msb(state) |> trim_pad(read_count)
      {result, state}
    end

    def write_read(%{sensor_type: _any} = state, _to_write, read_count) do
      {:binary.copy(<<0>>, read_count), state}
    end

    defp trim_pad(x, count) when byte_size(x) >= count, do: :binary.part(x, 0, count)
    defp trim_pad(x, count), do: x <> :binary.copy(<<0>>, count - byte_size(x))

    @impl I2CDevice
    def render(state) do
      "Sensor type: #{state.sensor_type}"
    end

    @impl I2CDevice
    def handle_message(state, {:set_sensor_type, value}) do
      {:ok, %{state | sensor_type: value}}
    end

    defp binary_for_sensor_type(%{sensor_type: :bmp180}), do: <<0x55>>
    defp binary_for_sensor_type(%{sensor_type: :bmp280}), do: <<0x58>>
    defp binary_for_sensor_type(%{sensor_type: :bme280}), do: <<0x60>>
    defp binary_for_sensor_type(%{sensor_type: :bme680}), do: <<0x61>>

    defp binary_for_calib00(%{sensor_type: :bme280}) do
      <<29, 110, 173, 102, 50, 0, 27, 143, 56, 214, 208, 11, 84, 43, 15, 255, 249, 255, 12, 48,
        32, 209, 136, 19, 0, 75>>
    end

    defp binary_for_calib26(%{sensor_type: :bme280}) do
      <<82, 1, 0, 23, 44, 3, 30>>
    end

    defp binary_for_press_msb(%{sensor_type: :bme280}) do
      <<69, 89, 64, 130, 243, 0, 137, 109>>
    end
  end
end
