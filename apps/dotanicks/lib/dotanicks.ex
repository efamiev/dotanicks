defmodule Dotanicks do
  alias Dotanicks.Parser

  require Logger

  @auth_header "Bearer #{Application.compile_env(:dotanicks, :llm_api_key)}"
  @llm_system_content Application.compile_env(:dotanicks, :llm_system_content)

  def generate(id) do
    Task.async(fn -> do_generate(id) end)
  end

  def do_generate(id) do
    with {:ok, body} <- fetch_matches(id),
         {profile_name, matches} when matches != [] <- Parser.parse(body),
         {:ok, nicks} <- fetch_nicks(matches) do
      Dotanicks.NicksHistory.add(id, profile_name, nicks)

      Phoenix.PubSub.broadcast(Dotanicks.PubSub, "nicks:#{id}", {:core_event, {:ok, {profile_name, nicks}}})
    else
      [] ->
        Logger.info("Не найдены мачти для аккаунта #{id}")
        Phoenix.PubSub.broadcast(Dotanicks.PubSub, "nicks:#{id}", {:core_event, {:error, :matches_not_found}})

      {:error, err} ->
        Logger.info("Ошибка генерации ников #{id} #{inspect(err)}")
        Phoenix.PubSub.broadcast(Dotanicks.PubSub, "nicks:#{id}", {:core_event, {:error, err}})
    end
  end

  def fetch_nicks(matches) do
    headers = [
      {"Authorization", @auth_header},
      {"Content-Type", "application/json"}
    ]

    req = Finch.build(:post, "https://openrouter.ai/api/v1/chat/completions", headers, llm_req_body(matches))

    with {:ok, %Finch.Response{status: 200, body: body}} <- Finch.request(req, DotanicksFinch),
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
        {:error, err}

      :error ->
        {:error, :key_not_found}
    end
  end

  def fetch_matches(id) do
    req = Finch.build(:get, "https://www.dotabuff.com/players/#{id}/matches")

    case Finch.request(req, DotanicksFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Finch.Response{}} ->
        {:error, :matches_req_error}

      {:error, err} ->
        {:error, err}
    end
  end

  def llm_req_body(matches) do
    Jason.encode!(%{
      model: "deepseek/deepseek-chat-v3-0324:free",
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
