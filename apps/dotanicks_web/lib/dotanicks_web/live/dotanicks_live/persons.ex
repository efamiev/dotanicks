defmodule DotanicksWeb.DotanicksLive.Persons do
  use DotanicksWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:persons, persons())
     |> assign(:page_title, "Профессиональные игроки с уникальными никнеймами")}
  end

  def persons do
    [
      %{name: "Kuroky", nicks: [%{name: "Nickname1", desctiption: "What a player"}]},
      %{name: "Topson", nicks: [%{name: "Nickname1", desctiption: "What a player"}]}
    ]
  end
end
