defmodule DotanicksTest do
  use ExUnit.Case

  test "prepare matches data" do
    raw_matches = [
      %{
        "assists" => 10,
        "average_rank" => 75,
        "deaths" => 6,
        "duration" => 3010,
        "game_mode" => 2,
        "hero_id" => 138,
        "hero_variant" => 3,
        "kills" => 14,
        "leaver_status" => 0,
        "lobby_type" => 1,
        "match_id" => 8_424_907_831,
        "party_size" => 10,
        "player_slot" => 0,
        "radiant_win" => true,
        "start_time" => 1_755_682_165,
        "version" => 22
      },
      %{
        "assists" => 16,
        "average_rank" => 75,
        "deaths" => 3,
        "duration" => 3127,
        "game_mode" => 2,
        "hero_id" => 94,
        "hero_variant" => 3,
        "kills" => 11,
        "leaver_status" => 0,
        "lobby_type" => 1,
        "match_id" => 8_424_834_343,
        "party_size" => 10,
        "player_slot" => 128,
        "radiant_win" => false,
        "start_time" => 1_755_677_175,
        "version" => 22
      },
      %{
        "assists" => 6,
        "average_rank" => 75,
        "deaths" => 4,
        "duration" => 2836,
        "game_mode" => 2,
        "hero_id" => 18,
        "hero_variant" => 2,
        "kills" => 25,
        "leaver_status" => 0,
        "lobby_type" => 1,
        "match_id" => 8_423_633_777,
        "party_size" => 10,
        "player_slot" => 128,
        "radiant_win" => false,
        "start_time" => 1_755_601_218,
        "version" => 22
      }
    ]

    assert Dotanicks.prepare_matches(raw_matches) == [
        %{
          "kills" => 14,
          "deaths" => 6,
          "assists" => 10,
          "win" => true,
          "duration" => 3010,
          "hero_name" => "Muerta",
          "hero_legs" => 2,
          "hero_attack_type" => "Ranged",
          "hero_primary_attr" => "int"
        },
        %{
          "kills" => 11,
          "deaths" => 3,
          "assists" => 16,
          "win" => true,
          "duration" => 3127,
          "hero_name" => "Medusa",
          "hero_legs" => 0,
          "hero_attack_type" => "Ranged",
          "hero_primary_attr" => "agi"
        },
        %{
          "kills" => 25,
          "deaths" => 4,
          "assists" => 6,
          "win" => true,
          "duration" => 2836,
          "hero_name" => "Sven",
          "hero_legs" => 2,
          "hero_attack_type" => "Melee",
          "hero_primary_attr" => "str"
        },
      ]
  end
end
