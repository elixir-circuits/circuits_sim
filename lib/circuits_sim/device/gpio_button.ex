defmodule CircuitsSim.Device.GPIOButton do
  @moduledoc """
  This is simple GPIO-connected button

  Buttons can be connected in a few ways:

  * `:external_pullup` - 0 is pressed, 1 is released
  * `:external_pulldown` - 1 is pressed, 0 is released
  * `:internal_pullup` - 0 is pressed. The GPIO will need to be configured in pullup mode for releases to be 1.
  * `:internal_pulldown` - 1 is pressed. The GPIO will need to be configured in pulldown mode for releases to be 0.

  Call `press/1` and `release/1` to change the state of the button.
  """
  alias Circuits.GPIO
  alias CircuitsSim.GPIO.GPIODevice
  alias CircuitsSim.GPIO.GPIOServer

  @type connection_mode() ::
          :external_pullup | :external_pulldown | :internal_pullup | :internal_pulldown

  defstruct state: :released, connection: :external_pullup

  @type t() :: %__MODULE__{state: :pressed | :released, connection: connection_mode()}

  @type options() :: [connection: connection_mode()]

  @spec child_spec(options()) :: %{
          id: GPIOServer,
          start: {GPIOServer, :start_link, [[keyword()], ...]}
        }
  def child_spec(args) do
    device = new(args)
    GPIOServer.child_spec_helper(device, args)
  end

  @spec new(options()) :: t()
  def new(options) do
    %__MODULE__{connection: Keyword.get(options, :connection, :external_pullup)}
  end

  @doc """
  Press the button

  Pass in a duration in milliseconds to automatically release the button after
  a timeout.
  """
  @spec press(GPIO.pin_spec(), non_neg_integer() | :infinity) :: :ok
  def press(pin_spec, duration \\ :infinity)
      when duration == :infinity or (duration > 0 and duration < 10000) do
    GPIOServer.send_message(pin_spec, {:press, duration})
  end

  @doc """
  Release the button
  """
  @spec release(GPIO.pin_spec()) :: :ok
  def release(pin_spec) do
    GPIOServer.send_message(pin_spec, :release)
  end

  defimpl GPIODevice do
    @impl GPIODevice
    def write(state, _value) do
      # Ignore
      state
    end

    @impl GPIODevice
    def read(%{state: :pressed, connection: :external_pullup}), do: 0
    def read(%{state: :released, connection: :external_pullup}), do: 1
    def read(%{state: :pressed, connection: :external_pulldown}), do: 1
    def read(%{state: :released, connection: :external_pulldown}), do: 0
    def read(%{state: :pressed, connection: :internal_pullup}), do: 0
    def read(%{state: :released, connection: :internal_pullup}), do: :hi_z
    def read(%{state: :pressed, connection: :internal_pulldown}), do: 1
    def read(%{state: :released, connection: :internal_pulldown}), do: :hi_z

    @impl GPIODevice
    def render(state) do
      "Button #{state.state} connected with #{state.connection}"
    end

    @impl GPIODevice
    def info(state) do
      %{device: __MODULE__, value: state.state}
    end

    @impl GPIODevice
    def handle_message(state, {:press, duration}) do
      if duration != :infinity do
        # Don't try to do anything fancy with timeouts
        _ = Process.send_after(self(), :release, duration)
        :ok
      end

      {:ok, %{state | state: :pressed}}
    end

    def handle_message(state, :release) do
      {:ok, %{state | state: :released}}
    end

    @impl GPIODevice
    def handle_info(state, :release) do
      %{state | state: :released}
    end
  end
end
