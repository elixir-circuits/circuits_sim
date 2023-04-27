defmodule CircuitsSim.Device.SGP30Test do
  use ExUnit.Case
  alias CircuitsSim.I2C.I2CServer
  alias CircuitsSim.Device.SGP30, as: SGP30Sim

  @i2c_address 0x59

  test "setting SGP30 state", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({SGP30Sim, bus_name: i2c_bus, address: @i2c_address})

    SGP30Sim.set_tvoc_ppb(i2c_bus, @i2c_address, 10)
    SGP30Sim.set_co2_eq_ppm(i2c_bus, @i2c_address, 410)
    SGP30Sim.set_h2_raw(i2c_bus, @i2c_address, 13610)
    SGP30Sim.set_ethanol_raw(i2c_bus, @i2c_address, 18858)

    assert I2CServer.render(i2c_bus, @i2c_address) ==
             "tvoc_ppb: 10, co2_eq_ppm: 410, h2_raw: 13610, ethanol_raw: 18858"
  end

  test "supports SGP30 package", %{test: test_name} do
    i2c_bus = to_string(test_name)
    start_supervised!({SGP30Sim, bus_name: i2c_bus, address: @i2c_address, serial: 438})

    sgp_pid =
      start_supervised!({SGP30, bus_name: i2c_bus, address: @i2c_address, name: test_name})

    SGP30Sim.set_tvoc_ppb(i2c_bus, @i2c_address, 2)
    SGP30Sim.set_co2_eq_ppm(i2c_bus, @i2c_address, 500)
    SGP30Sim.set_h2_raw(i2c_bus, @i2c_address, 12345)
    SGP30Sim.set_ethanol_raw(i2c_bus, @i2c_address, 23456)

    # SGP30 requires me measurements at specific intervals, so it may take 900ms on startup
    # before the first one. Since this is a mock device and we don't want
    # to wait in tests, just send the message to force the measurement now
    send(sgp_pid, :measure)
    Process.sleep(10)

    sgp_state = SGP30.state(sgp_pid)
    assert sgp_state.tvoc_ppb == 2
    assert sgp_state.co2_eq_ppm == 500
    assert sgp_state.h2_raw == 12345
    assert sgp_state.ethanol_raw == 23456
    assert sgp_state.serial == 438
  end
end
