defmodule AdbcLeakDemoTest do
  use ExUnit.Case
  doctest AdbcLeakDemo

  test "greets the world" do
    assert AdbcLeakDemo.hello() == :world
  end
end
