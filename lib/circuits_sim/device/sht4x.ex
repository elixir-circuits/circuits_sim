defmodule CircuitsSim.Device.SHT4X do
  @moduledoc """
  Sensirion SHT4x sensors

  Typically found at 0x44
  See the [datasheet](https://cdn-learn.adafruit.com/assets/assets/000/099/223/original/Sensirion_Humidity_Sensors_SHT4x_Datasheet.pdf) for details.
  Many features aren't implemented.
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Tools

  defstruct current: nil
  @type t() :: %__MODULE__{current: atom()}

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    I2CServer.child_spec_helper(device, args)
  end

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  ## protocol implementation

  defimpl I2CDevice do
    @impl I2CDevice
    def read(%{current: :serial_number} = state, 6) do
      {<<15, 186, 124, 249, 143, 14>>, %{state | current: nil}}
    end

    def read(%{current: :measure_high_repeatability} = state, 6) do
      {random_raw_sample(), %{state | current: nil}}
    end

    def read(%{current: :measure_medium_repeatability} = state, 6) do
      {random_raw_sample(), %{state | current: nil}}
    end

    def read(%{current: :measure_low_repeatability} = state, 6) do
      {random_raw_sample(), %{state | current: nil}}
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
      # TODO: show something more useful
      ["current: ", Tools.hex_byte(state.current), "\n"]
    end

    @impl I2CDevice
    def handle_message(state, _message), do: {:not_implemented, state}

    defp random_raw_sample() do
      measurement_to_raw(random_humidity_rh(), random_temperature_c())
    end

    defp random_humidity_rh(), do: 47 + :rand.uniform()
    defp random_temperature_c(), do: 27 + :rand.uniform()

    defp measurement_to_raw(humidity_rh, temperature_c) do
      raw_rh = trunc((humidity_rh + 6) * (0xFFFF - 1) / 125)
      raw_t = trunc((temperature_c + 45) * (0xFFFF - 1) / 175)
      crc1 = SHT4X.Calc.checksum(<<raw_t::16>>)
      crc2 = SHT4X.Calc.checksum(<<raw_rh::16>>)

      <<raw_t::16, crc1, raw_rh::16, crc2>>
    end
  end
end
