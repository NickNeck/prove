defmodule NumTest do
  use ExUnit.Case

  import Prove

  defmodule Num do
    def check(0), do: :zero

    def check(x) when is_integer(x) do
      case rem(x, 2) do
        0 -> :even
        1 -> :odd
      end
    end

    def check(_), do: :error
  end

  describe "check/1" do
    prove Num.check(0) == :zero

    batch "returns :odd or :even" do
      prove Num.check(1) == :odd
      prove Num.check(2) == :even
      prove "for big num", Num.check(2_000) == :even
    end

    batch "returns :error" do
      prove Num.check("1") == :error
      prove Num.check(nil) == :error
    end
  end

  # The example above with regular `test`s:
  # describe "check/1" do
  #   test "returns :zero" do
  #     assert Num.check(0) == :zero
  #   end

  #   test "returns :odd or :even" do
  #     assert Num.check(1) == :odd
  #     assert Num.check(2) == :even
  #     assert Num.check(2_000) == :even
  #   end

  #   test "returns :error" do
  #     assert Num.check("1") == :error
  #     assert Num.check(nil) == :error
  #   end
  # end
end
