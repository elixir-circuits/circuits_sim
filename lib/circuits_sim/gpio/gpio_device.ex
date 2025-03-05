# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defprotocol CircuitsSim.GPIO.GPIODevice do
  @moduledoc """
  A protocol for GPIO devices
  """
  alias Circuits.GPIO

  @doc """
  Read state

  This is only called when the GPIO is an input. If the GPIO is an output, the most recently
  written value is returned without making this call.

  If the wire is not being driven (i.e., high impedance state or disconnected), return `:hi_z`.
  """
  @spec read(t()) :: GPIO.value() | :hi_z
  def read(dev)

  @doc """
  Write state

  This is only called when the GPIO is set as an output.
  """
  @spec write(t(), GPIO.value()) :: t()
  def write(dev, value)

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

  @doc """
  Handle a message sent to the GenServer running the device

  These are used for timeouts or other events
  """
  @spec handle_info(t(), any()) :: t()
  def handle_info(dev, message)
end
