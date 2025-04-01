defmodule DotanicksWeb.Router do
  use DotanicksWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DotanicksWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admins_only do
    plug :admin_basic_auth
  end

  scope "/live_dashboard" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/", metrics: DotanicksWeb.Telemetry
  end

  scope "/", DotanicksWeb do
    pipe_through :browser

    # Rewrite to controller page
    live "/", DotanicksLive.Index
    live "/nicks/:id", DotanicksLive.Index

    # Rewrite to controller page and sse
    get "/persons", PageController, :persons

    # get "/", PageController, :home
  end

  defp admin_basic_auth(conn, _opts) do
    username = System.fetch_env!("AUTH_USERNAME")
    password = System.fetch_env!("AUTH_PASSWORD")
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

  # Enable LiveDashboard in development
  # if Application.compile_env(:dotanicks_web, :dev_routes) do
  #   # If you want to use the LiveDashboard in production, you should put
  #   # it behind authentication and allow only admins to access it.
  #   # If your application does not have an admins-only section yet,
  #   # you can use Plug.BasicAuth to set up some basic authentication
  #   # as long as you are also using SSL (which you should anyway).
  #   import Phoenix.LiveDashboard.Router
  #
  #   scope "/dev" do
  #     pipe_through :browser
  #
  #     live_dashboard "/dashboard", metrics: DotanicksWeb.Telemetry
  #   end
  # end
end
