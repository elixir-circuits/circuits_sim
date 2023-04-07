# CircuitsSim

Interact with simulated I2C devices

NOTE: This project is an active development. Expect big API changes as we use it.

## Demo

CircuitsSim takes a configuration for how to set up the simulated I2C buses and
devices. Here's an example configuration:

```elixir
config :circuits_sim,
  config: %{
    "i2c-0" => %{
      0x20 => CircuitsSim.Device.MCP23008,
      0x50 => CircuitsSim.Device.AT24C02
    },
    "i2c-1" => %{
      0x10 => CircuitsSim.Device.ADS7138,
      0x20 => CircuitsSim.Device.MCP23008,
      0x21 => CircuitsSim.Device.MCP23008
    },
    "spidev0.0" => %{0 => {CircuitsSim.Device.TM1620, render: :binary_clock}}
  }
```

This shows two simulated I2C buses, `"i2c-0"` and `"i2c-1"`, and one SPI bus.
The `"i2c-0"` bus has two devices, an MCP23008 GPIO expander and an AT24C02
EEPROM.

Here's how it looks when you run IEx:

```shell
$ iex -S mix

Interactive Elixir (1.14.3) - press Ctrl+C to exit (type h() ENTER for help)
iex> Circuits.I2C.detect_devices
Devices on I2C bus "i2c-1":
 * 16  (0x10)
 * 32  (0x20)
 * 33  (0x21)

Devices on I2C bus "i2c-0":
 * 32  (0x20)
 * 80  (0x50)

5 devices detected on 2 I2C buses
```

You can then read and write to the I2C devices similar to how you'd interact
with them for real. While they're obviously not real and have limitations, they
can be super helpful in mocking I2C devices or debugging I2C interactions
without hardware in the loop.

## Adding an I2C device

Many I2C devices follow a simple pattern of exposing all operations as register
reads and writes. If this is the case for your device, create a new module and
implement the `CircuitsSim.I2C.SimpleI2CDevice` protocol. See
`CircuitsSim.Device.MCP23008` for an example.

If your device has a fancier interface, you'll need to implement the
`CircuitsSim.I2C.I2CDevice` protocol which just passes the reads and writes
through and doesn't handle conveniences like auto-incrementing register
addresses on multi-byte reads and writes. See `CircuitsSim.Device.ADS7138` for
an example.

## Adding a SPI device

Simulated SPI devices implement the `CircuitsSim.SPI.SPIDevice` protocols. See
`CircuitsSim.Device.TM1620` for an example.
