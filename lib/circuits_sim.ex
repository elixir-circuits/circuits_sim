# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim do
  @moduledoc """
  Circuits Simulator
  """

  alias CircuitsSim.DeviceRegistry
  alias CircuitsSim.GPIO.GPIOServer
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.SPI.SPIServer

  @doc """
  Show information about all simulated devices
  """
  @spec info() :: :ok
  def info() do
    [i2c_info(), ?\n, spi_info(), ?\n, gpio_info()]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  defp i2c_info() do
    DeviceRegistry.bus_names(:i2c)
    |> Enum.map(&i2c_bus_info/1)
  end

  defp i2c_bus_info(bus_name) do
    result =
      for address <- 0..127 do
        info = I2CServer.render(bus_name, address)
        hex_addr = CircuitsSim.Tools.hex_byte(address)
        if info != [], do: ["Device 0x#{hex_addr}: \n", info, "\n"], else: []
      end

    ["=== ", bus_name, " ===\n", result]
  end

  defp spi_info() do
    DeviceRegistry.bus_names(:spi)
    |> Enum.map(&spi_bus_info/1)
  end

  defp spi_bus_info(bus_name) do
    result = SPIServer.render(bus_name)
    ["=== ", bus_name, " ===\n", result]
  end

  defp gpio_info() do
    DeviceRegistry.bus_names(:gpio)
    |> Enum.map(&gpio_spec_info/1)
  end

  defp gpio_spec_info(gpio_spec) do
    result = GPIOServer.render(gpio_spec)
    ["=== GPIO ", inspect(gpio_spec), " ===\n", result]
  end
end
