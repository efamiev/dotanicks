defmodule Dotanicks.Storage.NicksHistory do
  use GenServer

  @table :nicks_history
  @dets_file Application.get_env(:dotanicks, :nicks_history_file)

  ## --- API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_file do
    @dets_file
  end

  def get_table do
    @table
  end

  def add(profile_id, profile_name, data) do
    timestamp = System.system_time(:second)
    GenServer.call(__MODULE__, {:add, profile_id, {timestamp, profile_name, data}})
  end

  def get(profile_id) do
    GenServer.call(__MODULE__, {:get, profile_id})
  end

  ## --- GenServer callbacks ---

  @impl true
  def init(_) do
    table = @table

    case :dets.open_file(@table, file: @dets_file) do
      {:ok, ^table} -> {:ok, nil}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:add, key, new_item}, _from, state) do
    case :dets.lookup(@table, key) do
      [{^key, list}] ->
        updated_list = [new_item | list]
        :dets.insert(@table, {key, updated_list})

      [] ->
        :dets.insert(@table, {key, [new_item]})
    end

    {:reply, :ok, state}
  end

  def handle_call({:get, profile_id}, _from, state) do
    result = :dets.lookup(@table, profile_id)

    {:reply, result, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :dets.close(@table)
    :ok
  end
end
