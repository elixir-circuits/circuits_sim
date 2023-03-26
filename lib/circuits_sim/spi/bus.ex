defmodule CircuitsSim.SPI.Bus do
  @moduledoc false

  alias Circuits.SPI.Bus

  defstruct [:bus_name]
  @type t() :: %__MODULE__{bus_name: String.t()}

  @spec render(t()) :: String.t()
  def render(%__MODULE__{} = _bus) do
    "test"
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
  end

  defimpl Bus do
    @impl Bus
    def config(%CircuitsSim.SPI.Bus{} = _bus) do
      config = %{
        mode: 0,
        bits_per_word: 8,
        speed_hz: 1_000_000,
        delay_us: 0,
        lsb_first: false,
        sw_lsb_first: false
      }

      {:ok, config}
    end

    @impl Bus
    def transfer(%CircuitsSim.SPI.Bus{} = _bus, _data) do
      {:ok, <<>>}
    end

    @impl Bus
    def close(%CircuitsSim.SPI.Bus{}), do: :ok

    @impl Bus
    def max_transfer_size(%CircuitsSim.SPI.Bus{}), do: 1024
  end
end
