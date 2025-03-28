defmodule DotanicksWeb.DotanicksLive.Index do
  use DotanicksWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      IO.inspect("SUBSCRIBE to nicks:#{id}")
      Phoenix.PubSub.subscribe(Dotanicks.PubSub, "nicks:#{id}")
      Dotanicks.generate(id)
    end

    {:ok,
     socket
     # |> assign(:loading, false)
     # |> assign(:loading_text, "")
     |> assign(:nicks, [])
     |> assign(:page_title, "Анализируйте свои матчи и получайте уникальные никнеймы")}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:loading, false)
     |> assign(:loading_text, "")
     |> assign(:nicks, [])
     |> assign(:page_title, "Анализируйте свои матчи и получайте уникальные никнеймы")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("generate", %{"dotabuff_url" => dotabuff_url}, socket) do
    id = profile_id(dotabuff_url)

    {:noreply,
     socket
     |> apply_action(:generate, %{"id" => id})
     |> push_navigate(to: "/#{id}")}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp apply_action(socket, :generate, %{"id" => id}) do
    socket
    |> assign(:loading_text, "Генерируем ники для профиля #{id}")
    |> assign(:loading, true)
  end

  @impl true
  def handle_info({:core_event, {:ok, nicks}}, socket) do
    {:noreply,
     socket
     |> update(:loading, fn _ -> false end)
     |> update(:nicks, fn _ -> nicks end)}
  end

  def handle_info({:core_event, {:error, err}}, socket) do
    {:noreply,
     socket
     |> update(:loading, fn _ -> false end)
     |> update(:nicks, fn _ -> [] end)
     |> put_flash(:error, "Ошибка генерации ников")}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def profile_id(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> String.split("/", trim: true)
    |> Enum.at(1)
  end
end
