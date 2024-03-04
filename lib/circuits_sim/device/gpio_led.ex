defmodule CircuitsSim.Device.GPIOLED do
  @moduledoc """
  This is simple GPIO-connected LED
  """

  alias CircuitsSim.GPIO.GPIODevice
  alias CircuitsSim.GPIO.GPIOServer

  defstruct value: 0
  @type t() :: %__MODULE__{value: 0 | 1}

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = __MODULE__.new()
    GPIOServer.child_spec_helper(device, args)
  end

  @spec new() :: %__MODULE__{value: 0}
  def new() do
    %__MODULE__{}
  end

  defimpl GPIODevice do
    @impl GPIODevice
    def write(state, value) do
      %{state | value: value}
    end

    @impl GPIODevice
    def read(_state) do
      :hi_z
    end

    @impl GPIODevice
    def render(state) do
      ["LED ", led_string(state.value)]
    end

    defp led_string(0), do: "off"
    defp led_string(1), do: "on"

    @impl GPIODevice
    def handle_message(state, _message) do
      {:ok, state}
    end

    @impl GPIODevice
    def handle_info(state, :release) do
      state
    end
  end
end
