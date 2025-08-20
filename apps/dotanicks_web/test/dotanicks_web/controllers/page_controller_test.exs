defmodule DotanicksWeb.PageControllerTest do
  use DotanicksWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~
             "<h1 class=\"text-3xl font-bold text-indigo-200\">Dotanicks — AI генератор ников Dota 2</h1>"
  end
end
