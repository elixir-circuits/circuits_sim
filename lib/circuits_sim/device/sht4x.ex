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

  defstruct current: 0
  @type t() :: %__MODULE__{current: non_neg_integer()}

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    I2CServer.child_spec_helper(device, args)
  end

  @spec new() :: %__MODULE__{current: 0}
  def new() do
    %__MODULE__{}
  end

  ## protocol implementation

  defimpl I2CDevice do
    @cmd_serial_number 0x89
    @cmd_measure_high_repeatability 0xFD
    @cmd_measure_medium_repeatability 0xF6
    @cmd_measure_low_repeatability 0xE0

    @impl I2CDevice
    def read(%{current: :serial_number} = state, 6) do
      {<<15, 186, 124, 249, 143, 14>>, %{state | current: 0}}
    end

    def read(%{current: :measure_high_repeatability} = state, 6) do
      {<<105, 234, 13, 109, 6, 50>>, %{state | current: 0}}
    end

    def read(%{current: :measure_medium_repeatability} = state, 6) do
      {<<105, 234, 13, 108, 239, 143>>, %{state | current: 0}}
    end

    def read(%{current: :measure_low_repeatability} = state, 6) do
      {<<105, 219, 249, 108, 200, 158>>, %{state | current: 0}}
    end

    def read(state, 6) do
      {<<0, 0, 0, 0, 0, 0>>, %{state | current: 0}}
    end

    @impl I2CDevice
    def write(state, <<0x89>>) do
      %{state | current: :serial_number}
    end

    def write(state, <<0xFD>>) do
      %{state | current: :measure_high_repeatability}
    end

    def write(state, <<0xF6>>) do
      %{state | current: :measure_medium_repeatability}
    end

    def write(state, <<0xE0>>) do
      %{state | current: :measure_low_repeatability}
    end

    def write(state, _), do: state

    @impl I2CDevice
    def write_read(state, _, _), do: {<<>>, state}

    @impl I2CDevice
    def render(state) do
      # TODO: show something more useful
      ["current: ", Tools.hex_byte(state.current), "\n"]
    end

    @impl I2CDevice
    def handle_message(state, _message) do
      {:not_implemented, state}
    end
  end
end
