defmodule Dotanicks do
  @moduledoc """
  Dotanicks keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def generate(id) do
    Task.async(fn ->
      IO.inspect("BROADCAST to nicks:#{id}")
      Process.sleep(7000)
      Phoenix.PubSub.broadcast(
        Dotanicks.PubSub,
        "nicks:#{id}",
        {:core_event, [%{name: "Nickname1", description: "What a player"}]}
      )
    end)
  end
end
