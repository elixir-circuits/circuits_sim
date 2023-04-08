defmodule CircuitsSim.GPIO.Backend do
  @moduledoc """
  Circuits.GPIO backend for virtual GPIO devices
  """
  @behaviour Circuits.GPIO.Backend

  alias Circuits.GPIO
  alias Circuits.GPIO.Backend
  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.GPIO.GPIOServer
  alias CircuitsSim.GPIO.Handle

  @doc """
  Open an GPIO handle
  """
  @impl Backend
  def open(pin_spec, direction, options) do
    if pin_spec in pin_specs(options) do
      handle = %Handle{pin_spec: pin_spec}

      with :ok <- GPIOServer.set_direction(pin_spec, direction),
           :ok <- set_pull_mode(pin_spec, options[:pull_mode]),
           :ok <- set_initial_value(pin_spec, options[:initial_value]) do
        {:ok, handle}
      end
    else
      {:error, "Unknown GPIO pin_spec #{inspect(pin_spec)}"}
    end
  end

  defp set_pull_mode(_pin_spec, :not_set), do: :ok
  defp set_pull_mode(pin_spec, pull_mode), do: GPIOServer.set_pull_mode(pin_spec, pull_mode)

  defp set_initial_value(_pin_spec, :not_set), do: :ok
  defp set_initial_value(pin_spec, value), do: GPIOServer.write(pin_spec, value)

  @doc """
  Return information about this backend
  """
  @impl Backend
  def info() do
    %{backend: __MODULE__}
  end

  @spec pin_specs(keyword()) :: [GPIO.pin_spec()]
  def pin_specs(_options) do
    DeviceRegistry.bus_names(:gpio)
  end
end
