defmodule CircuitsSim.Device.SGP30Test do
  use ExUnit.Case

  alias CircuitsSim.I2C.I2CServer

  test "simple usage" do
    device = CircuitsSim.Device.SGP30.new()
    init_arg = [bus_name: "i2c-1", address: 0x58, device: device]
    I2CServer.start_link(init_arg)

    I2CServer.send_message("i2c-1", 0x58, {:set_tvoc_ppb, 0})
    I2CServer.send_message("i2c-1", 0x58, {:set_co2_eq_ppm, 400})
    I2CServer.send_message("i2c-1", 0x58, {:set_h2_raw, 13600})
    I2CServer.send_message("i2c-1", 0x58, {:set_ethanol_raw, 18848})

    assert I2CServer.render("i2c-1", 0x58) ==
             "tvoc_ppb: 0, co2_eq_ppm: 400, h2_raw: 13600, ethanol_raw: 18848"
  end

  test "supports SGP30 package" do
    {:ok, sgp_pid} = SGP30.start_link(bus_name: "i2c-1")

    I2CServer.send_message("i2c-1", 0x58, {:set_tvoc_ppb, 0})
    I2CServer.send_message("i2c-1", 0x58, {:set_co2_eq_ppm, 400})
    I2CServer.send_message("i2c-1", 0x58, {:set_h2_raw, 13600})
    I2CServer.send_message("i2c-1", 0x58, {:set_ethanol_raw, 18848})

    # SGP30 requires measurements at specific intervals, so it may take 900ms on startup
    # before the first one. Since this is a mock device and we don't want
    # to wait in tests, just send the message to force the measurement now
    send(sgp_pid, :measure)

    assert %SGP30{
             address: 88,
             serial: 26_094_046,
             tvoc_ppb: 0,
             co2_eq_ppm: 400,
             i2c: %CircuitsSim.I2C.Bus{bus_name: "i2c-1"},
             h2_raw: 13600,
             ethanol_raw: 18848
           } = SGP30.state(sgp_pid)
  end
end
