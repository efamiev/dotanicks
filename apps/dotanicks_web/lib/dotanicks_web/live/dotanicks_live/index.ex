defmodule DotanicksWeb.DotanicksLive.Index do
  use DotanicksWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:loading, false)
     |> assign(:loading_text, "")
     |> assign(:page_title, "Анализируйте свои матчи и получайте уникальные никнеймы")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp apply_action(socket, :generate, %{"id" => id}) do
    socket
    |> assign(:loading_text, "Генерируем ники для профиля #{id}.")
    |> assign(:loading, true)
  end

  @impl true
  def handle_event("generate", %{"dotabuff_url" => dotabuff_url}, socket) do
    {:noreply,
     socket
     |> assign(:loading_text, "Генерируем ники для профиля #{dotabuff_url}.")
     |> assign(:loading, true)
     |> push_navigate(to: "/#{profile_id(dotabuff_url)}")}
  end

  def profile_id(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> String.split("/", trim: true)
    |> Enum.at(1)
  end
end
