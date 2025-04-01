defmodule DotabuffMock do
  def save_page(id, file_path \\ "./apps/dotanicks/test/support/mocks/dotabuff.html") do
    case Dotanicks.fetch_matches(id) do
      {:ok, body} ->
        File.write(file_path, body)

      err ->
        raise "Cannot fetch matches #{inspect(err)}"
    end
  end
end
