import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :dotanicks_web, DotanicksWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

nicks_history_file =
  case System.get_env("NICKS_HISTORY_FILE") do
    file when is_binary(file) ->
      to_charlist(file)

    _ ->
      raise """
      Environment variable NICKS_HISTORY_FILE is missing.
      """
  end

config :dotanicks, :nicks_history_file, nicks_history_file

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
