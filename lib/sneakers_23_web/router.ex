#---
# Excerpted from "Real-Time Phoenix",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/sbsockets for more book information.
#---
defmodule Sneakers23Web.Router do
  use Sneakers23Web, :router
  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, {Sneakers23Web.LayoutView, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Sneakers23Web.CartIdPlug
  end

  scope "/", Sneakers23Web do
    pipe_through :browser

    live "/drops", ProductPageLive
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :basic_auth, Application.compile_env(:sneakers_23, :basic_auth)
    #function plug, as long as argument is conn, and return is conn
    plug :put_layout, {Sneakers23Web.LayoutView, :admin}
  end

  scope "/", Sneakers23Web do
    pipe_through :browser

    get "/", ProductController, :index
    get "/checkout", CheckoutController, :show
    post "/checkout", CheckoutController, :purchase
    get "/checkout/complete", CheckoutController, :success
  end

  scope "/admin", Sneakers23Web.Admin do
    pipe_through [:browser, :admin]

    get "/", DashboardController, :index
  end
end
