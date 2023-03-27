defmodule CircuitsSim.SPI.Backend do
  @moduledoc """
  Circuits.SPI backend for virtual SPI devices
  """
  @behaviour Circuits.SPI.Backend

  alias Circuits.SPI.Backend
  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.SPI.Bus

  @doc """
  Return the I2C bus names on this system

  No supported options
  """
  @impl Backend
  def bus_names(_options) do
    DeviceRegistry.bus_names()
  end

  @doc """
  Open an I2C bus
  """
  @impl Backend
  def open(bus_name, options) do
    if bus_name in bus_names(options) do
      {:ok, %Bus{bus_name: bus_name}}
    else
      {:error, "Unknown controller #{bus_name}"}
    end
  end

  @doc """
  Return information about this backend
  """
  @impl Backend
  def info() do
    %{backend: __MODULE__}
  end
end
