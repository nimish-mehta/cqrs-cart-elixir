defmodule MoveItemFromCartToInventory do
  def run(cart, inventory, item_id, count) do
    with {:ok, cart}      <- Repo.execute_command(cart, %RemoveFromCart{item: %{id: item_id}, count: count}),
         {:ok, inventory} <- Repo.execute_command(inventory, %RestockInventory{id: item_id, count: count}),
    do: {:ok, cart, inventory}
  end
end
