defmodule DotanicksWeb.DotanicksLive.Index do
  use DotanicksWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    put_logger_metadata(Map.new(get_connect_info(socket, :x_headers)))

    {:ok,
     socket
     |> assign(:dotabuff_url, "")
     |> assign(:loading, false)
     |> assign(:nicks, [])
     |> assign(:prev_nicks, [])
     |> assign(:profile_name, "")
     |> assign_timezone}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("generate", %{"dotabuff_url" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("generate", %{"dotabuff_url" => dotabuff_url}, socket) do
    id = profile_id(dotabuff_url)

    Phoenix.PubSub.subscribe(Dotanicks.PubSub, "nicks:#{id}")
    Dotanicks.generate(id)

    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_patch(to: "/nicks/#{id}")}
  end

  def handle_event("update", %{"dotabuff_url" => dotabuff_url}, socket) do
    {:noreply, assign(socket, :dotabuff_url, dotabuff_url)}
  end

  def handle_event("show_history", _params, %{assigns: %{dotabuff_url: ""}} = socket) do
    {:noreply, socket}
  end

  def handle_event("show_history", _params, %{assigns: %{dotabuff_url: dotabuff_url}} = socket) do
    {:noreply, push_patch(socket, to: "/nicks/#{profile_id(dotabuff_url)}")}
  end

  @impl true
  def handle_info({:core_event, {:ok, {profile_name, nicks}}}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:profile_name, profile_name)
     |> assign(:nicks, nicks)}
  end

  def handle_info({:core_event, {:error, err}}, socket) do
    {:noreply,
     socket
     |> update(:loading, fn _ -> false end)
     |> put_flash(:error, "Ошибка генерации ников")}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def assign_timezone(socket) do
    timezone = get_connect_params(socket)["timezone"] || "Europe/Moscow"

    assign(socket, :timezone, timezone)
  end

  defp apply_action(socket, _action, %{"id" => id}) do
    {profile_name, prev_nicks} =
      case load_nicks_history(id) do
        [] -> {"", []}
        [{_timestamp, profile_name, _data} | _] = res -> {profile_name, res}
      end

    socket
    |> assign(:nicks, [])
    |> assign(:prev_nicks, prev_nicks)
    |> assign(:profile_name, profile_name)
    |> assign(:dotabuff_url, "https://www.dotabuff.com/players/#{id}")
  end

  defp apply_action(socket, _action, _params) do
    socket
  end

  def load_nicks_history(id) do
    case Dotanicks.NicksHistory.get(id) do
      [{^id, list}] -> list
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

  def put_logger_metadata(%{"x-request-id" => request_id}) do
    Logger.metadata(request_id: request_id)
  end

  def put_logger_metadata(_) do
  end
end
