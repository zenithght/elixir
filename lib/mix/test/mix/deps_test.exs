Code.require_file "../../test_helper.exs", __FILE__

defmodule Mix.DepsTest do
  use MixTest.Case

  defmodule DepsApp do
    def project do
      [
        deps: [
          { :ok, "0.1.0",         github: "elixir-lang/ok" },
          { :invalidvsn, "0.2.0", raw: "deps/invalidvsn" },
          { :invalidapp, "0.1.0", raw: "deps/invalidapp" },
          { :noappfile, "0.1.0",  raw: "deps/noappfile" },
          { :uncloned,            git: "https://github.com/elixir-lang/uncloned.git" }
        ]
      ]
    end
  end

  test "extracts all dependencies from the given project" do
    Mix.Project.push DepsApp

    in_fixture "deps_status", fn ->
      deps = Mix.Deps.all
      assert Enum.find deps, match?(Mix.Dep[app: :ok, status: { :ok, _ }], &1)
      assert Enum.find deps, match?(Mix.Dep[app: :invalidapp, status: { :invalidapp, _ }], &1)
    end
  end
end