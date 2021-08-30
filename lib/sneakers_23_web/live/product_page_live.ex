defmodule Sneakers23Web.ProductPageLive do
  # use Sneakers23Web, :live_view
  use Phoenix.LiveView
	alias Sneakers23Web.ProductView

	def render(assigns) do
	  Phoenix.View.render(ProductView, "live_index.html",
    assigns)
	end

	def mount(_params, session ,socket) do
    IO.puts inspect session
	  {:ok, products} = Sneakers23.Inventory.get_complete_products()
	  socket = assign(socket, :products, products)


    if connected?(socket) do
      subscribe_to_products(products)
    end

	  {:ok, socket}
	end

  defp subscribe_to_products(products) do
    # sub to weither mark_product_released or item_sold
    Enum.each(products, fn %{id: id} ->
      Phoenix.PubSub.subscribe(Sneakers23.PubSub, "product:#{id}")
    end)
  end

  def handle_info(%{event: "released"}, socket) do
	  {:noreply, load_products_from_memory(socket)}
  end

  def handle_info(%{event: "stock_change"}, socket) do
	  {:noreply, load_products_from_memory(socket)}
  end

  defp load_products_from_memory(socket) do
	  {:ok, products} = Sneakers23.Inventory.get_complete_products()
	  assign(socket, :products, products)
  end
end
