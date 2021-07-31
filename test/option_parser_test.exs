defmodule OptionParserTest do
  use ExUnit.Case

  import Prove

  describe "next" do
    def config, do: [strict: [str: :string, int: :integer, bool: :boolean]]

    batch "with strict good options" do
      prove OptionParser.next(["--str", "hello", "..."], config()) ==
              {:ok, :str, "hello", ["..."]}

      prove OptionParser.next(["--int=13", "..."], config()) == {:ok, :int, 13, ["..."]}
      prove OptionParser.next(["--bool=false", "..."], config()) == {:ok, :bool, false, ["..."]}
      prove OptionParser.next(["--no-bool", "..."], config()) == {:ok, :bool, false, ["..."]}
      prove OptionParser.next(["--bool", "..."], config()) == {:ok, :bool, true, ["..."]}
      prove OptionParser.next(["..."], config()) == {:error, ["..."]}
    end
  end
end
