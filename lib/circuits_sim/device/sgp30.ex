# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Device.SGP30 do
  @moduledoc """
  Sensirion SGP30 gas sensor

  Typically found at 0x58
  See the [datasheet](https://www.mouser.com/datasheet/2/682/Sensirion_Gas_Sensors_SGP30_Datasheet_EN-1148053.pdf)
  Many features aren't implemented.

  Call the following functions to change the state of the sensor.

  * `set_tvoc_ppb/3`
  * `set_co2_eq_ppm/3`
  * `set_h2_raw/3`
  * `set_ethanol_raw/3`
  """
  alias CircuitsSim.I2C.I2CDevice
  alias CircuitsSim.I2C.I2CServer

  defstruct current: nil, serial: 0, tvoc_ppb: 0, co2_eq_ppm: 0, h2_raw: 0, ethanol_raw: 0

  @type t() :: %__MODULE__{
          current: atom(),
          serial: integer(),
          tvoc_ppb: integer(),
          co2_eq_ppm: integer(),
          h2_raw: integer(),
          ethanol_raw: integer()
        }

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device_options = Keyword.take(args, [:serial])
    device = __MODULE__.new(device_options)
    I2CServer.child_spec_helper(device, args)
  end

  @type options() :: [serial: integer()]

  @spec new(options()) :: %__MODULE__{
          current: nil,
          serial: 0,
          tvoc_ppb: 0,
          co2_eq_ppm: 0,
          h2_raw: 0,
          ethanol_raw: 0
        }
  def new(options \\ []) do
    serial = options[:serial] || 0
    %__MODULE__{serial: serial}
  end

  @spec set_tvoc_ppb(String.t(), Circuits.I2C.address(), integer()) :: :ok
  def set_tvoc_ppb(bus_name, address, value) when is_integer(value) do
    I2CServer.send_message(bus_name, address, {:set_tvoc_ppb, value})
  end

  @spec set_co2_eq_ppm(String.t(), Circuits.I2C.address(), integer()) :: :ok
  def set_co2_eq_ppm(bus_name, address, value) when is_integer(value) do
    I2CServer.send_message(bus_name, address, {:set_co2_eq_ppm, value})
  end

  @spec set_h2_raw(String.t(), Circuits.I2C.address(), integer()) :: :ok
  def set_h2_raw(bus_name, address, value) when is_integer(value) do
    I2CServer.send_message(bus_name, address, {:set_h2_raw, value})
  end

  @spec set_ethanol_raw(String.t(), Circuits.I2C.address(), integer()) :: :ok
  def set_ethanol_raw(bus_name, address, value) when is_integer(value) do
    I2CServer.send_message(bus_name, address, {:set_ethanol_raw, value})
  end

  ## protocol implementation

  defimpl I2CDevice do
    @crc_alg :cerlc.init({8, 0x31, 0xFF, 0x00, false})

    @impl I2CDevice
    def read(%{current: :iaq_measure} = state, count) do
      result = binary_for_measure(state) |> trim_pad(count)
      {{:ok, result}, %{state | current: nil}}
    end

    def read(%{current: :iaq_measure_raw} = state, count) do
      result = binary_for_measure_raw(state) |> trim_pad(count)
      {{:ok, result}, %{state | current: nil}}
    end

    def read(state, count) do
      {{:ok, :binary.copy(<<0>>, count)}, %{state | current: nil}}
    end

    @impl I2CDevice
    def write(state, <<0x20, 0x03>>), do: %{state | current: :iaq_init}
    def write(state, <<0x20, 0x08>>), do: %{state | current: :iaq_measure}
    def write(state, <<0x20, 0x50>>), do: %{state | current: :iaq_measure_raw}
    def write(state, _), do: state

    @impl I2CDevice
    def write_read(state, <<0x36, 0x82>>, count) do
      result = binary_for_serial(state) |> trim_pad(count)
      {{:ok, result}, %{state | current: nil}}
    end

    def write_read(state, _to_write, read_count) do
      {:binary.copy(<<0>>, read_count), %{state | current: nil}}
    end

    defp trim_pad(x, count) when byte_size(x) >= count, do: :binary.part(x, 0, count)
    defp trim_pad(x, count), do: x <> :binary.copy(<<0>>, count - byte_size(x))

    @impl I2CDevice
    def render(state) do
      state
    end

    @impl I2CDevice
    def handle_message(state, {:set_tvoc_ppb, value}) do
      {:ok, %{state | tvoc_ppb: value}}
    end

    def handle_message(state, {:set_co2_eq_ppm, value}) do
      {:ok, %{state | co2_eq_ppm: value}}
    end

    def handle_message(state, {:set_h2_raw, value}) do
      {:ok, %{state | h2_raw: value}}
    end

    def handle_message(state, {:set_ethanol_raw, value}) do
      {:ok, %{state | ethanol_raw: value}}
    end

    defp binary_for_serial(state) do
      <<state.serial::48>> |> add_crcs()
    end

    defp binary_for_measure(state) do
      co2_eq_ppm = state.co2_eq_ppm
      tvoc_ppb = state.tvoc_ppb

      <<co2_eq_ppm::16, tvoc_ppb::16>> |> add_crcs()
    end

    defp binary_for_measure_raw(state) do
      h2_raw = state.h2_raw
      ethanol_raw = state.ethanol_raw

      <<h2_raw::16, ethanol_raw::16>> |> add_crcs()
    end

    defp add_crcs(data) do
      for <<uint16::16 <- data>>, into: <<>> do
        crc = :cerlc.calc_crc(<<uint16::16>>, @crc_alg)
        <<uint16::16, crc>>
      end
    end
  end

  defimpl String.Chars do
    @spec to_string(CircuitsSim.Device.SGP30.t()) :: String.t()
    def to_string(state) do
      [
        "tvoc_ppb: #{state.tvoc_ppb}",
        "co2_eq_ppm: #{state.co2_eq_ppm}",
        "h2_raw: #{state.h2_raw}",
        "ethanol_raw: #{state.ethanol_raw}"
      ]
      |> Enum.join(", ")
    end
  end
end
