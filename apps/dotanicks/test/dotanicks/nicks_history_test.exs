defmodule Dotanicks.NicksHistoryTest do
  use ExUnit.Case

  alias Dotanicks.NicksHistory

  test "adds data to the first element of the list" do
    table = NicksHistory.get_table()

    id = "311360822"

    data1 = [
      %{
        "description" =>
          "Ты так легко раздаешь электрические шутки (и разряды) на Razor, что противники просто раки перед тобой.",
        "name" => "Электрорак"
      },
      %{
        "description" =>
          "Ты буквально морфишься между жизнью и смертью, но чаще выбираешь первое, особенно с такими статистиками.",
        "name" => "Морфляшка-госпожа"
      },
      %{
        "description" => "Ну, Slark — это твой выбор, но иногда выглядит так, будто ты не рыба, а дохлый сазан.",
        "name" => "Дохлый сларк"
      }
    ]

    data2 = [
      %{
        "description" => "7 убийств и 15 ассистов? Блин, ты не Kez, ты какой-то сумасшедший рассадник ассистов!",
        "name" => "Кез-пулемёт"
      },
      %{
        "description" => "Muerta с 6/8/6... Похоже, ты мертва не только в игре, но и в статистике, дружище.",
        "name" => "Мертвяк на райде"
      },
      %{
        "description" =>
          "16/2/19 — ну и как Silencer ты либо молча все убиваешь, либо так орёшь, что все вокруг тебя поддерживают.",
        "name" => "Silencer, но орущий"
      }
    ]

    assert :ok == NicksHistory.add(id, data1)
    assert [{^id, [{_, ^data1}]}] = :dets.lookup(table, "311360822")

    assert :ok == NicksHistory.add(id, data2)
    assert [{^id, [{_, ^data2}, {_, ^data1}]}] = :dets.lookup(table, "311360822")

    :dets.delete_all_objects(table)
  end

  test "gets all data" do
    table = NicksHistory.get_table()

    id = "123051238"

    data1 = [
      %{
        "description" =>
          "Ты так легко раздаешь электрические шутки (и разряды) на Razor, что противники просто раки перед тобой.",
        "name" => "Электрорак"
      },
      %{
        "description" =>
          "Ты буквально морфишься между жизнью и смертью, но чаще выбираешь первое, особенно с такими статистиками.",
        "name" => "Морфляшка-госпожа"
      },
      %{
        "description" => "Ну, Slark — это твой выбор, но иногда выглядит так, будто ты не рыба, а дохлый сазан.",
        "name" => "Дохлый сларк"
      }
    ]

    data2 = [
      %{
        "description" => "7 убийств и 15 ассистов? Блин, ты не Kez, ты какой-то сумасшедший рассадник ассистов!",
        "name" => "Кез-пулемёт"
      },
      %{
        "description" => "Muerta с 6/8/6... Похоже, ты мертва не только в игре, но и в статистике, дружище.",
        "name" => "Мертвяк на райде"
      },
      %{
        "description" =>
          "16/2/19 — ну и как Silencer ты либо молча все убиваешь, либо так орёшь, что все вокруг тебя поддерживают.",
        "name" => "Silencer, но орущий"
      }
    ]

    assert :ok == NicksHistory.add(id, data1)
    assert :ok == NicksHistory.add(id, data2)

    assert [{^id, [{_, ^data2}, {_, ^data1}]}] = NicksHistory.get(id)

    :dets.delete_all_objects(table)
  end
end
