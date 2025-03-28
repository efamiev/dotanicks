defmodule Dotanicks.FinchLogger do
  @moduledoc """
  Подписывается на Telemetry-события Finch и логирует
  информацию о завершённых запросах (URL, статус, часть тела).
  """

  require Logger

  # Подключение к Telemetry
  def attach() do
    :telemetry.attach(
      "finch-logger-start",
      [:finch, :request, :start],
      &__MODULE__.handle_event/4,
      %{}
    )

    :telemetry.attach(
      "finch-logger",
      [:finch, :request, :stop],
      &__MODULE__.handle_event/4,
      %{}
    )
  end

  # Колбэк, который вызывается при начале запроса
  def handle_event([:finch, :request, :start], _measurements, meta, _config) do
    # Извлекаем данные о запросе
    # %Finch.Request{}
    finch_request = meta[:request]
    scheme = finch_request.scheme
    host = finch_request.host
    path = finch_request.path
    # Если во время инициации запроса положили в finch_request.private[:request_id],
    # то вытащим его, иначе используем placeholder
    request_id = Map.get(finch_request.private, :request_id, "-")

    body =
      with body when not is_nil(body) <- Map.get(finch_request, :body),
           {:ok, json_body} <- Jason.decode(body) do
        json_body
      else
        _ -> nil
      end

    Logger.info(
      """
      Finch request start:
        Request ID: #{request_id}
        Method: #{finch_request.method}
        URL: #{scheme}://#{host}#{path}
        Body: #{inspect(body)}
      """,
      # Прокидываем request_id как метаданные, если нужно в консольном логере
      request_id: request_id
    )
  end

  # Основной колбэк, который вызывается при завершении запроса
  def handle_event([:finch, :request, :stop], measurements, meta, _config) do
    # Извлекаем данные о запросе
    # %Finch.Request{}
    finch_request = meta[:request]
    scheme = finch_request.scheme
    host = finch_request.host
    path = finch_request.path
    # Если во время инициации запроса положили в finch_request.private[:request_id],
    # то вытащим его, иначе используем placeholder
    request_id = Map.get(finch_request.private, :request_id, "-")

    # meta[:result] обычно {:ok, %Finch.Response{...}} или {:error, reason}
    result = meta[:result]

    {status_str, body_str} =
      case result do
        {:ok, %Finch.Response{status: code, body: body, headers: headers}} ->
          # Преобразуем тело в человекочитаемый вид (распаковка gzip/deflate и проверка UTF-8)
          readable_body = human_readable_body(body, headers)
          {"#{code}", readable_body}

        {:error, reason} ->
          {"ERROR: #{inspect(reason)}", "<<no-body>>"}
      end

    # measurements хранит метрики (duration, decode_time и т.д.)
    # при желании можно их вытащить, например:
    duration_us = Map.get(measurements, :duration, 0)

    Logger.info(
      """
      Finch request completed:
        Request ID: #{request_id}
        Method: #{finch_request.method}
        URL: #{scheme}://#{host}#{path}
        Status: #{status_str}
        Body (snippet / processed): #{body_str}

        Duration: #{System.convert_time_unit(duration_us, :native, :millisecond)}ms
      """,
      # Прокидываем request_id как метаданные, если нужно в консольном логере
      request_id: request_id
    )
  end

  # Приватная функция для "распаковки" и проверки, является ли тело текстовым.
  defp human_readable_body(body, headers) do
    # 1) Определяем content-encoding
    content_encoding =
      headers
      |> Enum.find(fn {k, _v} -> String.downcase(k) == "content-encoding" end)
      |> case do
        nil -> nil
        {_, v} -> String.downcase(v)
      end

    # 2) Если gzip/deflate, распакуем
    decompressed_body =
      case content_encoding do
        "gzip" ->
          try do
            :zlib.gunzip(body)
          rescue
            _ -> body
          end

        "deflate" ->
          try do
            :zlib.uncompress(body)
          rescue
            _ -> body
          end

        _ ->
          body
      end

    if String.valid?(decompressed_body) do
      # Попробуем распарсить JSON
      case Jason.decode(decompressed_body) do
        {:ok, json_data} ->
          content =
            json_data
            |> Map.get("choices", [%{}])
            |> case do
              [first_choice | _] ->
                first_choice
                |> Map.get("message", %{"content" => "no content key"})

              _ ->
                "no choices array"
            end

          # Можно вывести content целиком или обрезать
          "Extracted content: " <> inspect(content)

        # "Extracted content: " <> "id: " <> Map.get(json_data, "id") <> " " <> inspect(content)

        {:error, _reason} ->
          # Если не JSON, просто возвращаем небольшой фрагмент
          snippet = String.slice(decompressed_body, 0, 200)
          "Non-JSON text snippet: #{snippet}"
      end
    else
      # Бинарные данные (не UTF-8)
      "<<non-UTF8 or binary data, size=#{byte_size(decompressed_body)} bytes>>"
    end
  end
end
