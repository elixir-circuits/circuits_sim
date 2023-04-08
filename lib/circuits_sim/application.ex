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

    Enum.each(config, fn device_options ->
      {:ok, _} =
        DynamicSupervisor.start_child(
          CircuitSim.DeviceSupervisor,
          device_spec(device_options)
        )
    end)
  end

  defp device_spec(device) when is_atom(device) do
    {device, []}
  end

  defp device_spec({device, options} = device_options)
       when is_atom(device) and is_list(options) do
    device_options
  end
end
