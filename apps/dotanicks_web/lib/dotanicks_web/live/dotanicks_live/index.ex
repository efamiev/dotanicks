defmodule DotanicksWeb.DotanicksLive.Index do
  use DotanicksWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:dotabuff_url, "")
     |> assign(:loading, false)
     |> assign(:loading_text, "")
     |> assign(:nicks, [])
     |> assign(:prev_nicks, [])
     |> assign(:page_title, "Dotanicks — генератор никнеймов по Dota 2")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("generate", %{"dotabuff_url" => dotabuff_url}, socket) do
    id = profile_id(dotabuff_url)

    Dotanicks.generate(id)

    {:noreply,
     socket
     |> assign(:loading, true)
     |> assign(:loading_text, "Генерируем ники для профиля #{id}")
     |> push_patch(to: "/#{id}")}
  end

  defp apply_action(socket, :generate, %{"id" => id}) do
    Phoenix.PubSub.subscribe(Dotanicks.PubSub, "nicks:#{id}")

    socket
    |> assign(:prev_nicks, load_prev_nicks(id))
    |> assign(:dotabuff_url, "https://www.dotabuff.com/players/#{id}")
  end

  defp apply_action(socket, _action, _params) do
    socket
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

  def load_prev_nicks(id) do
    case Dotanicks.NicksHistory.get_all(id) do
      [{^id, list}] -> [list]
      _ -> []
    end
  end

  def profile_id(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> String.split("/", trim: true)
    |> Enum.at(1)
  end
end
