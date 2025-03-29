# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :dotanicks_web,
  generators: [context_app: :dotanicks]

# Configures the endpoint
config :dotanicks_web, DotanicksWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DotanicksWeb.ErrorHTML, json: DotanicksWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Dotanicks.PubSub,
  live_view: [signing_salt: "5kyzVbIr"]

llm_api_key =
  System.get_env("LLM_API_KEY") ||
    raise """
    Environment variable LLM_API_KEY is missing.
    """

llm_system_content =
  System.get_env("LLM_SYSTEM_CONTENT") ||
    raise """
    Environment variable LLM_SYSTEM_CONTENT is missing.
    """

config :dotanicks, :llm_api_key, llm_api_key
config :dotanicks, :llm_system_content, llm_system_content
config :dotanicks, :nicks_history_file, "nicks_history.dets"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  dotanicks_web: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/dotanicks_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  dotanicks_web: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/dotanicks_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
