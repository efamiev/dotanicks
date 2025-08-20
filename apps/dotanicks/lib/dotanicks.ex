defmodule Dotanicks do
  alias Dotanicks.Parser
  alias Dotanicks.Storage.Heroes
  alias Dotanicks.Storage.NicksHistory

  require Logger

  @auth_header "Bearer #{Application.compile_env(:dotanicks, :llm_api_key)}"
  @open_dota_api_key Application.compile_env(:dotanicks, :open_dota_api_key)
  @llm_system_content Application.compile_env(:dotanicks, :llm_system_content)

  def generate(id) do
    Task.async(fn -> do_generate(id) end)
  end

  def do_generate(id) do
    with {:ok, matches} <- fetch_matches(id),
         {:ok, nicks} <- fetch_nicks(matches),
         {:ok, %{"profile" => profile}} <- fetch_profile(id),
         profile_name <- profile_name(profile) do
      NicksHistory.add(id, profile_name, nicks)

      Phoenix.PubSub.broadcast(Dotanicks.PubSub, "nicks:#{id}", {:core_event, {:ok, {profile_name, nicks}}})
    else
      {:error, err} ->
        Logger.info("Ошибка генерации ников #{id} #{inspect(err)}")
        Phoenix.PubSub.broadcast(Dotanicks.PubSub, "nicks:#{id}", {:core_event, {:error, err}})

      err ->
        Logger.info("Непредвиденная ошибка генерации ников #{id} #{inspect(err)}")
        Phoenix.PubSub.broadcast(Dotanicks.PubSub, "nicks:#{id}", {:core_event, {:error, :unexpected_error}})
    end
  end

  def fetch_nicks(matches) do
    headers = [
      {"Authorization", @auth_header},
      {"Content-Type", "application/json"}
    ]

    req = Finch.build(:post, "https://openrouter.ai/api/v1/chat/completions", headers, llm_req_body(matches))

    with {:ok, %Finch.Response{status: 200, body: body}} <- Finch.request(req, DotanicksFinch, request_timeout: 150_000),
         {:ok, json_body} <- Jason.decode(body),
         {:ok, choices} <- Map.fetch(json_body, "choices"),
         {:ok, choice} <- Enum.fetch(choices, 0),
         {:ok, message} <- Map.fetch(choice, "message"),
         {:ok, content} <- Map.fetch(message, "content"),
         {:ok, json_res} <- extract_json(content),
         {:ok, res} <- Jason.decode(json_res) do
      {:ok, res}
    else
      {:ok, %Finch.Response{} = res} ->
        Logger.info("Ошибка от llm #{inspect(res)}")
        {:error, :llm_req_error}

      {:error, err} ->
        Logger.info("Ошибка получения ников error: #{inspect(err)}")
        {:error, err}

      :error ->
        Logger.info("Ошибка получения ников error: :key_not_found")
        {:error, :key_not_found}
    end
  end

  def fetch_matches(id) do
    params = %{api_key: @open_dota_api_key, limit: 20}
    url = "https://api.opendota.com/api/players/#{id}/matches?" <> URI.encode_query(params)

    req = Finch.build(:get, url)

    case Finch.request(req, DotanicksFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        matches =
          body
          |> Jason.decode!()
          |> prepare_matches()

        {:ok, matches}

      {:ok, %Finch.Response{}} ->
        {:error, :matches_req_error}

      {:error, err} ->
        {:error, err}
    end
  end

  def fetch_profile(id) do
    params = %{api_key: @open_dota_api_key}
    url = "https://api.opendota.com/api/players/#{id}?" <> URI.encode_query(params)

    req = Finch.build(:get, url)

    case Finch.request(req, DotanicksFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        profile =
          body
          |> Jason.decode!()

        {:ok, profile}

      {:ok, %Finch.Response{}} ->
        {:error, :profile_req_error}

      {:error, err} ->
        {:error, err}
    end
  end

  def prepare_matches(matches) do
    Enum.map(matches, fn match ->
      {:ok, hero} = Heroes.get(match["hero_id"])

      match
      |> Map.take(["kills", "deaths", "assists", "duration"])
      |> Map.put("win", win?(match["player_slot"], match["radiant_win"]))
      |> Map.put("hero_name", hero["localized_name"])
      |> Map.put("hero_legs", hero["legs"])
      |> Map.put("hero_attack_type", hero["attack_type"])
      |> Map.put("hero_primary_attr", hero["primary_attr"])
    end)
  end

  def win?(player_slot, radiant_win) when radiant_win and player_slot <= 127, do: true
  def win?(player_slot, radiant_win) when not radiant_win and player_slot > 127, do: true
  def win?(_, _), do: false

  def profile_name(%{"name" => nil, "personaname" => name}), do: name
  def profile_name(%{"name" => name}), do: name

  def llm_req_body(matches) do
    Jason.encode!(%{
      model: "deepseek/deepseek-r1:free",
      messages: [
        %{
          role: "system",
          content: @llm_system_content
        },
        %{
          role: "user",
          content: Jason.encode!(matches)
        }
      ]
    })
  end

  def extract_json(str) do
    # Регулярное выражение ищет содержимое между маркерами ```json и ```
    regex = ~r/```json\s*(.*?)\s*```/s

    case Regex.run(regex, str) do
      [_, json_part] ->
        {:ok, json_part}

      _ ->
        {:error, :json_not_found}
    end
  end
end
