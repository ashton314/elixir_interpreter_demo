defmodule ElixirInterpreterDemoTest do
  use ExUnit.Case
  doctest ElixirInterpreterDemo

  test "greets the world" do
    assert ElixirInterpreterDemo.hello() == :world
  end
end
