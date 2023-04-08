import Config

# Simulate a few devices
config :circuits_sim,
  config: [
    {CircuitsSim.Device.MCP23008, bus_name: "i2c-0", address: 0x20},
    {CircuitsSim.Device.AT24C02, bus_name: "i2c-0", address: 0x50},
    {CircuitsSim.Device.ADS7138, bus_name: "i2c-1", address: 0x10},
    {CircuitsSim.Device.MCP23008, bus_name: "i2c-1", address: 0x20},
    {CircuitsSim.Device.MCP23008, bus_name: "i2c-1", address: 0x21},
    {CircuitsSim.Device.TM1620, bus_name: "spidev0.0", render: :binary_clock}
  ]

# Use the simulated I2C and SPI buses
config :circuits_i2c, default_backend: CircuitsSim.I2C.Backend
config :circuits_spi, default_backend: CircuitsSim.SPI.Backend
