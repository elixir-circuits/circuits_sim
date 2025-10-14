# SPDX-FileCopyrightText: 2025 Timmo Verlaan
#
# SPDX-License-Identifier: Apache-2.0
#

# Kino.Render protocol implementations for CircuitsSim devices
#
# Devices needing implementation:
# - ADS7138 - 8-channel 12-bit ADC with GPIOs
# - B5ZE - Abracon RTC (Real-Time Clock)
# - PI4IOE5V6416LEX - 16-bit I/O expander
# - MCP23008 - 8-bit I/O expander
# - AT24C02 - 2 Kb I2C EEPROM (256 bytes)
# - TM1620 - LED Driver (SPI device, not I2C)

if Code.ensure_loaded?(Kino) do
  defimpl Kino.Render, for: CircuitsSim.Device.GPIOButton do
    def to_livebook(state) do
      # Create a visual representation of the button
      button_color = if state.state == :pressed, do: "#4CAF50", else: "#e0e0e0"
      button_text = if state.state == :pressed, do: "PRESSED", else: "RELEASED"

      connection_info =
        case state.connection do
          :external_pullup -> "External Pull-up (0=pressed, 1=released)"
          :external_pulldown -> "External Pull-down (1=pressed, 0=released)"
          :internal_pullup -> "Internal Pull-up (0=pressed, Hi-Z=released)"
          :internal_pulldown -> "Internal Pull-down (1=pressed, Hi-Z=released)"
        end

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">GPIO Button</h3>
        <div style="display: flex; align-items: center; gap: 20px; margin: 20px 0;">
          <div style="
            width: 100px;
            height: 100px;
            border-radius: 50%;
            background: #{button_color};
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            color: white;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          ">#{button_text}</div>
          <div>
            <div style="margin-bottom: 10px;"><strong>State:</strong> #{state.state}</div>
            <div style="font-size: 0.9em; color: #666;">#{connection_info}</div>
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: CircuitsSim.Device.GPIOLED do
    def to_livebook(state) do
      led_color = if state.value == 1, do: "#FFD700", else: "#333333"
      led_status = if state.value == 1, do: "ON", else: "OFF"

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">GPIO LED</h3>
        <div style="display: flex; align-items: center; gap: 20px; margin: 20px 0;">
          <div style="
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: #{led_color};
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            color: white;
            box-shadow: 0 0 #{if state.value == 1, do: "20px", else: "0"} #{if state.value == 1, do: led_color, else: "transparent"};
            transition: all 0.3s ease;
          ">💡</div>
          <div>
            <div><strong>Status:</strong> #{led_status}</div>
            <div style="font-size: 0.9em; color: #666;">Value: #{state.value}</div>
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: CircuitsSim.Device.SHT4X do
    def to_livebook(state) do
      humidity_rh = Float.round(state.humidity_rh, 1)
      temperature_c = Float.round(state.temperature_c, 1)
      temperature_f = Float.round(temperature_c * 9 / 5 + 32, 1)

      # Color coding for temperature (blue=cold, orange=warm, red=hot)
      temp_color =
        cond do
          temperature_c < 15 -> "#2196F3"
          temperature_c < 25 -> "#4CAF50"
          temperature_c < 30 -> "#FF9800"
          true -> "#F44336"
        end

      # Color coding for humidity (brown=dry, blue=humid)
      humidity_color =
        cond do
          humidity_rh < 30 -> "#795548"
          humidity_rh < 60 -> "#4CAF50"
          true -> "#2196F3"
        end

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">SHT4X Sensor</h3>
        <div style="display: flex; gap: 20px; margin: 20px 0;">
          <div style="
            flex: 1;
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{temp_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Temperature</div>
            <div style="font-size: 2em; font-weight: bold; color: #{temp_color};">#{temperature_c}°C</div>
            <div style="font-size: 0.9em; color: #999;">#{temperature_f}°F</div>
          </div>
          <div style="
            flex: 1;
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{humidity_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Humidity</div>
            <div style="font-size: 2em; font-weight: bold; color: #{humidity_color};">#{humidity_rh}%</div>
            <div style="font-size: 0.9em; color: #999;">RH</div>
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: CircuitsSim.Device.AHT20 do
    def to_livebook(state) do
      humidity_rh = Float.round(state.humidity_rh, 1)
      temperature_c = Float.round(state.temperature_c, 1)
      temperature_f = Float.round(temperature_c * 9 / 5 + 32, 1)

      # Color coding for temperature
      temp_color =
        cond do
          temperature_c < 15 -> "#2196F3"
          temperature_c < 25 -> "#4CAF50"
          temperature_c < 30 -> "#FF9800"
          true -> "#F44336"
        end

      # Color coding for humidity
      humidity_color =
        cond do
          humidity_rh < 30 -> "#795548"
          humidity_rh < 60 -> "#4CAF50"
          true -> "#2196F3"
        end

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">AHT20 Sensor</h3>
        <div style="display: flex; gap: 20px; margin: 20px 0;">
          <div style="
            flex: 1;
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{temp_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Temperature</div>
            <div style="font-size: 2em; font-weight: bold; color: #{temp_color};">#{temperature_c}°C</div>
            <div style="font-size: 0.9em; color: #999;">#{temperature_f}°F</div>
          </div>
          <div style="
            flex: 1;
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{humidity_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Humidity</div>
            <div style="font-size: 2em; font-weight: bold; color: #{humidity_color};">#{humidity_rh}%</div>
            <div style="font-size: 0.9em; color: #999;">RH</div>
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: CircuitsSim.Device.SGP30 do
    def to_livebook(state) do
      # Color coding for CO2 levels (green=good, yellow=elevated, red=poor)
      co2_color =
        cond do
          state.co2_eq_ppm < 800 -> "#4CAF50"
          state.co2_eq_ppm < 1200 -> "#FF9800"
          true -> "#F44336"
        end

      # Color coding for TVOC levels
      tvoc_color =
        cond do
          state.tvoc_ppb < 220 -> "#4CAF50"
          state.tvoc_ppb < 660 -> "#FF9800"
          true -> "#F44336"
        end

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">SGP30 Gas Sensor</h3>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0;">
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{co2_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">CO₂ Equivalent</div>
            <div style="font-size: 2em; font-weight: bold; color: #{co2_color};">#{state.co2_eq_ppm}</div>
            <div style="font-size: 0.9em; color: #999;">ppm</div>
          </div>
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{tvoc_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">TVOC</div>
            <div style="font-size: 2em; font-weight: bold; color: #{tvoc_color};">#{state.tvoc_ppb}</div>
            <div style="font-size: 0.9em; color: #999;">ppb</div>
          </div>
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #9E9E9E;
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">H₂ Raw Signal</div>
            <div style="font-size: 2em; font-weight: bold; color: #9E9E9E;">#{state.h2_raw}</div>
            <div style="font-size: 0.9em; color: #999;">raw</div>
          </div>
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #9E9E9E;
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Ethanol Raw Signal</div>
            <div style="font-size: 2em; font-weight: bold; color: #9E9E9E;">#{state.ethanol_raw}</div>
            <div style="font-size: 0.9em; color: #999;">raw</div>
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: CircuitsSim.Device.VCNL4040 do
    def to_livebook(state) do
      # Convert raw values to percentages for visual representation
      proximity_pct = min(100, trunc(state.proximity_raw / 655.35))
      ambient_pct = min(100, trunc(state.ambient_light_raw / 655.35))
      white_pct = min(100, trunc(state.white_light_raw / 655.35))

      # Color coding based on intensity
      proximity_color =
        cond do
          proximity_pct > 70 -> "#F44336"
          proximity_pct > 30 -> "#FF9800"
          true -> "#4CAF50"
        end

      light_color =
        cond do
          ambient_pct > 70 -> "#FFD700"
          ambient_pct > 30 -> "#FFA726"
          true -> "#616161"
        end

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">VCNL4040 Light & Proximity Sensor</h3>
        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; margin: 20px 0;">
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{proximity_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Proximity</div>
            <div style="font-size: 2em; font-weight: bold; color: #{proximity_color};">#{state.proximity_raw}</div>
            <div style="font-size: 0.9em; color: #999;">raw (#{proximity_pct}%)</div>
          </div>
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{light_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Ambient Light</div>
            <div style="font-size: 2em; font-weight: bold; color: #{light_color};">#{state.ambient_light_raw}</div>
            <div style="font-size: 0.9em; color: #999;">raw (#{ambient_pct}%)</div>
          </div>
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{light_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">White Light</div>
            <div style="font-size: 2em; font-weight: bold; color: #{light_color};">#{state.white_light_raw}</div>
            <div style="font-size: 0.9em; color: #999;">raw (#{white_pct}%)</div>
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: CircuitsSim.Device.VEML7700 do
    def to_livebook(state) do
      # Convert raw values to percentages for visual representation
      als_pct = min(100, trunc(state.als_output / 655.35))
      white_pct = min(100, trunc(state.white_output / 655.35))

      # Color coding based on light intensity
      als_color =
        cond do
          als_pct > 70 -> "#FFD700"
          als_pct > 30 -> "#FFA726"
          true -> "#616161"
        end

      white_color =
        cond do
          white_pct > 70 -> "#FFFFFF"
          white_pct > 30 -> "#E0E0E0"
          true -> "#9E9E9E"
        end

      # Adjust text color for light backgrounds
      white_text_color = if white_pct > 50, do: "#000000", else: white_color

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">VEML7700 Ambient Light Sensor</h3>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0;">
          <div style="
            padding: 20px;
            background: white;
            border-radius: 8px;
            border-left: 4px solid #{als_color};
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">Ambient Light</div>
            <div style="font-size: 2em; font-weight: bold; color: #{als_color};">#{state.als_output}</div>
            <div style="font-size: 0.9em; color: #999;">raw (#{als_pct}%)</div>
          </div>
          <div style="
            padding: 20px;
            background: #{if white_pct > 50, do: white_color, else: "white"};
            border-radius: 8px;
            border-left: 4px solid #{white_color};
            #{if white_pct > 50, do: "border: 1px solid #ddd;", else: ""}
          ">
            <div style="font-size: 0.9em; color: #666; margin-bottom: 5px;">White Light</div>
            <div style="font-size: 2em; font-weight: bold; color: #{white_text_color};">#{state.white_output}</div>
            <div style="font-size: 0.9em; color: #999;">raw (#{white_pct}%)</div>
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: CircuitsSim.Device.BMP3XX do
    def to_livebook(state) do
      sensor_name =
        case state.sensor_type do
          :bmp380 -> "BMP380"
          :bmp390 -> "BMP390"
          :bmp180 -> "BMP180"
          :bmp280 -> "BMP280"
          :bme280 -> "BME280"
          :bme680 -> "BME680"
          _ -> "Unknown"
        end

      sensor_description =
        case state.sensor_type do
          type when type in [:bmp380, :bmp390, :bmp180, :bmp280] ->
            "Pressure & Temperature Sensor"

          type when type in [:bme280, :bme680] ->
            "Pressure, Temperature & Humidity Sensor"

          _ ->
            "Sensor"
        end

      html = """
      <div style="padding: 20px; background: #f5f5f5; border-radius: 8px; font-family: system-ui;">
        <h3 style="margin-top: 0;">#{sensor_name} #{sensor_description}</h3>
        <div style="padding: 20px; background: white; border-radius: 8px; border-left: 4px solid #2196F3;">
          <div style="font-size: 1.2em; color: #666;">
            This device stores raw register data. Use the BMP3XX library to read temperature and pressure values.
          </div>
          <div style="margin-top: 15px; font-size: 0.9em; color: #999;">
            Sensor Type: #{state.sensor_type}
          </div>
        </div>
      </div>
      """

      Kino.HTML.new(html) |> Kino.Render.to_livebook()
    end
  end
end
