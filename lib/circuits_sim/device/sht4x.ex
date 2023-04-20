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

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @spec set_humidity_rh(String.t(), Circuits.I2C.address(), float()) :: :ok
  def set_humidity_rh(bus_name, address, humidity_rh) when is_number(humidity_rh) do
    I2CServer.send_message(bus_name, address, {:set_humidity_rh, humidity_rh})
  end

  @spec set_temperature_c(String.t(), Circuits.I2C.address(), float()) :: :ok
  def set_temperature_c(bus_name, address, temperature_c) when is_number(temperature_c) do
    I2CServer.send_message(bus_name, address, {:set_temperature_c, temperature_c})
  end

  ## protocol implementation

  defimpl I2CDevice do
    @impl I2CDevice
    def read(%{current: :serial_number} = state, 6) do
      {<<15, 186, 124, 249, 143, 14>>, %{state | current: nil}}
    end

    def read(%{current: :measure_high_repeatability} = state, 6) do
      {raw_sample(state), %{state | current: nil}}
    end

    def read(%{current: :measure_medium_repeatability} = state, 6) do
      {raw_sample(state), %{state | current: nil}}
    end

    def read(%{current: :measure_low_repeatability} = state, 6) do
      {raw_sample(state), %{state | current: nil}}
    end

    def read(state, 6) do
      {<<0, 0, 0, 0, 0, 0>>, %{state | current: nil}}
    end

    @impl I2CDevice
    def write(state, <<0x89>>), do: %{state | current: :serial_number}
    def write(state, <<0xFD>>), do: %{state | current: :measure_high_repeatability}
    def write(state, <<0xF6>>), do: %{state | current: :measure_medium_repeatability}
    def write(state, <<0xE0>>), do: %{state | current: :measure_low_repeatability}
    def write(state, _), do: state

    @impl I2CDevice
    def write_read(state, _, _), do: {<<>>, state}

    @impl I2CDevice
    def render(state) do
      humidity_rh = Float.round(state.humidity_rh, 3)
      temperature_c = Float.round(state.temperature_c, 3)
      "Humidity RH: #{humidity_rh}, Temperature C: #{temperature_c}"
    end

    @impl I2CDevice
    def handle_message(state, {:set_humidity_rh, humidity_rh}) do
      {:ok, %{state | humidity_rh: humidity_rh}}
    end

    def handle_message(state, {:set_temperature_c, temperature_c}) do
      {:ok, %{state | temperature_c: temperature_c}}
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
