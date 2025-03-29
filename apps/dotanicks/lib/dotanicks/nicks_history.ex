defmodule Dotanicks.NicksHistory do
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

  def add(task_id, data) do
    timestamp = System.system_time(:second)
    # key = {task_id, timestamp}
    GenServer.call(__MODULE__, {:add, task_id, {timestamp, data}})
  end

  def get_all(task_id) do
    GenServer.call(__MODULE__, {:get_all, task_id})
  end

  def get_range(task_id, from_ts, to_ts) do
    GenServer.call(__MODULE__, {:get_range, task_id, from_ts, to_ts})
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
  def handle_call({:add, key, data}, _from, state) do
    :ok = :dets.insert(@table, {key, data})
    {:reply, :ok, state}
  end

  def handle_call({:get_all, task_id}, _from, state) do
    # result =
    # :dets.foldl(fn
    #   {{^task_id, ts}, value}, acc -> [{ts, value} | acc]
    #   _, acc -> acc
    # end, [], @table)
    # |> Enum.sort_by(fn {ts, _} -> ts end)
    result = :dets.lookup(@table, task_id)

    {:reply, result, state}
  end

  def handle_call({:get_range, task_id, from_ts, to_ts}, _from, state) do
    result =
      :dets.foldl(
        fn
          {{^task_id, ts}, value}, acc when ts >= from_ts and ts <= to_ts ->
            [{ts, value} | acc]

          _, acc ->
            acc
        end,
        [],
        @table
      )
      |> Enum.sort_by(fn {ts, _} -> ts end)

    {:reply, result, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :dets.close(@table)
    :ok
  end
end
