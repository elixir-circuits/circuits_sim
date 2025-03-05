# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defprotocol CircuitsSim.SPI.SPIDevice do
  @moduledoc """
  A protocol for SPI devices
  """

  @doc """
  Transfer data
  """
  @spec transfer(t(), binary()) :: {binary(), t()}
  def transfer(dev, count)

  @doc """
  Return the internal state as ASCII art
  """
  @spec render(t()) :: IO.ANSI.ansidata()
  def render(dev)

  @doc """
  Handle an user message

  User messages are used to modify the state of the simulated device outside of
  SPI. This can be used to simulate real world changes like temperature changes
  affecting a simulated temperature sensor. Another use is as a hook for getting
  internal state.
  """
  @spec handle_message(t(), any()) :: {any(), t()}
  def handle_message(dev, message)
end
