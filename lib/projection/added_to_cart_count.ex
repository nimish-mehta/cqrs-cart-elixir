defmodule AddedToCartCount do
  defstruct counts: %{}

  def consume_events(event_source) do
    Enum.reduce(event_source.events, %AddedToCartCount{},
      fn
        (%AddedToCart{item: %{id: id}, count: add_count}, %AddedToCartCount{counts: counts} = projection) ->
          existing = Map.get(counts, id)
          updated_counts = if existing do
            Map.put(counts, id, existing + add_count)
          else
            Map.put(counts, id, add_count)
          end
          %AddedToCartCount{projection|counts: updated_counts}
        (_, acc) -> acc
    end)
  end
end
