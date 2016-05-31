defmodule Inventory do
  # default to avoid adding commands for adding to inventory
  defstruct inventory_items: %{
    "1" => %{id: "1", name: "product", available: 5},
    "2" => %{id: "2", name: "product", available: 5},
    "3" => %{id: "3", name: "product", available: 5}
  }

  def execute_command(inventory, %ReserveInInventory{id: id, count: count} = command) do
    inventory_item = Map.get(inventory.inventory_items, id)
    inventory_update =
      if inventory_item do
        if inventory_item.available >= count do
          {:ok, %{inventory_item| available: inventory_item.available - count}}
        else
          {:error, "The quantity requested in not available"}
        end
      else
        {:error, "The item requested for does not exist"}
      end

    case do_inventory_update(inventory, inventory_update) do
      {:ok, inventory} ->
        {%ReservedInInventory{id: id, count: count}, inventory}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute_command(inventory, %RestockInventory{id: id, count: count}) do
    inventory_item = Map.get(inventory.inventory_items, id)
    inventory_update =
      if inventory_item do
          {:ok, %{inventory_item| available: inventory_item.available + count}}
      else
        {:error, "The item requested for does not exist"}
      end
    case do_inventory_update(inventory, inventory_update) do
      {:ok, inventory} ->
        {%RestockedInventory{id: id, count: count}, inventory}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_inventory_update(inventory, {:ok, inventory_update}) do
    updated_inventory_items = Map.put(inventory.inventory_items, inventory_update.id, inventory_update)
    {:ok, %Inventory{inventory | inventory_items: updated_inventory_items}}
  end

  defp do_inventory_update(_inventory, {:error, reason}) do
    {:error, reason}
  end

end
