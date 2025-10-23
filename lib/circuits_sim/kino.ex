# SPDX-FileCopyrightText: 2025 Timmo Verlaan
#
# SPDX-License-Identifier: Apache-2.0
#

if Code.ensure_loaded?(Kino) do
  defmodule CircuitsSim.Kino do
    @moduledoc """
    Interactive Kinos for CircuitsSim devices.

    These widgets allow you to interact with simulated devices directly from LiveBook.
    """
    alias CircuitsSim.GPIO.GPIOServer
    alias CircuitsSim.I2C.I2CServer
    alias CircuitsSim.Device.{AHT20, GPIOButton, SGP30, SHT4X, VCNL4040, VEML7700}

    @doc """
    Create an interactive button widget for a GPIO button device.

    ## Example

        CircuitsSim.Kino.button({:circuits_sim, "button1", 17})
    """
    @spec button(Circuits.GPIO.gpio_spec()) :: Kino.Control.t()
    def button(gpio_spec) do
      # Single button that does press + release
      btn = Kino.Control.button("Push Button")

      # Handle button click - press, brief delay, then release
      Kino.listen(btn, fn _event ->
        GPIOButton.press(gpio_spec)
        Process.sleep(100)
        GPIOButton.release(gpio_spec)
      end)

      btn
    end

    @doc """
    Create an auto-updating LED display widget for a GPIO LED device.

    ## Example

        CircuitsSim.Kino.led({:circuits_sim, "led1", 27})
    """
    @spec led(Circuits.GPIO.gpio_spec(), non_neg_integer()) :: Kino.Frame.t()
    def led(gpio_spec, interval \\ 10) do
      frame = Kino.Frame.new()

      # Initial display
      state = GPIOServer.snapshot(gpio_spec)
      Kino.Frame.render(frame, state)

      # Start auto-update loop that only renders on state change

      Stream.interval(interval)
      |> Stream.scan({nil, nil}, fn _, {_, prev} ->
        current_state = GPIOServer.snapshot(gpio_spec)
        {prev, current_state}
      end)
      |> Kino.listen(fn
        {same, same} ->
          :ok

        {_, now} ->
          Kino.Frame.render(frame, now)

          :ok
      end)

      frame
    end

    @doc """
    Create an interactive temperature/humidity sensor widget.

    ## Example

        CircuitsSim.Kino.sht4x("i2c-1", 0x44)
    """
    @spec sht4x(String.t(), 0..127) :: Kino.Layout.t()
    def sht4x(bus_name, address) do
      frame = Kino.Frame.new()

      # Create sliders for temperature and humidity
      temp_input =
        Kino.Input.range("Temperature (°C)", min: -40, max: 125, default: 22, step: 0.5)

      humidity_input = Kino.Input.range("Humidity (%RH)", min: 0, max: 100, default: 50, step: 1)

      # Update display
      update_display = fn ->
        state = I2CServer.snapshot(bus_name, address)

        if state != [] do
          Kino.Frame.render(frame, state)
        end
      end

      # Initial display
      update_display.()

      # Update on slider changes
      Kino.listen(temp_input, fn %{value: temp} ->
        SHT4X.set_temperature_c(bus_name, address, temp)
        update_display.()
      end)

      Kino.listen(humidity_input, fn %{value: humidity} ->
        SHT4X.set_humidity_rh(bus_name, address, humidity)
        update_display.()
      end)

      Kino.Layout.grid([temp_input, humidity_input, frame], columns: 1)
    end

    @doc """
    Create an interactive temperature/humidity sensor widget.

    ## Example

        CircuitsSim.Kino.aht20("i2c-1", 0x44)
    """
    @spec aht20(String.t(), 0..127) :: Kino.Layout.t()
    def aht20(bus_name, address) do
      frame = Kino.Frame.new()

      # Create sliders for temperature and humidity
      temp_input =
        Kino.Input.range("Temperature (°C)", min: -40, max: 125, default: 22, step: 0.5)

      humidity_input = Kino.Input.range("Humidity (%RH)", min: 0, max: 100, default: 50, step: 1)

      # Update display
      update_display = fn ->
        state = I2CServer.snapshot(bus_name, address)

        if state != [] do
          Kino.Frame.render(frame, state)
        end
      end

      # Initial display
      update_display.()

      # Update on slider changes
      Kino.listen(temp_input, fn %{value: temp} ->
        AHT20.set_temperature_c(bus_name, address, temp)
        update_display.()
      end)

      Kino.listen(humidity_input, fn %{value: humidity} ->
        AHT20.set_humidity_rh(bus_name, address, humidity)
        update_display.()
      end)

      Kino.Layout.grid([temp_input, humidity_input, frame], columns: 1)
    end

    @doc """
    Create an interactive gas sensor widget for SGP30.

    ## Example

        CircuitsSim.Kino.sgp30("i2c-1", 0x58)
    """
    @spec sgp30(String.t(), 0..127) :: Kino.Layout.t()
    def sgp30(bus_name, address) do
      frame = Kino.Frame.new()

      # Create sliders for gas sensor values
      co2_input =
        Kino.Input.range("CO₂ Equivalent (ppm)", min: 400, max: 2000, default: 400, step: 50)

      tvoc_input =
        Kino.Input.range("TVOC (ppb)", min: 0, max: 1000, default: 0, step: 10)

      h2_input =
        Kino.Input.range("H₂ Raw Signal", min: 0, max: 65535, default: 13000, step: 100)

      ethanol_input =
        Kino.Input.range("Ethanol Raw Signal", min: 0, max: 65535, default: 13000, step: 100)

      # Update display
      update_display = fn ->
        state = I2CServer.snapshot(bus_name, address)

        if state != [] do
          Kino.Frame.render(frame, state)
        end
      end

      # Initial display
      update_display.()

      # Update on slider changes
      Kino.listen(co2_input, fn %{value: co2} ->
        SGP30.set_co2_eq_ppm(bus_name, address, trunc(co2))
        update_display.()
      end)

      Kino.listen(tvoc_input, fn %{value: tvoc} ->
        SGP30.set_tvoc_ppb(bus_name, address, trunc(tvoc))
        update_display.()
      end)

      Kino.listen(h2_input, fn %{value: h2} ->
        SGP30.set_h2_raw(bus_name, address, trunc(h2))
        update_display.()
      end)

      Kino.listen(ethanol_input, fn %{value: ethanol} ->
        SGP30.set_ethanol_raw(bus_name, address, trunc(ethanol))
        update_display.()
      end)

      Kino.Layout.grid([co2_input, tvoc_input, h2_input, ethanol_input, frame], columns: 1)
    end

    @doc """
    Create an interactive light and proximity sensor widget for VCNL4040.

    ## Example

        CircuitsSim.Kino.vcnl4040("i2c-1", 0x60)
    """
    @spec vcnl4040(String.t(), 0..127) :: Kino.Layout.t()
    def vcnl4040(bus_name, address) do
      frame = Kino.Frame.new()

      # Create sliders for sensor values
      proximity_input =
        Kino.Input.range("Proximity (raw)", min: 0, max: 65535, default: 0, step: 100)

      ambient_input =
        Kino.Input.range("Ambient Light (raw)", min: 0, max: 65535, default: 10000, step: 100)

      white_input =
        Kino.Input.range("White Light (raw)", min: 0, max: 65535, default: 10000, step: 100)

      # Update display
      update_display = fn ->
        state = I2CServer.snapshot(bus_name, address)

        if state != [] do
          Kino.Frame.render(frame, state)
        end
      end

      # Initial display
      update_display.()

      # Update on slider changes
      Kino.listen(proximity_input, fn %{value: proximity} ->
        VCNL4040.set_proximity(bus_name, address, trunc(proximity))
        update_display.()
      end)

      Kino.listen(ambient_input, fn %{value: ambient} ->
        VCNL4040.set_ambient_light(bus_name, address, trunc(ambient))
        update_display.()
      end)

      Kino.listen(white_input, fn %{value: white} ->
        VCNL4040.set_white_light(bus_name, address, trunc(white))
        update_display.()
      end)

      Kino.Layout.grid([proximity_input, ambient_input, white_input, frame], columns: 1)
    end

    @doc """
    Create an interactive ambient light sensor widget for VEML7700.

    ## Example

        CircuitsSim.Kino.veml7700("i2c-1", 0x48)
    """
    @spec veml7700(String.t(), 0..127) :: Kino.Layout.t()
    def veml7700(bus_name, address) do
      frame = Kino.Frame.new()

      # Create sliders for light sensor values
      als_input =
        Kino.Input.range("Ambient Light (raw)", min: 0, max: 65535, default: 10000, step: 100)

      white_input =
        Kino.Input.range("White Light (raw)", min: 0, max: 65535, default: 10000, step: 100)

      # Update display
      update_display = fn ->
        state = I2CServer.snapshot(bus_name, address)

        if state != [] do
          Kino.Frame.render(frame, state)
        end
      end

      # Initial display
      update_display.()

      # Update on slider changes
      Kino.listen(als_input, fn %{value: als} ->
        VEML7700.set_state(bus_name, address, als_output: trunc(als))
        update_display.()
      end)

      Kino.listen(white_input, fn %{value: white} ->
        VEML7700.set_state(bus_name, address, white_output: trunc(white))
        update_display.()
      end)

      Kino.Layout.grid([als_input, white_input, frame], columns: 1)
    end
  end
end
