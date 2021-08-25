defmodule Sneakers23Web.Admin.DashboardChannel do
  use Phoenix.Channel

  def join("admin:cart_tracker", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    # presence_state is automatically pickup by the Presence class(of Phoenix JS)
    # this sets the initial state
	  push(socket, "presence_state", Sneakers23Web.CartTracker.all_carts())
	  {:noreply, socket}
  end
end
