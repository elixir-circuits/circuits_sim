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

  @spec add_device(module() | {module(), keyword()}) :: DynamicSupervisor.on_start_child()
  def add_device(device_options) do
    {:ok, _} =
      DynamicSupervisor.start_child(CircuitSim.DeviceSupervisor, device_spec(device_options))
  end

  defp device_spec(device) when is_atom(device) do
    {device, []}
  end

  defp device_spec({device, options} = device_options)
       when is_atom(device) and is_list(options) do
    device_options
  end

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
        device_struct = I2CServer.render(bus_name, address)
        hex_addr = CircuitsSim.Tools.hex_byte(address)

        # Empty list means no device at this address
        if device_struct != [] do
          ["Device 0x#{hex_addr}: \n", to_string(device_struct), "\n"]
        else
          []
        end
      end

    ["=== ", bus_name, " ===\n", result]
  end

  defp spi_info() do
    DeviceRegistry.bus_names(:spi)
    |> Enum.map(&spi_bus_info/1)
  end

  defp spi_bus_info(bus_name) do
    device_struct = SPIServer.render(bus_name)
    ["=== ", bus_name, " ===\n", to_string(device_struct)]
  end

  defp gpio_info() do
    DeviceRegistry.bus_names(:gpio)
    |> Enum.map(&gpio_spec_info/1)
  end

  defp gpio_spec_info(gpio_spec) do
    device_struct = GPIOServer.render(gpio_spec)
    ["=== GPIO ", inspect(gpio_spec), " ===\n", to_string(device_struct)]
  end
end
