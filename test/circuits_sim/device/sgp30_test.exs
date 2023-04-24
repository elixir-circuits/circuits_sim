defmodule CircuitsSim.Device.SGP30Test do
  use ExUnit.Case

  test "simple usage", %{test: test_name} do
    alias CircuitsSim.I2C.I2CServer
    alias CircuitsSim.Device.SGP30

    init_arg = [bus_name: "i2c-1", address: 0x58, device: SGP30.new(), name: test_name]
    start_supervised({I2CServer, init_arg})

    SGP30.set_tvoc_ppb("i2c-1", 0x58, 0)
    SGP30.set_co2_eq_ppm("i2c-1", 0x58, 400)
    SGP30.set_h2_raw("i2c-1", 0x58, 13600)
    SGP30.set_ethanol_raw("i2c-1", 0x58, 18848)

    assert I2CServer.render("i2c-1", 0x58) ==
             "tvoc_ppb: 0, co2_eq_ppm: 400, h2_raw: 13600, ethanol_raw: 18848"
  end

  test "supports SGP30 package", %{test: test_name} do
    alias CircuitsSim.Device.SGP30, as: SGP30Sim

    init_arg = [bus_name: "i2c-1", address: 0x58, name: test_name]
    {:ok, sgp_pid} = start_supervised({SGP30, init_arg})

    SGP30Sim.set_tvoc_ppb("i2c-1", 0x58, 0)
    SGP30Sim.set_co2_eq_ppm("i2c-1", 0x58, 400)
    SGP30Sim.set_h2_raw("i2c-1", 0x58, 13600)
    SGP30Sim.set_ethanol_raw("i2c-1", 0x58, 18848)

    # SGP30 requires me gwasurements at specific intervals, so it may take 900ms on startup
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
