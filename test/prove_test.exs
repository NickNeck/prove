defmodule ProveTest do
  use ExUnit.Case

  import Prove

  defmodule Num do
    def check(0), do: :zero
    def check(neg) when neg < 0, do: :neg

    def check(num) when is_integer(num) do
      case rem(num, 2) do
        0 -> :even
        1 -> :odd
      end
    end

    def check(_), do: :error
  end

  defp identity(x), do: x

  describe "check/1:" do
    prove Num.check(-1) == :neg
    prove Num.check(0) == :zero
    prove Num.check(1) == :odd
    prove Num.check(2) == :even
    prove "big-num:", Num.check(999_999_999) == :odd
  end

  describe "prove with different operators" do
    prove identity(5) == 5
    prove identity(5) != 1
    prove identity(5) === 5
    prove identity(5) !== 1
    prove identity(5) > 1
    prove identity(5) >= 5
    prove identity(5) < 10
    prove identity(5) <= 5
    prove "abcd" =~ "bc"
  end

  describe "batch/2" do
    batch "all together now" do
      prove identity(5) > 1
      prove identity(5) > 2
      prove identity(5) > 3
      prove "can I have a little more?", identity(5) > 4
    end

    batch "one" do
      prove identity(5) > 1
    end
  end

  test "context" do
    assert __MODULE__.__info__(:functions) == [
             __ex_unit__: 0,
             __ex_unit__: 2,
             "test batch/2 all together now can I have a little more? identity(5) > 4": 1,
             "test batch/2 all together now identity(5) > 1": 1,
             "test batch/2 all together now identity(5) > 2": 1,
             "test batch/2 all together now identity(5) > 3": 1,
             "test batch/2 one identity(5) > 1": 1,
             "test check/1: Num.check(-1) == :neg": 1,
             "test check/1: Num.check(0) == :zero": 1,
             "test check/1: Num.check(1) == :odd": 1,
             "test check/1: Num.check(2) == :even": 1,
             "test check/1: big-num: Num.check(999999999) == :odd": 1,
             "test context": 1,
             "test prove with different operators "abcd" =~ "bc"": 1,
             "test prove with different operators identity(5) != 1": 1,
             "test prove with different operators identity(5) !== 1": 1,
             "test prove with different operators identity(5) < 10": 1,
             "test prove with different operators identity(5) <= 5": 1,
             "test prove with different operators identity(5) == 5": 1,
             "test prove with different operators identity(5) === 5": 1,
             "test prove with different operators identity(5) > 1": 1,
             "test prove with different operators identity(5) >= 5": 1
           ]
  end
end
