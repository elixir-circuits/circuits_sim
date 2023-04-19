defmodule CircuitsSim.Device.SGP30Test do
  use ExUnit.Case

  test "measurement" do
    {:ok, sgp_pid} = SGP30.start_link(bus_name: "i2c-1")

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
