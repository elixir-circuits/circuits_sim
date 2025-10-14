# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule CircuitsSim.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: CircuitSim.DeviceRegistry},
      {DynamicSupervisor, name: CircuitSim.DeviceSupervisor, strategy: :one_for_one},
      {Task, &add_devices/0}
    ]

    opts = [strategy: :one_for_one, name: CircuitsSim.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp add_devices() do
    config = Application.get_env(:circuits_sim, :config, %{})
    Enum.each(config, &CircuitsSim.add_device/1)
  end
end
