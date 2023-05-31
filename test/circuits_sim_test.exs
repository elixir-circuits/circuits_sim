defmodule CircuitsSimTest do
  use ExUnit.Case
  doctest CircuitsSim

  test "info/0 does not crash" do
    CircuitsSim.info()
  end
end
