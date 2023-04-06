import Config

# Simulate a few devices
config :circuits_sim,
  config: %{
    "i2c-0" => %{0x20 => CircuitsSim.Device.MCP23008, 0x50 => CircuitsSim.Device.AT24C02},
    "i2c-1" => %{
      0x10 => CircuitsSim.Device.ADS7138,
      0x20 => CircuitsSim.Device.MCP23008,
      0x21 => CircuitsSim.Device.MCP23008
    },
    "spidev0.0" => %{0 => {CircuitsSim.Device.TM1620, render: :binary_clock}}
  }

# Use the simulated I2C and SPI buses
config :circuits_i2c, default_backend: CircuitsSim.I2C.Backend
config :circuits_spi, default_backend: CircuitsSim.SPI.Backend
