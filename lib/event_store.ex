defmodule EventStore do
  def init do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def save_event(event) do
    Agent.update(__MODULE__, fn (events) ->
      [event | events]
    end)
  end

  def events do
    Agent.get(__MODULE__, fn (events) -> events end)
  end

end
