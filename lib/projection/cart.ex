defmodule Projection.Cart do
  defstruct id: nil, line_items: %{}

  def consume_events(event_source, id) do
    Enum.reduce(event_source.events, nil, fn
      (%CreatedCart{id: cart_id}, acc) when cart_id == id ->
        %__MODULE__{id: cart_id}
      (%AddedToCart{id: cart_id, item: item, count: count}, acc) when cart_id == id ->
        add_to_cart(acc, item, count)
      (%RemovedFromCart{id: cart_id, item: item, count: count}, acc) when cart_id == id ->
        remove_from_cart(acc, item, count)
      (_, acc) ->
        acc
    end)
  end

  def add_to_cart(%__MODULE__{line_items: line_items} = existing, item, count) do
    existing_line_item = line_items[item.id]
    line_item_to_insert = if existing_line_item do
      {quantity, _} = existing_line_item
      {quantity + count, item}
    else
      {count, item}
    end
    line_items = Map.put(line_items, item.id, line_item_to_insert)
    %__MODULE__{existing | line_items: line_items}
  end

  def remove_from_cart(%__MODULE__{line_items: line_items} = existing, item, count) do
    line_item = {existing_count, _} = line_items[item.id]
    line_items = cond do
      existing_count > count ->
        Map.put(line_items, item.id, {existing_count - count, item})
      count == existing_count ->
        Map.delete(line_items, item.id)
    end
    %__MODULE__{existing | line_items: line_items}
  end

end
