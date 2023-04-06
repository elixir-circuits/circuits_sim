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
    DeviceRegistry.bus_names(:spi)
  end

  @doc """
  Open an I2C bus
  """
  @impl Backend
  def open(bus_name, options) do
    if bus_name in bus_names(options) do
      mode = Keyword.get(options, :mode, 0)
      bits_per_word = Keyword.get(options, :bits_per_word, 8)
      speed_hz = Keyword.get(options, :speed_hz, 1_000_000)
      delay_us = Keyword.get(options, :delay_us, 10)
      lsb_first = Keyword.get(options, :lsb_first, false)

      config = %{
        mode: mode,
        bits_per_word: bits_per_word,
        speed_hz: speed_hz,
        delay_us: delay_us,
        lsb_first: lsb_first,
        sw_lsb_first: lsb_first
      }

      {:ok, %Bus{bus_name: bus_name, config: config}}
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
