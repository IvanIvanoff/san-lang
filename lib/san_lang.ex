<<<<<<< HEAD
defmodule SanLang do
  @moduledoc ~s"""
  SanLang's function is to evaluate simple one-line expressions. These expressions can be used
  in Santiment Queries.

  The following list explains the capabilities of the language
    - Simple arithmetic operations: +, -, *, /
      - 1 + 2 * 3 + 10 => 17
      - 1 / 5 => 0.2
    - Access to environment variables passed via the env parameter. These variables
      are accessed by prefixing their name with '@', like @projects, @owner, etc.
    - Access operator that can be chained:
      - @owner["email"] => test@santiment.net
      - @projects["bitcoin"]["infrastructure"] => BTC
    - Named functions:
      - pow(2, 10) => 1024
      - div(10, 5) => 2
    - Named functions with lambda function as arguments:
      - map([1,2,3], fn x -> x + 10 end) => [11, 12, 13]
      - filter([1,2,3], fn x -> x > 1 end) => [2, 3]
    - Comparisons and boolean expressions: ==, !=, >, <, >=, <=, and, or
      - 1 + 2 * 3 + 10 > 10 => true
  """
  alias SanLang.Environment
  alias SanLang.Interpreter

  @doc ~s"""
  Evaluates the given input string as a SanLang expression and returns the result.

  The `env` parameter is optional and defaults to an empty environment. It can be used to pass
  local bindings (var) or environment variable bindings (@env_var).
  """
  @spec eval(String.t(), Environment.t()) :: {:ok, any()} | {:error, String.t()}
  def eval(input, env \\ Environment.new()) when is_binary(input) do
    with {:ok, ast} <- string_to_ast(input),
         result <- Interpreter.eval(ast, env) do
      {:ok, result}
    else
      error ->
        handle_error(error)
    end
  end

  @doc ~s"""
  Same as eval/2, but raises on error.
  """
  @spec eval(String.t(), Environment.t()) :: any() | no_return
  def eval!(input, env \\ Environment.new()) when is_binary(input) do
    case eval(input, env) do
      {:ok, result} -> result
      {:error, error} -> raise(error)
    end
  end

  def run() do
    do_run(1)
  end

  defp do_run(n) do
    input = IO.gets("#{n}> ") |> String.trim()

    if input != "" do
      case eval(input) do
        {:ok, result} ->
          IO.inspect(result)
          do_run(n + 1)

        {:error, error} ->
          IO.puts([IO.ANSI.red(), error, IO.ANSI.reset()])
          do_run(n + 1)
      end
    else
      do_run(n + 1)
    end
  rescue
    e ->
      IO.puts([IO.ANSI.red(), Exception.message(e), IO.ANSI.reset()])
      do_run(n + 1)
  end

  defp string_to_ast(input) when is_binary(input) do
    input_charlist = String.to_charlist(input)

    with {:ok, tokens, _} <- :san_lang_lexer.string(input_charlist),
         {:ok, ast} <- :san_lang_parser.parse(tokens) do
      {:ok, ast}
    end
  end

  defp handle_error({:error, {location, :san_lang_parser, errors_list}}) do
    {:error,
     """
     Parser error on  #{location(location)}
     Reason: #{to_string(errors_list)}
     """}
  end

  defp handle_error({:error, {location, :san_lang_lexer, error_tuple}, _}) do
    case error_tuple do
      {:illegal, token} ->
        {:error,
         """
         Lexer error on #{location(location)}
         Illegal token '#{to_string(token)}'
         """}

      tuple ->
        {:error,
         """
         Lexer error on #{location(location)}
         Reason: #{inspect(tuple)}
         """}
    end
  end

  defp location({line, column}), do: "line:#{line}, column:#{column}"
  defp location(line), do: "line:#{line}"
end
||||||| (empty tree)
=======
defmodule SanLang do
  @moduledoc ~s"""
  SanLang's function is to evaluate simple one-line expressions. These expressions can be used
  in Santiment Queries.

  The following list explains the capabilities of the language
    - Simple arithmetic operations: +, -, *, /
      - 1 + 2 * 3 + 10 => 17
      - 1 / 5 => 0.2
    - Access to environment variables passed via the env parameter. These variables
      are accessed by prefixing their name with '@', like @projects, @owner, etc.
    - Access operator that can be chained:
      - @owner["email"] => test@santiment.net
      - @projects["bitcoin"]["infrastructure"] => BTC
    - Named functions:
      - pow(2, 10) => 1024
      - div(10, 5) => 2
    - Named functions with lambda function as arguments:
      - map([1,2,3], fn x -> x + 10 end) => [11, 12, 13]
      - filter([1,2,3], fn x -> x > 1 end) => [2, 3]
    - Comparisons and boolean expressions: ==, !=, >, <, >=, <=, and, or
      - 1 + 2 * 3 + 10 > 10 => true
  """
  alias SanLang.Environment
  alias SanLang.Interpreter

  @doc ~s"""
  Evaluates the given input string as a SanLang expression and returns the result.

  The `env` parameter is optional and defaults to an empty environment. It can be used to pass
  local bindings (var) or environment variable bindings (@env_var).
  """
  @spec eval(String.t(), Keyword.t()) :: {:ok, any()} | {:error, String.t()}
  def eval(input, opts \\ []) when is_binary(input) do
    env = Keyword.get(opts, :env, Environment.new())

    with {:ok, ast} <- string_to_ast(input),
         result <- Interpreter.eval(ast, env) do
      case Keyword.get(opts, :dbg, false) do
        true -> {:ok, result}
        false -> {:ok, List.last(result)}
      end
    else
      error ->
        handle_error(error)
    end
  end

  @doc ~s"""
  Same as eval/2, but raises on error.
  """
  @spec eval(String.t(), Keyword.t()) :: any() | no_return
  def eval!(input, opts \\ []) when is_binary(input) do
    case eval(input, opts) do
      {:ok, result} -> result
      {:error, error} -> raise(error)
    end
  end

  def run() do
    do_run(1)
  end

  defp do_run(n) do
    input = IO.gets("#{n}> ") |> String.trim()

    if input != "" do
      case eval(input) do
        {:ok, result} ->
          IO.inspect(result)
          do_run(n + 1)

        {:error, error} ->
          IO.puts([IO.ANSI.red(), error, IO.ANSI.reset()])
          do_run(n + 1)
      end
    else
      do_run(n + 1)
    end
  rescue
    e ->
      IO.puts([IO.ANSI.red(), Exception.message(e), IO.ANSI.reset()])
      do_run(n + 1)
  end

  defp string_to_ast(input) when is_binary(input) do
    input_charlist = String.to_charlist(input)

    with {:ok, tokens, _} <- :san_lang_lexer.string(input_charlist),
         {:ok, ast} <- :san_lang_parser.parse(tokens) do
      {:ok, ast}
    end
  end

  defp handle_error({:error, {location, :san_lang_parser, errors_list}}) do
    {:error,
     """
     Parser error on  #{location(location)}
     Reason: #{to_string(errors_list)}
     """}
  end

  defp handle_error({:error, {location, :san_lang_lexer, error_tuple}, _}) do
    case error_tuple do
      {:illegal, token} ->
        {:error,
         """
         Lexer error on #{location(location)}
         Illegal token '#{to_string(token)}'
         """}

      tuple ->
        {:error,
         """
         Lexer error on #{location(location)}
         Reason: #{inspect(tuple)}
         """}
    end
  end

  defp location({line, column}), do: "line:#{line}, column:#{column}"
  defp location(line), do: "line:#{line}"
end
>>>>>>> 45664f9 (Initial working version of SanLang)
