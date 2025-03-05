# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
import Config

# Simulate a few devices
config :circuits_sim,
  config: [
    {CircuitsSim.Device.MCP23008, bus_name: "i2c-0", address: 0x20},
    {CircuitsSim.Device.AT24C02, bus_name: "i2c-0", address: 0x50},
    {CircuitsSim.Device.ADS7138, bus_name: "i2c-1", address: 0x10},
    {CircuitsSim.Device.MCP23008, bus_name: "i2c-1", address: 0x20},
    {CircuitsSim.Device.MCP23008, bus_name: "i2c-1", address: 0x21},
    {CircuitsSim.Device.AHT20, bus_name: "i2c-1", address: 0x38},
    {CircuitsSim.Device.SHT4X, bus_name: "i2c-1", address: 0x44},
    {CircuitsSim.Device.VEML7700, bus_name: "i2c-1", address: 0x48},
    {CircuitsSim.Device.SGP30, bus_name: "i2c-1", address: 0x58},
    {CircuitsSim.Device.BMP3XX, bus_name: "i2c-1", address: 0x77},
    {CircuitsSim.Device.TM1620, bus_name: "spidev0.0", render: :binary_clock},
    {CircuitsSim.Device.GPIOLED, gpio_spec: 10},
    {CircuitsSim.Device.GPIOButton, gpio_spec: 11}
  ]

# Default to simulated versions of I2C, SPI, and GPIO
config :circuits_i2c, default_backend: CircuitsSim.I2C.Backend
config :circuits_spi, default_backend: CircuitsSim.SPI.Backend
config :circuits_gpio, default_backend: CircuitsSim.GPIO.Backend
