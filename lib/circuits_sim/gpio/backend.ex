defmodule CircuitsSim.GPIO.Backend do
  @moduledoc """
  Circuits.GPIO backend for virtual GPIO devices
  """
  @behaviour Circuits.GPIO.Backend

  alias Circuits.GPIO.Backend
  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.GPIO.GPIOServer
  alias CircuitsSim.GPIO.Handle

  @doc """
  Open an GPIO handle
  """
  @impl Backend
  def open(gpio_spec, direction, options) do
    with {:ok, identifiers} <- identifiers(gpio_spec, options),
         handle = %Handle{gpio_spec: identifiers.gpio_spec},
         :ok <- GPIOServer.set_direction(identifiers.gpio_spec, direction),
         :ok <- set_pull_mode(identifiers.gpio_spec, options[:pull_mode]),
         :ok <- set_initial_value(identifiers.gpio_spec, options[:initial_value]) do
      {:ok, handle}
    end
  end

  defp set_pull_mode(_gpio_spec, :not_set), do: :ok
  defp set_pull_mode(gpio_spec, pull_mode), do: GPIOServer.set_pull_mode(gpio_spec, pull_mode)

  defp set_initial_value(_gpio_spec, :not_set), do: :ok
  defp set_initial_value(gpio_spec, value), do: GPIOServer.write(gpio_spec, value)

  @doc """
  Return information about this backend
  """
  @impl Backend
  def info() do
    %{backend: __MODULE__}
  end
end
