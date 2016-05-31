defmodule Cart do

  defstruct id: nil,
    line_items: %{},
    user_id: nil

  def execute_command(_cart, %CreateCart{}) do
    id = UUID.uuid1()
    {%CreatedCart{id: id}, %Cart{id: id}}
  end

  def execute_command(cart, %AddToCart{item: item, count: count}) do
    {%AddedToCart{item: item, count: count, id: cart.id}, %__MODULE__{cart|line_items: add_to_line_items(cart.line_items, item, count)}}
  end

  def execute_command(cart, %RemoveFromCart{item: item, count: count}) do
    case remove_from_line_items(cart.line_items, item, count) do
      {:ok, line_items} ->
        {%RemovedFromCart{item: item, count: count, id: cart.id}, %__MODULE__{cart|line_items: line_items}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute_command(_) do
    {:error, "Command Not Supported"}
  end

  def add_to_line_items(line_items, item, count) do
    existing_line_item = line_items[item.id]
    line_item_to_insert = if existing_line_item do
      {quantity, _} = existing_line_item
      {quantity + count, item}
    else
      {count, item}
    end
    Map.put(line_items, item.id, line_item_to_insert)
  end

  def remove_from_line_items(line_items, item, count) do
    existing_line_item = line_items[item.id]
    delete_action =
      if existing_line_item do
        {quantity, _} = existing_line_item
        cond do
          quantity > count ->
            {:ok, {quantity - count, item}}
          quantity == count ->
            {:delete, item}
          true ->
            {:error, "remove count greater than present count"}
        end
      else
        {:error, "line item not present in cart"}
      end

    case delete_action do
      {:ok, updated_line_item} ->
        {:ok, Map.put(line_items, item.id, updated_line_item)}
      {:delete, item} ->
        {:ok, Map.delete(line_items, item.id)}
      {:error, reason} -> {:error, reason}
    end
  end
end
