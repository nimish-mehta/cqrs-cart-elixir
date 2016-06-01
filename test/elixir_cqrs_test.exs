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

  test "consumption of events by the projection remove from cart count" do
    EventStore.init
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})  # 1 event
    inventory = %Inventory{}
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "1", 2) # 2 events
    assert Enum.count(EventStore.events) == 5
    assert RemovedFromCartCount.consume_events(EventStore) == %RemovedFromCartCount{counts: %{"1" => 2}}
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
    # projection
    assert AddedToCartCount.consume_events(EventStore) == %AddedToCartCount{counts: %{"1" => 2, "2" => 2}}
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

  test "consumption of events by the projection" do
    EventStore.init
    assert EventStore.events == []
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})
    assert Enum.count(EventStore.events) == 1
    inventory = %Inventory{}
    {:ok, _, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2)
    assert Enum.count(EventStore.events) == 3
    {:ok, _, _} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2)
    assert Enum.count(EventStore.events) == 5
    assert AddedToCartCount.consume_events(EventStore) == %AddedToCartCount{counts: %{"1" => 4}}
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

  test "consumption of events by  projection remove from cart count for multiple items" do
    EventStore.init
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})  # 1 event
    inventory = %Inventory{}
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "3", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "2", 2) # 2 events

    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "3", 1) # 2 events
    assert Enum.count(EventStore.events) == 11
    assert RemovedFromCartCount.consume_events(EventStore) == %RemovedFromCartCount{counts: %{"1" => 2, "3" => 1}}
  end

  test "most removed item in store" do
    EventStore.init
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})  # 1 event
    inventory = %Inventory{}
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "3", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "2", 2) # 2 events

    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "3", 1) # 2 events
    assert Enum.count(EventStore.events) == 11
    most_removed = MostRemovedFromCart.consume_events(EventStore)
    assert most_removed.most_removed  == "1"
    assert most_removed.removed_times ==  2
  end

  test "cart projection" do
    EventStore.init
    {:ok, cart} = Repo.execute_command(%Cart{}, %CreateCart{})  # 1 event
    IO.inspect cart
    inventory = %Inventory{}
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "3", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromInventoryToCart.run(cart, inventory, "2", 2) # 2 events

    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "1", 2) # 2 events
    {:ok, cart, inventory} = MoveItemFromCartToInventory.run(cart, inventory, "3", 1) # 2 events
    IO.inspect cart
    assert Enum.count(EventStore.events) == 11
    assert Projection.Cart.consume_events(EventStore, cart.id) == %Projection.Cart{id: cart.id,
                                                                                   line_items: %{"2" => {2, %{id: "2"}}, "3" => {1, %{id: "3"}}}}
  end

end
