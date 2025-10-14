# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defprotocol CircuitsSim.I2C.I2CDevice do
  @moduledoc """
  A protocol for I2C devices

  See `Circuits.I2C.SimpleI2CDevice` if you have a simple register-based I2C device.
  """

  @doc """
  Read count bytes

  The first item in the returned tuple is what's returned from the original
  call to Circuits.I2C.read/2. Try to make the errors consistent with that
  function if possible.
  """
  @spec read(t(), non_neg_integer()) :: {{:ok, binary()} | {:error, any()}, t()}
  def read(dev, count)

  @doc """
  Write data to the device
  """
  @spec write(t(), binary()) :: t()
  def write(dev, data)

  @doc """
  Write data to the device and immediately follow it with a read
  """
  @spec write_read(t(), binary(), non_neg_integer()) :: {{:ok, binary()} | {:error, any()}, t()}
  def write_read(dev, data, read_count)

  @doc """
  Return the device struct for rendering

  The returned struct should implement both `Kino.Render` for LiveBook visualization
  and `String.Chars` for CLI output.
  """
  @spec render(t()) :: t()
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
