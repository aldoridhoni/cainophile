defmodule Cainophile.Adapters.Postgres.TypesReproductionTest do
  use ExUnit.Case
  alias Cainophile.Adapters.Postgres.Types
  alias PgoutputDecoder.Messages.Relation.Column

  test "reproduces FunctionClauseError when array is nil" do
    column = %Column{name: "tags", type: {:array, "varchar"}}
    # This should not raise FunctionClauseError
    assert {"tags", nil} == Types.cast(column, nil)
  end
end
