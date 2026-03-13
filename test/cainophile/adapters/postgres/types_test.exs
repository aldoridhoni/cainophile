defmodule Cainophile.Adapters.Postgres.TypesTest do
  use ExUnit.Case
  alias Cainophile.Adapters.Postgres.Types
  alias PgoutputDecoder.Messages.Relation.Column

  describe "cast/2" do
    test "handles simple types" do
      assert {"id", 123} == Types.cast(%Column{name: "id", type: "int4"}, "123")
      assert {"active", true} == Types.cast(%Column{name: "active", type: "bool"}, "t")
      assert {"active", false} == Types.cast(%Column{name: "active", type: "bool"}, "f")
    end

    test "handles array of integers" do
      column = %Column{name: "ids", type: {:array, "int4"}}
      assert {"ids", [1, 2, 3]} == Types.cast(column, "{1,2,3}")
    end

    test "handles array of strings with quotes and commas" do
      column = %Column{name: "tags", type: {:array, "text"}}
      assert {"tags", ["a,b", "c"]} == Types.cast(column, "{\"a,b\",c}")
    end

    test "handles array with NULLs" do
      column = %Column{name: "vals", type: {:array, "int4"}}
      assert {"vals", [1, nil, 3]} == Types.cast(column, "{1,NULL,3}")
    end

    test "handles empty array" do
      column = %Column{name: "vals", type: {:array, "int4"}}
      assert {"vals", []} == Types.cast(column, "{}")
    end

    test "handles array of booleans" do
      column = %Column{name: "flags", type: {:array, "bool"}}
      assert {"flags", [true, false]} == Types.cast(column, "{t,f}")
    end

    test "handles escaped quotes in strings" do
      column = %Column{name: "titles", type: {:array, "text"}}
      assert {"titles", ["a\"b", "c"]} == Types.cast(column, "{\"a\\\"b\",c}")
    end
  end
end
