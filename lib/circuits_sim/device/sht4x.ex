defmodule CircuitsSim.Device.SHT4X do
  @moduledoc """
  Sensirion SHT4x sensors

  Typically found at 0x44
  See the [datasheet](https://cdn-learn.adafruit.com/assets/assets/000/099/223/original/Sensirion_Humidity_Sensors_SHT4x_Datasheet.pdf) for details.

  Call `set_humidity_rh/3` and `set_temperature_c/3` to change the state of the sensor.
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer

  defstruct current: nil,
            serial_number: 0x12345678,
            humidity_rh: 30.0,
            temperature_c: 22.2,
            crc_injection_count: 0,
            broken: nil,
            acc: <<>>

  @type t() :: %__MODULE__{
          current: atom(),
          serial_number: integer(),
          humidity_rh: float(),
          temperature_c: float(),
          crc_injection_count: non_neg_integer(),
          broken: nil | {:error, any()},
          acc: binary()
        }

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device_options = Keyword.take(args, [:serial_number])
    device = __MODULE__.new(device_options)
    I2CServer.child_spec_helper(device, args)
  end

  @type options() :: [serial_number: integer()]

  @spec new(options()) :: %__MODULE__{
          current: nil,
          serial_number: integer(),
          humidity_rh: float(),
          temperature_c: float(),
          crc_injection_count: non_neg_integer(),
          acc: binary()
        }
  def new(options \\ []) do
    serial_number = options[:serial_number] || 0
    %__MODULE__{serial_number: serial_number}
  end

  @spec set_humidity_rh(String.t(), Circuits.I2C.address(), number()) :: :ok
  def set_humidity_rh(bus_name, address, value) when is_number(value) do
    I2CServer.send_message(bus_name, address, {:set_humidity_rh, value})
  end

  @spec set_temperature_c(String.t(), Circuits.I2C.address(), number()) :: :ok
  def set_temperature_c(bus_name, address, value) when is_number(value) do
    I2CServer.send_message(bus_name, address, {:set_temperature_c, value})
  end

  @doc """
  Inject CRC errors into the next n CRC fields

  Currently all messages have 2 CRC fields, so this will cause CRC mismatch
  errors on the next n/2 messages.
  """
  @spec inject_crc_errors(String.t(), Circuits.I2C.address(), non_neg_integer()) :: :ok
  def inject_crc_errors(bus_name, address, count) when is_integer(count) do
    I2CServer.send_message(bus_name, address, {:inject_crc_errors, count})
  end

  @doc """
  Experimental API to return I2C errors on read/read_writes

  Set the 3rd argument to an error tuple to be returned or `nil` to work
  normally.
  """
  @spec set_broken(String.t(), Circuits.I2C.address(), nil | {:error, any()}) :: :ok
  def set_broken(bus_name, address, broken) do
    I2CServer.send_message(bus_name, address, {:set_broken, broken})
  end

  ## protocol implementation

  defimpl I2CDevice do
    @crc_alg :cerlc.init(:crc8_sensirion)

    @impl I2CDevice
    def read(%{broken: result} = state, _count) when is_tuple(result) do
      {result, state}
    end

    def read(%{current: :serial_number} = state, count) do
      state |> binary_for_serial_number() |> flush_read_to_result(count)
    end

    def read(%{current: op} = state, count)
        when op in [
               :measure_high_repeatability,
               :measure_medium_repeatability,
               :measure_low_repeatability
             ] do
      state |> raw_sample() |> flush_read_to_result(count)
    end

    def read(state, count) do
      flush_read_to_result(state, count)
    end

    defp flush_read_to_result(state, count) do
      {{:ok, trim_pad(state.acc, count)}, %{state | current: nil, acc: <<>>}}
    end

    @impl I2CDevice
    def write(state, <<0x89>>), do: %{state | current: :serial_number}
    def write(state, <<0xFD>>), do: %{state | current: :measure_high_repeatability}
    def write(state, <<0xF6>>), do: %{state | current: :measure_medium_repeatability}
    def write(state, <<0xE0>>), do: %{state | current: :measure_low_repeatability}
    def write(state, _), do: state

    @impl I2CDevice
    def write_read(%{broken: result} = state, _to_write, _read_count) when is_tuple(result) do
      {result, state}
    end

    def write_read(state, _to_write, read_count) do
      {{:ok, :binary.copy(<<0>>, read_count)}, %{state | current: nil}}
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

    def handle_message(state, {:inject_crc_errors, count}) do
      {:ok, %{state | crc_injection_count: count}}
    end

    def handle_message(state, {:set_broken, value}) do
      {:ok, %{state | broken: value}}
    end

    defp binary_for_serial_number(state) do
      state |> add_crcs(<<state.serial_number::32>>)
    end

    defp raw_sample(state) do
      raw_rh = round((state.humidity_rh + 6) * (0xFFFF - 1) / 125)
      raw_t = round((state.temperature_c + 45) * (0xFFFF - 1) / 175)

      state |> add_crcs(<<raw_t::16, raw_rh::16>>)
    end

    defp add_crcs(state, <<>>), do: state

    defp add_crcs(state, <<val::2-bytes, rest::binary>>) do
      {next_state, crc} = crc(state, val)
      this_part = <<val::2-bytes, crc>>
      add_crcs(%{next_state | acc: state.acc <> this_part}, rest)
    end

    defp crc(%{crc_injection_count: 0} = state, v) do
      {state, :cerlc.calc_crc(v, @crc_alg)}
    end

    defp crc(%{crc_injection_count: n} = state, v) do
      {%{state | crc_injection_count: n - 1}, :cerlc.calc_crc(v, @crc_alg) |> Bitwise.bxor(1)}
    end
  end
end
