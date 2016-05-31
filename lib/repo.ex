defmodule Repo do

  def execute_command(aggregate, command) do
    case do_execute_command(aggregate, command) do
      {:error, reason}     ->
        {:error, reason}

      {event, aggregate}   ->
        store_event(event)
        {:ok, aggregate} # we return a updated snapshot everytime
    end
  end

  defp do_execute_command(aggregate, command) do
    aggregate.__struct__.execute_command(aggregate, command)
  end

  defp store_event(event) do
    EventStore.save_event(event)
  end

end
