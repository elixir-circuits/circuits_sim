defmodule CircuitsSim.Device.SHT4X do
  @moduledoc """
  Sensirion SHT4x sensors

  Typically found at 0x44
  See the [datasheet](https://cdn-learn.adafruit.com/assets/assets/000/099/223/original/Sensirion_Humidity_Sensors_SHT4x_Datasheet.pdf) for details.

  Call `set_humidity_rh/3` and `set_temperature_c/3` to change the state of the sensor.
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer

  defstruct current: nil, humidity_rh: 50.0, temperature_c: 20.0
  @type t() :: %__MODULE__{current: atom(), humidity_rh: float(), temperature_c: float()}

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    I2CServer.child_spec_helper(device, args)
  end

  @spec new() :: %__MODULE__{current: nil, humidity_rh: float(), temperature_c: float()}

  def new() do
    %__MODULE__{}
  end

  @spec set_humidity_rh(String.t(), Circuits.I2C.address(), float()) :: :ok
  def set_humidity_rh(bus_name, address, value) when is_number(value) do
    I2CServer.send_message(bus_name, address, {:set_humidity_rh, value})
  end

  @spec set_temperature_c(String.t(), Circuits.I2C.address(), float()) :: :ok
  def set_temperature_c(bus_name, address, value) when is_number(value) do
    I2CServer.send_message(bus_name, address, {:set_temperature_c, value})
  end

  ## protocol implementation

  defimpl I2CDevice do
    @impl I2CDevice
    def read(%{current: :serial_number} = state, count) do
      result = <<15, 186, 124, 249, 143, 14>> |> trim_pad(count)
      {result, %{state | current: nil}}
    end

    def read(%{current: :measure_high_repeatability} = state, count) do
      result = raw_sample(state) |> trim_pad(count)
      {result, %{state | current: nil}}
    end

    def read(%{current: :measure_medium_repeatability} = state, count) do
      result = raw_sample(state) |> trim_pad(count)
      {result, %{state | current: nil}}
    end

    def read(%{current: :measure_low_repeatability} = state, count) do
      result = raw_sample(state) |> trim_pad(count)
      {result, %{state | current: nil}}
    end

    def read(state, count) do
      {:binary.copy(<<0>>, count), %{state | current: nil}}
    end

    @impl I2CDevice
    def write(state, <<0x89>>), do: %{state | current: :serial_number}
    def write(state, <<0xFD>>), do: %{state | current: :measure_high_repeatability}
    def write(state, <<0xF6>>), do: %{state | current: :measure_medium_repeatability}
    def write(state, <<0xE0>>), do: %{state | current: :measure_low_repeatability}
    def write(state, _), do: state

    @impl I2CDevice
    def write_read(state, _to_write, read_count) do
      {:binary.copy(<<0>>, read_count), %{state | current: nil}}
    end

    defp trim_pad(x, count) when byte_size(x) >= count, do: :binary.part(x, 0, count)
    defp trim_pad(x, count), do: x <> :binary.copy(<<0>>, count - byte_size(x))

    @impl I2CDevice
    def render(state) do
      humidity_rh = Float.round(state.humidity_rh, 3)
      temperature_c = Float.round(state.temperature_c, 3)
      "Temperature: #{temperature_c}°C, Relative humidity: #{humidity_rh}%"
    end

    @impl I2CDevice
    def handle_message(state, {:set_humidity_rh, value}) do
      {:ok, %{state | humidity_rh: value}}
    end

    def handle_message(state, {:set_temperature_c, value}) do
      {:ok, %{state | temperature_c: value}}
    end

    defp raw_sample(state) do
      raw_rh = trunc((state.humidity_rh + 6) * (0xFFFF - 1) / 125)
      raw_t = trunc((state.temperature_c + 45) * (0xFFFF - 1) / 175)
      crc1 = SHT4X.Calc.checksum(<<raw_t::16>>)
      crc2 = SHT4X.Calc.checksum(<<raw_rh::16>>)
      <<raw_t::16, crc1, raw_rh::16, crc2>>
    end
  end
end
