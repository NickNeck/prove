defmodule Prove do
  @moduledoc """
  Prove provides the macros `prove` and `batch` to write simple tests shorter.

  A `prove` is just helpful for elementary tests. Prove generates one test with
  one assert for every `prove`.

  ## Example

  ```elixir
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
  end
  ```
  The example above generates the following tests:
  ```shell
  $> mix test --trace test/num_test.exs --seed 0

  NumTest [test/num_test.exs]
    * test check/1 Num.check(0) == :zero (0.00ms) [L#20]
    * test check/1 returns :odd or :even Num.check(1) == :odd (0.00ms) [L#22]
    * test check/1 returns :odd or :even Num.check(2) == :even (0.00ms) [L#22]
    * test check/1 returns :odd or :even for big num Num.check(2000) == :even (0.00ms) [L#22]
    * test check/1 returns :error Num.check("1") == :error (0.00ms) [L#28]
    * test check/1 returns :error Num.check(nil) == :error (0.00ms) [L#28]


  Finished in 0.05 seconds (0.00s async, 0.05s sync)
  6 tests, 0 failures

  Randomized with seed 0
  ```

  The benefit of `prove` is that tests with multiple asserts can be avoided.
  The example above with regular `test`s:
  ```elixir
  ...
    describe "check/1" do
      test "returns :zero" do
        assert Num.check(0) == :zero
      end

      test "returns :odd od :even" do
        assert Num.check(1) == :odd
        assert Num.check(2) == :even
        assert "for big num", Num.check(2_000) == :even
      end

      test "returns :error" do
        assert Num.check("1") == :error
        assert Num.check(nil) == :error
      end
    end
  ...
  ```
  """

  @operators [:==, :!=, :===, :!==, :<=, :>=, :<, :>, :=~]

  @doc """
  A macro to write simple a simple test shorter.

  Code like:
  ```elxir
  prove identity(5) == 5
  prove "check:", identity(7) == 7
  ```
  is equivalent to:
  ```elixir
  test "identity(5) == 5" do
    assert identity(5) == 5
  end

  test "check: indentity(7) == 7" do
    assert identity(7) == 7
  end
  ```

  `prove` supports the operators `==`, `!=`, `===`, `!==`, `<`, `<=`, `>`, `>=`,
  and `=~`.
  """
  defmacro prove(description \\ "", expr)

  defmacro prove(description, {operator, _, [_, _]} = expr)
           when is_binary(description) and operator in @operators do
    quote_prove(description, expr)
  end

  defmacro prove(_description, expr) do
    raise ArgumentError, message: "Unsupported do: #{Macro.to_string(expr)}"
  end

  @doc """
  Creates a batch of proves.

  The `description` is added to every `prove` in the `batch`.
  """
  defmacro batch(description, do: {:__block__, _meta, block}) do
    {:__block__, [], quote_block(description, block)}
  end

  defmacro batch(description, do: block) when is_tuple(block) do
    {:__block__, [], quote_block(description, [block])}
  end

  defp quote_block(description, block) do
    Enum.reduce(block, {[], []}, fn
      {:prove, _meta, [prove]}, {proves, exprs} ->
        prove = quote_prove(description, prove, Enum.reverse(exprs))
        {[prove | proves], exprs}

      {:prove, _meta, [prove_description, prove]}, {proves, exprs} ->
        prove = quote_prove("#{description} #{prove_description}", prove, Enum.reverse(exprs))
        {[prove | proves], exprs}

      expr, {proves, exprs} ->
        {proves, [expr | exprs]}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp quote_prove(description, {operator, _, [_, _]} = expr, exprs \\ [])
       when is_binary(description) and operator in @operators do
    quote do
      test unquote(name(description, Macro.to_string(expr))) do
        unquote(exprs)
        unquote(quote_assert(expr))
      end
    end
  end

  defp quote_assert({op, meta, [left, right]} = expr) do
    quote do
      assert unquote(expr),
        message: "Prove with #{to_string(unquote(op))} failed",
        left: unquote(left),
        right: unquote(right)
    end
    |> put_meta(meta)
  end

  defp put_meta({marker, _, children}, meta), do: {marker, meta, children}

  defp name("", b), do: b
  defp name(a, b), do: "#{a} #{b}"
end
