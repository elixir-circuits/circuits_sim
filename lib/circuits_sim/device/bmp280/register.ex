defmodule CircuitsSim.Device.BMP280.Register do
  @moduledoc false

  alias CircuitsSim.Device.BMP280

  @spec default_registers(BMP280.sensor_type()) :: %{byte() => byte()}
  def default_registers(sensor_type) do
    for(r <- 0x00..0xFF, into: %{}, do: {r, 0})
    |> Map.merge(sensor_type_register(sensor_type))
    |> Map.merge(calibration_registers(sensor_type))
  end

  defp sensor_type_register(:bmp180), do: %{0xD0 => 0x55}
  defp sensor_type_register(:bmp280), do: %{0xD0 => 0x58}
  defp sensor_type_register(:bme280), do: %{0xD0 => 0x60}
  defp sensor_type_register(:bme680), do: %{0xD0 => 0x61}

  defp calibration_registers(:bmp180) do
    # calib00: 22 bytes from 0xAA
    <<25, 38, 251, 185, 200, 200, 133, 213, 100, 76, 63, 129, 25, 115, 0, 40, 128, 0, 209, 246, 9,
      104>>
    |> binary_to_address_byte_map({0xAA, 22})
  end

  defp calibration_registers(:bmp280) do
    # calib00: 24 bytes from 0x88
    <<29, 110, 173, 102, 50, 0, 27, 143, 56, 214, 208, 11, 84, 43, 15, 255, 249, 255, 12, 48, 32,
      209, 136, 19>>
    |> binary_to_address_byte_map({0x88, 24})
  end

  defp calibration_registers(:bme280) do
    # calib00: 26 bytes from 0x88
    calib00 =
      <<29, 110, 173, 102, 50, 0, 27, 143, 56, 214, 208, 11, 84, 43, 15, 255, 249, 255, 12, 48,
        32, 209, 136, 19, 0, 75>>
      |> binary_to_address_byte_map({0x88, 26})

    # calib26: 7 bytes from 0xE1
    calib26 =
      <<82, 1, 0, 23, 44, 3, 30>>
      |> binary_to_address_byte_map({0xE1, 7})

    Map.merge(calib00, calib26)
  end

  defp calibration_registers(:bme680) do
    # coeff1: 23 bytes from 0x8A
    coeff1 =
      <<178, 102, 3, 16, 67, 138, 91, 215, 88, 0, 228, 18, 138, 255, 26, 30, 0, 0, 3, 253, 217,
        242, 30>>
      |> binary_to_address_byte_map({0x8A, 23})

    # coeff2: 14 bytes from 0xE1
    coeff2 =
      <<63, 221, 44, 0, 45, 20, 120, 156, 83, 102, 175, 232, 226, 18>>
      |> binary_to_address_byte_map({0xE1, 14})

    # coeff3: 5 bytes from 0x00
    coeff3 =
      <<50, 170, 22, 74, 19>>
      |> binary_to_address_byte_map({0x00, 5})

    coeff1 |> Map.merge(coeff2) |> Map.merge(coeff3)
  end

  @spec measurement_registers(BMP280.sensor_type(), any()) :: %{byte() => byte()}
  def measurement_registers(_sensor_type, _options \\ nil)

  def measurement_registers(:bmp180, :temperature) do
    <<95, 16, 0>>
    |> binary_to_address_byte_map({0xF6, 3})
  end

  def measurement_registers(:bmp180, :pressure) do
    <<161, 135, 0>>
    |> binary_to_address_byte_map({0xF6, 3})
  end

  def measurement_registers(:bmp280, _) do
    # press_msb: 6 bytes from 0xF7
    <<69, 89, 64, 130, 243, 0>>
    |> binary_to_address_byte_map({0xF7, 6})
  end

  def measurement_registers(:bme280, _) do
    # press_msb: 8 bytes from 0xF7
    <<69, 89, 64, 130, 243, 0, 137, 109>>
    |> binary_to_address_byte_map({0xF7, 8})
  end

  def measurement_registers(:bme680, _) do
    # press_msb: 8 bytes from 0x1F
    pres_msb =
      <<96, 30, 144, 117, 93, 192, 65, 180>>
      |> binary_to_address_byte_map({0x1F, 8})

    # gas_r_msb: 2bytes from 0x2A
    gas_r_msb =
      <<166, 139>>
      |> binary_to_address_byte_map({0x2A, 2})

    Map.merge(pres_msb, gas_r_msb)
  end

  defp binary_to_address_byte_map(data, {address, how_many}) do
    addresses = address..(address + how_many - 1)
    bytes = for(<<r::8 <- data>>, do: r)
    Enum.zip(addresses, bytes) |> Map.new()
  end
end
