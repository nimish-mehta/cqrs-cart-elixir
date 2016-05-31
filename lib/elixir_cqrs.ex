defmodule ElixirCqrs do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      worker(EventStore, [])
    ]
    opts = [strategy: :one_for_one, name: ElixirCqrs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
