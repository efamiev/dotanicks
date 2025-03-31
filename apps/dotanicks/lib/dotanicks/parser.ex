defmodule Dotanicks.Parser do
  require Logger

  def parse_mochi(html) do
    {:ok, document} = Floki.parse_document(html)

    document
    |> Floki.find("section tbody tr")
    |> Enum.take(20)
    |> Enum.map(fn el ->
      td = Floki.find(el, "td")

      hero = td |> Enum.at(1) |> Floki.find("a") |> Floki.text()

      role =
        td
        |> Enum.at(2)
        |> parse_icons(0)

      lane =
        td
        |> Enum.at(2)
        |> parse_icons(1)

      result = td |> Enum.at(3) |> Floki.find("a") |> Floki.text()
      duration = td |> Enum.at(5) |> Floki.text()
      kda = td |> Enum.at(6) |> Floki.find(".kda-record") |> Floki.text()

      %{hero: hero, role: role, lane: lane, result: result, duration: duration, kda: kda}
    end)
  end

  def parse_icons(node, position) do
    case Floki.find(node, "i") do
      [] ->
        nil

      icons ->
        icons
        |> Enum.at(position)
        |> Floki.attribute("title")
        |> Floki.text()
    end
  end

  def parse_fast_html(html) do
    {:ok, document} = Floki.parse_document(html, html_parser: Floki.HTMLParser.FastHtml)

    document
    |> Floki.find("section tbody tr")
    |> Enum.take(20)
    |> Enum.map(fn el ->
      td = Floki.find(el, "td")

      hero = td |> Enum.at(1) |> Floki.find("a") |> Floki.text()

      role =
        td
        |> Enum.at(2)
        |> Floki.find("i")
        |> Enum.at(0)
        |> Floki.attribute("title")
        |> Floki.text()

      lane =
        td
        |> Enum.at(2)
        |> Floki.find("i")
        |> Enum.at(1)
        |> Floki.attribute("title")
        |> Floki.text()

      result = td |> Enum.at(3) |> Floki.find("a") |> Floki.text()
      duration = td |> Enum.at(5) |> Floki.text()
      kda = td |> Enum.at(6) |> Floki.find(".kda-record") |> Floki.text()
      # items = td |> Enum.at(1) |> Floki.find("a") |> Floki.text

      %{hero: hero, role: role, lane: lane, result: result, duration: duration, kda: kda}
    end)
  end
end
