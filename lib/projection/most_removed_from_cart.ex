defmodule MostRemovedFromCart do
  defstruct counts: nil, most_removed: nil, removed_times: 0

  def consume_events(event_source) do
    counts = RemovedFromCartCount.consume_events(event_source)
    {most_removed, removed_times} = Enum.reduce(counts.counts, {nil, 0}, fn
      ({item_id, count} = nex, {existing_id, curr_count} = acc) when curr_count < count -> nex
      ({item_id, count} = nex, {existing_id, curr_count} = acc) -> acc
    end)
    %MostRemovedFromCart{counts: counts, most_removed: most_removed, removed_times: removed_times}
  end
end
