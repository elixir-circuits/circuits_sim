# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSimTest do
  use ExUnit.Case
  doctest CircuitsSim

  test "info/0 does not crash" do
    CircuitsSim.info()
  end
end
