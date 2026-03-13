defmodule AdbcLeakDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :adbc_leak_demo,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:adbc, "~> 0.8"},
      {:duckdbex, "~> 0.3"},
      {:exqlite, "~> 0.23"}
    ]
  end
end
