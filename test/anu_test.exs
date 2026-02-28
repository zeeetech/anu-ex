defmodule AnuTest do
  use ExUnit.Case
  doctest Anu

  test "greets the world" do
    assert Anu.hello() == :world
  end
end
