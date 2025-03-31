defmodule DotanicksWeb.PageController do
  use DotanicksWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def persons(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :persons, page_title: "Dotanicks | никнеймы игроков и стримеров по Dota 2", persons: persons(), layout: false)
  end

  def persons do
    [
      %{
        name: " ALOHADANCE",
        id: 123_051_238,
        nicks: [
        #   %{
        #     name: "Пук-бум",
        #     desctiption:
        #       "Ты жёстко домишь на Паке, особенно в миду, и твои соперники просто взрываются от твоих комбо. Пук-бум — это про твои внезапные убийства."
        #   },
        #   %{
        #     name: "Пук-бум",
        #     desctiption:
        #       "Ты жёстко домишь на Паке, особенно в миду, и твои соперники просто взрываются от твоих комбо. Пук-бум — это про твои внезапные убийства."
        #   }
        ]
      },
      %{
        name: "Topson",
        id: 94_054_712,
        nicks: [
          # %{
          #   name: "Рубик вор",
          #   desctiption:
          #     "Ты не просто играешь за Рубика, ты воруешь ульты и превращаешь их в ад для врагов. Особенно весело, когда ты крадёшь что-то вроде Black Hole и устраиваешь цирк."
          # }
        ]
      }
    ]
  end
end
