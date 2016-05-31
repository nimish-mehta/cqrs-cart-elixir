defmodule MoveItemFromInventoryToCart do
  def run(cart, inventory, item_id, count) do
    with {:ok, inventory} <- Repo.execute_command(inventory, %ReserveInInventory{id: item_id, count: count}),
         {:ok, cart}      <- Repo.execute_command(cart, %AddToCart{item: %{id: item_id}, count: count}),
    do: {:ok, cart, inventory}
  end
end
