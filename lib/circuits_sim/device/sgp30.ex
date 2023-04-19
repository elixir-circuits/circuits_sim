defmodule CircuitsSim.Device.SGP30 do
  @moduledoc """
  Sensirion SGP30 gas sensor

  Typically found at 0x58
  See the [datasheet](https://www.mouser.com/datasheet/2/682/Sensirion_Gas_Sensors_SGP30_Datasheet_EN-1148053.pdf)
  Many features aren't implemented.
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer

  defstruct current: nil
  @type t() :: %__MODULE__{current: atom()}

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    I2CServer.child_spec_helper(device, args)
  end

  @spec new() :: %__MODULE__{current: nil}
  def new() do
    %__MODULE__{}
  end

  ## protocol implementation

  defimpl I2CDevice do
    @impl I2CDevice
    def read(%{current: :iaq_measure} = state, 6) do
      {<<1, 144, 76, 0, 0, 129>>, %{state | current: nil}}
    end

    def read(%{current: :iaq_measure_raw} = state, 6) do
      {<<53, 32, 194, 73, 160, 55>>, %{state | current: nil}}
    end

    @impl I2CDevice
    def write(state, <<0x20, 0x03>>), do: %{state | current: :iaq_init}
    def write(state, <<0x20, 0x08>>), do: %{state | current: :iaq_measure}
    def write(state, <<0x20, 0x50>>), do: %{state | current: :iaq_measure_raw}

    @impl I2CDevice
    def write_read(state, <<0x36, 0x82>>, 9) do
      {<<0, 0, 129, 1, 142, 16, 41, 222, 133>>, %{state | current: nil}}
    end

    @impl I2CDevice
    def render(state) do
      "current: #{state.current}\n"
    end

    @impl I2CDevice
    def handle_message(state, _message) do
      {:not_implemented, state}
    end
  end
end
