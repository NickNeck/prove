defmodule Prove do
  @moduledoc """
  Prove provides the macros `prove` and `batch` to write simple tests in `ExUnit`
  shorter.

  A `prove` is just helpful for elementary tests. Prove generates one test with
  one assert for every `prove`.

  The disadvantage of these macros is that the tests are containing fewer
  descriptions. For this reason and also if a `prove` looks too complicated, a
  regular `test` is to prefer.

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
  $> mix test test/num_test.exs --trace --seed 0

  NumTest [test/num_test.exs]
    * prove check/1 (1) (0.00ms) [L#20]
    * prove check/1 returns :odd or :even (1) (0.00ms) [L#23]
    * prove check/1 returns :odd or :even (2) (0.00ms) [L#24]
    * prove check/1 returns :odd or :even for big num (1) (0.00ms) [L#25]
    * prove check/1 returns :error (1) (0.00ms) [L#29]
    * prove check/1 returns :error (2) (0.00ms) [L#30]


  Finished in 0.08 seconds (0.00s async, 0.08s sync)
  6 proves, 0 failures

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

      test "returns :odd or :even" do
        assert Num.check(1) == :odd
        assert Num.check(2) == :even
        assert Num.check(2_000) == :even
      end

      test "returns :error" do
        assert Num.check("1") == :error
        assert Num.check(nil) == :error
      end
    end
  ...
  ```
  ```shell
  $> mix test test/num_test.exs --trace --seed 0

  NumTest [test/num_test.exs]
    * test check/1 returns :zero (0.00ms) [L#36]
    * test check/1 returns :odd or :even (0.00ms) [L#40]
    * test check/1 returns :error (0.00ms) [L#46]


  Finished in 0.03 seconds (0.00s async, 0.03s sync)
  3 tests, 0 failures

  Randomized with seed 0
  ```

  """

  @operators [:==, :!=, :===, :!==, :<=, :>=, :<, :>, :=~]

  @doc """
  A macro to write simple a simple test shorter.

  Code like:
  ```elxir
  prove identity(5) == 5
  prove identity(6) > 5
  prove "check:", identity(7) == 7
  ```
  is equivalent to:
  ```elixir
  test "(1)" do
    assert identity(5) == 5
  end

  test "(2)" do
    assert identity(6) > 5
  end

  test "check: (1)" do
    assert identity(7) == 7
  end
  ```

  `prove` supports the operators `==`, `!=`, `===`, `!==`, `<`, `<=`, `>`, `>=`,
  and `=~`.
  """
  defmacro prove(description \\ "", expr)

  defmacro prove(description, {operator, _, [_, _]} = expr)
           when is_binary(description) and operator in @operators do
    quote_prove(
      update_description(description, __CALLER__),
      expr,
      __CALLER__
    )
  end

  defmacro prove(_description, expr) do
    raise ArgumentError, message: "Unsupported do: #{Macro.to_string(expr)}"
  end

  @doc """
  Creates a batch of proves.

  A batch adds the `description` to every `prove`. This can be used to
  group`proves`s with a context. Every prove is still an own `test`.

  Code like:
  ```
  batch "valid" do
    prove 1 == 1
    prove "really", 2 == 2
  end
  ```
  is equivalent to:
  ```
  test "valid (1)" do
    assert 1 == 1
  end

  test "valid really (1)" do
    assert 2 == 2
  end
  ```
  """
  defmacro batch(description, do: {:__block__, _meta, block}) do
    {:__block__, [], quote_block(description, block, __CALLER__)}
  end

  defmacro batch(description, do: block) when is_tuple(block) do
    {:__block__, [], quote_block(description, [block], __CALLER__)}
  end

  defp quote_block(description, block, caller) do
    Enum.map(block, fn
      {:prove, meta, [op]} ->
        quote_block_prove(description, op, meta)

      {:prove, meta, [prove_description, op]} ->
        quote_block_prove("#{description} #{prove_description}", op, meta)

      _error ->
        raise CompileError,
          file: caller.file,
          line: caller.line,
          description: "A batch can only contain prove/1/2 functions"
    end)
  end

  defp quote_block_prove(description, op, meta) do
    {marker, _meta, children} =
      quote do
        prove unquote(description), unquote(op)
      end

    {marker, meta, children}
  end

  defp quote_prove(
         description,
         {operator, _meta, [_, _]} = expr,
         %{module: mod, file: file, line: line}
       )
       when is_binary(description) and operator in @operators do
    assertion = quote_assertion(expr)

    quote bind_quoted: [
            assertion: Macro.escape(assertion),
            description: description,
            file: file,
            line: line,
            mod: mod
          ] do
      name = ExUnit.Case.register_test(mod, file, line, :prove, description, [])

      def unquote(name)(_) do
        unquote(assertion)
      rescue
        error in [ExUnit.AssertionError] -> reraise(error, __STACKTRACE__)
      end
    end
  end

  defp quote_assertion({op, meta, [left, right]} = expr) do
    {marker, _meta, children} =
      quote do
        unless unquote(expr) do
          raise ExUnit.AssertionError,
            expr: unquote(Macro.escape(expr)),
            message: "Prove with #{to_string(unquote(op))} failed",
            left: unquote(left),
            right: unquote(right)
        end
      end

    {marker, meta, children}
  end

  defp update_description(description, caller) do
    case Module.get_attribute(caller.module, :prove_counter) do
      nil ->
        Module.register_attribute(caller.module, :count, persist: false)
        Module.put_attribute(caller.module, :prove_counter, Map.put(%{}, description, 1))
        join(description, 1)

      %{^description => value} = map ->
        inc = value + 1
        Module.put_attribute(caller.module, :prove_counter, Map.put(map, description, inc))
        join(description, inc)

      map ->
        Module.put_attribute(caller.module, :prove_counter, Map.put(map, description, 1))
        join(description, 1)
    end
  end

  defp join("", b), do: "(#{b})"
  defp join(a, b), do: "#{a} (#{b})"
end
