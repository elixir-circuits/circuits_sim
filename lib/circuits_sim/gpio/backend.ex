defmodule CircuitsSim.GPIO.Backend do
  @moduledoc """
  Circuits.GPIO backend for virtual GPIO devices
  """
  @behaviour Circuits.GPIO.Backend

  alias Circuits.GPIO.Backend
  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.GPIO.GPIOServer
  alias CircuitsSim.GPIO.Handle

  @impl Backend
  def enumerate(_options) do
    DeviceRegistry.bus_names(:gpio)
  end

  @impl Backend
  def identifiers(gpio_spec, _options) do
    # Simplest possible implementation for now.
    {:ok, %{controller: "sim", label: "unknown", location: gpio_spec}}
  end

  @impl Backend
  def status(_gpio_spec, _options) do
    {:error, :unimplemented}
  end

  @doc """
  Open an GPIO handle
  """
  @impl Backend
  def open(gpio_spec, direction, options) do
    with {:ok, identifiers} <- identifiers(gpio_spec, options),
         handle = %Handle{gpio_spec: identifiers.location},
         :ok <- GPIOServer.set_direction(identifiers.location, direction),
         :ok <- set_pull_mode(identifiers.location, options[:pull_mode]),
         :ok <- set_initial_value(direction, identifiers.location, options[:initial_value]) do
      {:ok, handle}
    end
  end

  defp set_pull_mode(_gpio_spec, :not_set), do: :ok
  defp set_pull_mode(gpio_spec, pull_mode), do: GPIOServer.set_pull_mode(gpio_spec, pull_mode)

  defp set_initial_value(:output, gpio_spec, value), do: GPIOServer.write(gpio_spec, value)
  defp set_initial_value(:input, _gpio_spec, _value), do: :ok

  @doc """
  Return information about this backend
  """
  @impl Backend
  def backend_info() do
    %{backend: __MODULE__}
  end
end
