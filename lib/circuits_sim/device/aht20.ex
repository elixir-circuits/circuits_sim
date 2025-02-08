defmodule CircuitsSim.Device.AHT20 do
  @moduledoc """
  AHT20 temperature and humidity sensor

  Typically found at 0x38
  See the [datasheet](https://cdn-learn.adafruit.com/assets/assets/000/091/676/original/AHT20-datasheet-2020-4-16.pdf)
  Many features aren't implemented.

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

  @spec set_humidity_rh(String.t(), Circuits.I2C.address(), number()) :: :ok
  def set_humidity_rh(bus_name, address, value) when is_number(value) do
    I2CServer.send_message(bus_name, address, {:set_humidity_rh, value})
  end

  @spec set_temperature_c(String.t(), Circuits.I2C.address(), number()) :: :ok
  def set_temperature_c(bus_name, address, value) when is_number(value) do
    I2CServer.send_message(bus_name, address, {:set_temperature_c, value})
  end

  ## protocol implementation

  defimpl I2CDevice do
    @impl I2CDevice
    def read(%{current: :measure} = state, count) do
      result = raw_sample(state) |> trim_pad(count)
      {{:ok, result}, %{state | current: nil}}
    end

    def read(state, count) do
      {{:ok, :binary.copy(<<0>>, count)}, %{state | current: nil}}
    end

    @impl I2CDevice
    def write(state, <<0xBA>>), do: %{state | current: :reset}
    def write(state, <<0xBE, 0x08, 0x00>>), do: %{state | current: :init}
    def write(state, <<0xAC, 0x33, 0x00>>), do: %{state | current: :measure}
    def write(state, _), do: state

    @impl I2CDevice
    def write_read(state, _to_write, read_count) do
      {{:ok, :binary.copy(<<0>>, read_count)}, %{state | current: :reset}}
    end

    defp trim_pad(x, count) when byte_size(x) >= count, do: :binary.part(x, 0, count)
    defp trim_pad(x, count), do: x <> :binary.copy(<<0>>, count - byte_size(x))

    @impl I2CDevice
    def render(state) do
      humidity_rh = Float.round(state.humidity_rh * 1.0, 3)
      temperature_c = Float.round(state.temperature_c * 1.0, 3)
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
      raw_humidity = round(1_048_576 * state.humidity_rh / 100)
      raw_temperature = round((state.temperature_c + 50) * 1_048_576 / 200)
      <<0, raw_humidity::20, raw_temperature::20, 0>>
    end
  end
end
