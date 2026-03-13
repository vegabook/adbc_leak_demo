# colorscheme guepardo light
defmodule AdbcLeakDemo do
  @moduledoc """
  ADBC NIF memory leak reproducer.
  Compares ADBC DuckDB/SQLite drivers against duckdbex as a control.

      mix run -e "AdbcLeakDemo.run(:adbc_duckdb)"
      mix run -e "AdbcLeakDemo.run(:adbc_sqlite)"
      mix run -e "AdbcLeakDemo.run(:duckdbex)"
      mix run -e "AdbcLeakDemo.run(:exqlite)"
      mix run -e "AdbcLeakDemo.run_all()"
  """

  @backends [:adbc_duckdb, :adbc_sqlite, :duckdbex, :exqlite]
  @iterations 5_000
  @rows_per_insert 100
  @log_every 500

  def run_all(iterations \\ @iterations) do
    results = for backend <- @backends do
      {backend, run(backend, iterations)}
    end

    csv_dir = Path.join([File.cwd!(), "priv", "results"])
    File.mkdir_p!(csv_dir)
    csv_path = Path.join(csv_dir, "leak_comparison.csv")

    header = "iter," <> Enum.map_join(@backends, ",", &"delta_mb_#{&1}")
    iters = results |> hd() |> elem(1) |> Enum.map(&elem(&1, 0))
    deltas_by_backend = Map.new(results, fn {b, data} -> {b, Map.new(data)} end)

    rows = Enum.map(iters, fn iter ->
      "#{iter}," <> Enum.map_join(@backends, ",", fn b ->
        :io_lib.format("~.1f", [deltas_by_backend[b][iter]]) |> to_string()
      end)
    end)

    File.write!(csv_path, [header, "\n", Enum.join(rows, "\n"), "\n"])
    IO.puts("\nCSV written to #{csv_path}")
  end

  def run(backend \\ :adbc_duckdb, iterations \\ @iterations) do
    db_path = fresh_db_path(backend)
    {query_fn, label} = setup(backend, db_path)

    syms = ~w(AAPL GOOG MSFT TSLA AMZN META NVDA)

    initial_rss = resident_set_mb()
    IO.puts("#{label} — #{@rows_per_insert} rows/insert, #{iterations} iterations")
    IO.puts(" iter | beam_mb | resident_set_mb | delta_mb")
    IO.puts("------|---------|-----------------|----------")
    log(0, initial_rss)

    deltas = for i <- 1..iterations do
      sql = "INSERT INTO leak_test VALUES " <>
        Enum.map_join(1..@rows_per_insert, ", ", fn j ->
          sym = Enum.random(syms)
          ts = i * @rows_per_insert + j
          v = :rand.uniform() * 1000
          "('#{sym}', #{ts}, #{v})"
        end)
      query_fn.(sql)
      if rem(i, @log_every) == 0 do
        delta = log(i, initial_rss)
        {i, delta}
      end
    end

    IO.puts("\ndone.")
    Enum.reject(deltas, &is_nil/1)
  end

  defp setup(:adbc_duckdb, path) do
    {:ok, db} = Adbc.Database.start_link(driver: :duckdb, path: path)
    {:ok, conn} = Adbc.Connection.start_link(database: db)
    Adbc.Connection.query!(conn, "CREATE TABLE leak_test (sym VARCHAR, ts BIGINT, v DOUBLE)")
    {&Adbc.Connection.query!(conn, &1), "adbc :duckdb"}
  end

  defp setup(:adbc_sqlite, path) do
    {:ok, db} = Adbc.Database.start_link(driver: :sqlite, uri: path)
    {:ok, conn} = Adbc.Connection.start_link(database: db)
    Adbc.Connection.query!(conn, "CREATE TABLE leak_test (sym VARCHAR, ts BIGINT, v DOUBLE)")
    {&Adbc.Connection.query!(conn, &1), "adbc :sqlite"}
  end

  defp setup(:duckdbex, path) do
    {:ok, db} = Duckdbex.open(path)
    {:ok, conn} = Duckdbex.connection(db)
    {:ok, _} = Duckdbex.query(conn, "CREATE TABLE leak_test (sym VARCHAR, ts BIGINT, v DOUBLE)")
    {fn sql -> {:ok, _} = Duckdbex.query(conn, sql) end, "duckdbex"}
  end

  defp setup(:exqlite, path) do
    {:ok, conn} = Exqlite.Sqlite3.open(path)
    :ok = Exqlite.Sqlite3.execute(conn, "CREATE TABLE leak_test (sym VARCHAR, ts BIGINT, v DOUBLE)")
    {fn sql -> :ok = Exqlite.Sqlite3.execute(conn, sql) end, "exqlite"}
  end

  defp fresh_db_path(backend) do
    dir = Path.join([File.cwd!(), "priv", "data"])
    File.mkdir_p!(dir)
    ext = if backend in [:adbc_sqlite, :exqlite], do: ".sqlite", else: ".duckdb"
    path = Path.join(dir, "leak_test_#{backend}#{ext}")
    File.rm(path)
    path
  end

  defp log(iter, initial_rss) do
    beam = :erlang.memory(:total) / 1_048_576
    rss = resident_set_mb()
    delta = rss - initial_rss
    IO.puts("#{String.pad_leading("#{iter}", 5)} | #{f(beam)} | #{f15(rss)} | #{f(delta)}")
    delta
  end

  defp resident_set_mb do
    {out, 0} = System.cmd("ps", ["-o", "rss=", "-p", "#{System.pid()}"])
    String.trim(out) |> String.to_integer() |> Kernel./(1024)
  end

  defp f(val), do: :io_lib.format("~7.1f", [val]) |> to_string()
  defp f15(val), do: :io_lib.format("~15.1f", [val]) |> to_string()
end
