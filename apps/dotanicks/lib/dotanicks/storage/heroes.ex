defmodule Dotanicks.Storage.Heroes do
  @moduledoc """
  Хранилище героев Dota 2.

  - При старте читает DETS и заполняет ETS.
  - Если DETS пуст → тянет героев из API, пишет в DETS и ETS.
  - Чтение идёт напрямую из ETS.
  """

  use GenServer
  require Logger

  @open_dota_api_key Application.compile_env(:dotanicks, :open_dota_api_key)
  @dets_file Application.get_env(:dotanicks, :heroes_file)

  @table :heroes

  # --- Публичный API ---

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def get(id) when is_integer(id) do
    case :ets.lookup(@table, id) do
      [{^id, hero}] -> {:ok, hero}
      _ -> :not_found
    end
  end

  def all do
    :ets.tab2list(@table) |> Enum.map(fn {_id, hero} -> hero end)
  end

  def refresh!, do: GenServer.call(__MODULE__, :refresh!)

  # --- GenServer ---

  @impl true
  def init(_opts) do
    ensure_ets!()
    table = @table

    case :dets.open_file(@table, file: @dets_file) do
      {:ok, ^table} ->
        count = load_from_dets_to_ets!()

        if count > 0 do
          Logger.info("Loaded #{count} heroes from DETS")
          {:ok, %{}}
        else
          Logger.warning("DETS is empty, fetching from API...")
          fetch_from_api_and_persist!()
          {:ok, %{}}
        end

      {:error, reason} ->
        Logger.error("Failed to open DETS: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:refresh!, _from, state) do
    case fetch_from_api_and_persist!() do
      {:ok, n} -> {:reply, {:ok, n}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def terminate(_reason, _state) do
    :dets.close(@table)
    :ok
  end

  # --- Внутренние функции ---

  def ensure_ets! do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])

      _ ->
        :ok
    end
  end

  def load_from_dets_to_ets! do
    objects = :dets.match_object(@table, {:"$1", :"$2"})
    :ets.delete_all_objects(@table)
    Enum.each(objects, fn {id, hero} -> :ets.insert(@table, {id, hero}) end)
    length(objects)
  end

  def fetch_from_api_and_persist! do
    req = Finch.build(:get, "https://api.opendota.com/api/heroes?" <> @open_dota_api_key)

    with {:ok, %Finch.Response{status: 200, body: body}} <- Finch.request(req, DotanicksFinch),
         {:ok, heroes} <- Jason.decode(body) do
      :ets.delete_all_objects(@table)
      :dets.delete_all_objects(@table)

      Enum.each(heroes, fn hero ->
        id = hero["id"]
        :ets.insert(@table, {id, hero})
        :dets.insert(@table, {id, hero})
      end)

      {:ok, length(heroes)}
    else
      error -> {:error, error}
    end
  end
end
