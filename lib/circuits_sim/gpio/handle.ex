defmodule CircuitsSim.GPIO.Handle do
  @moduledoc false

  alias Circuits.GPIO.Handle
  alias CircuitsSim.GPIO.GPIOServer

  defstruct [:pin_spec]

  @type t() :: %__MODULE__{
          pin_spec: Circuits.GPIO.pin_spec()
        }

  @spec render(t()) :: String.t()
  def render(%__MODULE__{} = handle) do
    GPIOServer.render(handle.pin_spec)
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
  end

  defimpl Handle do
    alias CircuitsSim.GPIO.GPIOServer

    @impl Handle
    def read(%CircuitsSim.GPIO.Handle{} = handle) do
      GPIOServer.read(handle.pin_spec)
    end

    @impl Handle
    def write(%CircuitsSim.GPIO.Handle{} = handle, value) do
      GPIOServer.write(handle.pin_spec, value)
    end

    @impl Handle
    def set_direction(%CircuitsSim.GPIO.Handle{} = handle, direction) do
      GPIOServer.set_direction(handle.pin_spec, direction)
    end

    @impl Handle
    def set_interrupts(%CircuitsSim.GPIO.Handle{} = handle, trigger, options) do
      GPIOServer.set_interrupts(handle.pin_spec, trigger, options)
    end

    @impl Handle
    def set_pull_mode(%CircuitsSim.GPIO.Handle{} = handle, pull_mode) do
      GPIOServer.set_pull_mode(handle.pin_spec, pull_mode)
    end

    @impl Handle
    def close(%CircuitsSim.GPIO.Handle{}), do: :ok

    @impl Handle
    def info(%CircuitsSim.GPIO.Handle{} = handle) do
      GPIOServer.info(handle.pin_spec)
    end
  end
end
