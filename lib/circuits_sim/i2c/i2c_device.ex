defprotocol CircuitsSim.I2C.I2CDevice do
  @moduledoc """
  A protocol for I2C devices

  See `Circuits.I2C.SimpleI2CDevice` if you have a simple register-based I2C device.
  """

  @doc """
  Read count bytes
  """
  @spec read(t(), non_neg_integer()) :: {binary(), t()}
  def read(dev, count)

  @doc """
  Write data to the device
  """
  @spec write(t(), binary()) :: t()
  def write(dev, data)

  @doc """
  Write data to the device and immediately follow it with a read
  """
  @spec write_read(t(), binary(), non_neg_integer()) :: {binary(), t()}
  def write_read(dev, data, read_count)

  @doc """
  Return the internal state as ASCII art
  """
  @spec render(t()) :: IO.ANSI.ansidata()
  def render(dev)

  @doc """
  Handle an user message

  User messages are used to modify the state of the simulated device outside of
  I2C. This can be used to simulate real world changes like temperature changes
  affecting a simulated temperature sensor. Another use is as a hook for getting
  internal state.
  """
  @spec handle_message(t(), any()) :: {any(), t()}
  def handle_message(dev, message)
end
