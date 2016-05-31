defmodule ElixirCqrsTest do
  use ExUnit.Case
  doctest ElixirCqrs

  test "roundtrip" do
    EventStore.init
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})  # 1 event
    inventory = %Inventory{}
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "1", 2) # 2 events
    assert Enum.count(EventStore.events) == 5
  end

  test "the workflow" do
    EventStore.init
    assert EventStore.events == []
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})
    assert Enum.count(EventStore.events) == 1
    inventory = %Inventory{}
    {:ok, _, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2)
    assert Enum.count(EventStore.events) == 3
    {:ok, _, _} = MoveItemFromInventoryToCart.run(cart, inventory, "2", 2)
    assert Enum.count(EventStore.events) == 5
  end

  test "the workflow add same item twice" do
    EventStore.init
    assert EventStore.events == []
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})
    assert Enum.count(EventStore.events) == 1
    inventory = %Inventory{}
    {:ok, _, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2)
    assert Enum.count(EventStore.events) == 3
    {:ok, _, _} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2)
    assert Enum.count(EventStore.events) == 5
  end


  test "the workflow with two carts" do
    EventStore.init
    assert EventStore.events == []
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})
    assert Enum.count(EventStore.events) == 1
    inventory = %Inventory{}
    {:ok, _, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2)
    assert Enum.count(EventStore.events) == 3
    {:ok, cart2} = Repo.execute_command(%Cart{}, %CreateCart{})
    {:ok, _, _} = MoveItemFromInventoryToCart.run(cart2, inventory, "2", 2)
    assert Enum.count(EventStore.events) == 6
  end
end
