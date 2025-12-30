defmodule SanLang.Kernel do
  alias SanLang.Environment
  alias SanLang.Interpreter

  def print(arg, _env) do
    IO.inspect(arg)
    arg
  end

  def pow(base, pow, _env) when is_number(base) and is_number(pow) do
    base ** pow
  end

  def div(dividend, divisor, _env) when is_number(dividend) and is_number(divisor) do
    div(dividend, divisor)
  end

  def length(list, _env) when is_list(list), do: length(list)

  def map_keys(map, _env) when is_map(map) do
    Map.keys(map)
  end

  def flatten(list, _env) when is_list(list) do
    List.flatten(list)
  end

  def map(enumerable, {:closure, _args, _body, _captured} = closure, %Environment{} = env) do
    do_reduce(enumerable, closure, env)
    |> Enum.reverse()
  end

  def filter(enumerable, {:closure, args, body, captured_bindings}, %Environment{} = env) do
    [{:identifier, _, local_binding}] = args

    enumerable
    |> Enum.reduce({[], env}, fn elem, {acc, env} ->
      # Merge captured bindings into environment
      env =
        Enum.reduce(captured_bindings, env, fn {name, value}, acc_env ->
          Environment.add_local_binding(acc_env, name, value)
        end)

      # Add the iteration variable
      env = Environment.add_local_binding(env, local_binding, elem)

      case Interpreter.eval(body, env) do
        falsey when falsey in [false, nil] ->
          {acc, env}

        _ ->
          {[elem | acc], env}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def flat_map(enumerable, {:closure, _args, _body, _captured} = closure, %Environment{} = env) do
    do_reduce(enumerable, closure, env)
    |> flat_reverse([])
  end

  def reduce(enumerable, {:closure, _args, _body, _captured} = closure, %Environment{} = env) do
    do_reduce(enumerable, closure, env)
  end

  # Private functions

  defp flat_reverse([h | t], acc), do: flat_reverse(t, h ++ acc)
  defp flat_reverse([], acc), do: acc

  defp do_reduce(enumerable, {:closure, args, body, captured_bindings}, env) do
    [{:identifier, _, local_binding}] = args

    enumerable
    |> Enum.reduce({[], env}, fn elem, {acc, env} ->
      # Merge captured bindings into environment
      env =
        Enum.reduce(captured_bindings, env, fn {name, value}, acc_env ->
          Environment.add_local_binding(acc_env, name, value)
        end)

      # Add the iteration variable
      env = Environment.add_local_binding(env, local_binding, elem)

      computed_item = Interpreter.eval(body, env)
      {[computed_item | acc], env}
    end)
    |> elem(0)
  end
end
