defmodule Sneakers23Web.ShoppingCartChannel do
	use Phoenix.Channel

  import Sneakers23Web.CartView, only: [cart_to_map: 1] # takes one argument

	alias Sneakers23.Checkout

	intercept ["cart_updated"]

  def join("cart:" <> id, params, socket) when byte_size(id) == 64 do
	  cart = get_cart(params)
	  socket = assign(socket, :cart, cart)
    # call itself
    send(self(), :send_cart)
		# subscribe to all the items within the cart
		# dynamic subscription where
		# 1. the items are subscribed to when they are added
		# 2. unsubscribed when they are removed
		enqueue_cart_subscriptions(cart)

	  {:ok, socket}
  end

  def join("cart:" <> _id, _params, socket) do
    {:ok, socket}
  end

	def handle_info({:subscribe, item_id}, socket) do
		Phoenix.PubSub.subscribe(Sneakers23.PubSub, "item_out:#{item_id}")
		{:noreply, socket}
	end

	def handle_info({:unsubscribe, item_id}, socket) do
	  Phoenix.PubSub.unsubscribe(Sneakers23.PubSub, "item_out:#{item_id}")
	  {:noreply, socket}
	end

	# handler for the above two pubsub item_out events
	def handle_info({:item_out, _id}, socket = %{assigns: %{cart: cart}}) do
		push(socket, "cart", cart_to_map(cart))
		{:noreply, socket}
	end

	def handle_info(:send_cart, socket = %{assigns: %{cart: cart}}) do
    # map the cart into the right format for client
	  push(socket, "cart", cart_to_map(cart))
	  {:noreply, socket}
	end

	def handle_in(
		"add_item", %{"item_id" => id}, socket = %{assigns: %{cart: cart}}) do
		case Checkout.add_item_to_cart(cart, String.to_integer(id)) do
	  	{:ok, new_cart} ->
				send(self(), {:subscribe, id})
				broadcast_cart(new_cart, socket, added: [id])
	    	socket = assign(socket, :cart, new_cart)
	    	{:reply, {:ok, cart_to_map(new_cart)}, socket}

	  	{:error, :duplicate_item} ->
	    	{:reply, {:error, %{error: "duplicate_item"}}, socket}
		end
	end

	def handle_in(
		"remove_item", %{"item_id" => id}, socket = %{assigns: %{cart: cart}}) do
		case Checkout.remove_item_from_cart(cart, String.to_integer(id)) do
	  	{:ok, new_cart} ->
				send(self(), {:unsubscribe, id})
				broadcast_cart(new_cart, socket, removed: [id])
	    	socket = assign(socket, :cart, new_cart)
	    	{:reply, {:ok, cart_to_map(new_cart)}, socket}

	  	{:error, :not_found} ->
	    	{:reply, {:error, %{error: "not_found"}}, socket}
		end
	end

	# before broadcasting out for "cart_updated"
	# need to `get_cart` to get deserialized cart and push to channel "cart"
	def handle_out("cart_updated", params, socket) do
		modify_subscriptions(params)
		cart = get_cart(params)
		socket = assign(socket, :cart, cart)
		push(socket, "cart", cart_to_map(cart))

		{:noreply, socket}
	end

	defp modify_subscriptions(%{"added" => add, "removed" => remove}) do
		Enum.each(add, & send(self(), {:subscribe, &1}))
		Enum.each(remove, & send(self(), {:unsubscribe, &1}))
	end

	defp broadcast_cart(cart, socket, opts) do
		{:ok, serialized} = Checkout.export_cart(cart)

		# broadcast to all other clients (except caller)
		broadcast_from(socket, "cart_updated", %{
	  	"serialized" => serialized,
	  	"added" => Keyword.get(opts, :added, []),
	  	"removed" => Keyword.get(opts, :removed, [])
		})
	end

  defp get_cart(params) do
	  params
	  |> Map.get("serialized", nil)
	  |> Checkout.restore_cart()
  end

	defp enqueue_cart_subscriptions(cart) do
		cart
		|> Checkout.cart_item_ids()
		|> Enum.each(fn id ->
	  	send(self(), {:subscribe, id})
		end)
	end
end
