defmodule Dotanicks.ParserTest do
  use ExUnit.Case

  alias Dotanicks.Parser

  test "gets matches data from html" do
    html = File.read!(Path.join(File.cwd!(), "/test/support/mocks/dotabuff.html"))

    assert [
             %{
               result: "Lost Match",
               role: "Support Role",
               duration: "46:57",
               hero: "Queen of Pain",
               kda: "8/12/20",
               lane: "Off Lane"
             },
             %{
               result: "Won Match",
               role: "Support Role",
               duration: "37:47",
               hero: "Nature's Prophet",
               kda: "2/10/19",
               lane: "Off Lane"
             },
             %{
               result: "Won Match",
               role: "Support Role",
               duration: "42:54",
               hero: "Jakiro",
               kda: "5/10/25",
               lane: "Off Lane"
             },
             %{
               result: "Lost Match",
               role: "Core Role",
               duration: "34:22",
               hero: "Axe",
               kda: "7/9/7",
               lane: "Off Lane"
             },
             %{
               result: "Won Match",
               role: "Support Role",
               duration: "31:02",
               hero: "Skywrath Mage",
               kda: "4/8/16",
               lane: "Off Lane"
             },
             %{result: "Won Match", role: nil, duration: "46:24", hero: "Silencer", kda: "6/4/19", lane: nil},
             %{
               result: "Won Match",
               role: "Core Role",
               duration: "53:24",
               hero: "Spirit Breaker",
               kda: "7/8/26",
               lane: "Off Lane"
             },
             %{
               result: "Won Match",
               role: "Support Role",
               duration: "30:04",
               hero: "Crystal Maiden",
               kda: "7/4/26",
               lane: "Safe Lane"
             },
             %{result: "Won Match", role: nil, duration: "37:33", hero: "Sniper", kda: "11/0/7", lane: nil},
             %{result: "Won Match", role: nil, duration: "35:47", hero: "Undying", kda: "9/9/18", lane: nil},
             %{result: "Lost Match", role: nil, duration: "53:51", hero: "Enigma", kda: "6/12/20", lane: nil},
             %{result: "Lost Match", role: nil, duration: "42:52", hero: "Puck", kda: "5/9/21", lane: nil},
             %{
               result: "Won Match",
               role: "Core Role",
               duration: "22:29",
               hero: "Mars",
               kda: "2/3/12",
               lane: "Off Lane"
             },
             %{
               result: "Won Match",
               role: "Core Role",
               duration: "35:56",
               hero: "Pudge",
               kda: "6/3/11",
               lane: "Off Lane"
             },
             %{result: "Lost Match", role: nil, duration: "32:54", hero: "Mars", kda: "4/9/11", lane: nil},
             %{
               result: "Lost Match",
               role: "Core Role",
               duration: "41:02",
               hero: "Centaur Warrunner",
               kda: "6/7/20",
               lane: "Off Lane"
             },
             %{result: "Lost Match", role: nil, duration: "31:22", hero: "Axe", kda: "5/13/9", lane: nil},
             %{result: "Won Match", role: nil, duration: "54:48", hero: "Dragon Knight", kda: "7/6/19", lane: nil},
             %{
               result: "Won Match",
               role: nil,
               duration: "36:26",
               hero: "Spirit Breaker",
               kda: "7/3/33",
               lane: nil
             },
             %{result: "Won Match", role: nil, duration: "41:36", hero: "Bristleback", kda: "18/9/21", lane: nil}
           ] == Parser.parse_mochi(html)
  end
end
