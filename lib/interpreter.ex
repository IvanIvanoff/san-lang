defmodule SanLang.Interpreter do
  alias SanLang.Environment

  defmodule UnboundError do
    defexception [:message]
  end

  defmodule UndefinedFunctionError do
    defexception [:message]
  end

  def eval({:__block__, exprs}, env) do
    # Blocks get clear local bindings
    env = Environment.clear_local_bindings(env)

    exprs
    |> Enum.reverse()
    |> Enum.reduce({[], env}, fn expr, {result_acc, env_acc} ->
      case eval(expr, env_acc) do
        {value, new_env} -> {[value | result_acc], new_env}
        value -> {[value | result_acc], env_acc}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def eval({:=, {:identifier, _, name}, expr}, env) do
    # Evaluate the expression - this will create a closure for lambda_fn
    value = eval(expr, env)
    env = Environment.add_local_binding(env, name, value)
    {value, env}
  end

  # Terminal values
  def eval({:int, _, value}, _env), do: value
  def eval({:float, _, value}, _env), do: value
  def eval({:ascii_string, _, value}, _env), do: value
  def eval({:env_var, _, _} = env_var, env), do: eval_env_var(env_var, env)
  def eval({:identifier, _, _} = identifier, env), do: eval_identifier(identifier, env)
  def eval({:list, _} = list, env), do: eval_list(list, env)

  # When evaluating a lambda definition, create a closure that captures the current environment
  def eval({:lambda_fn, {:list, args}, body}, env) do
    {:closure, args, body, env.local_bindings}
  end

  # Lambda call on a closure - merge captured environment, bind arguments, evaluate body
  def eval(
        {:lambda_fn_call, {:closure, args_names, body, captured_bindings}, {:list, _} = args_values},
        env
      ) do
    args_values = eval(args_values, env)

    # Start with captured environment (closure bindings)
    env =
      Enum.reduce(captured_bindings, env, fn {name, value}, acc ->
        Environment.add_local_binding(acc, name, value)
      end)

    # Add argument bindings
    env =
      [args_names, args_values]
      |> Enum.zip()
      |> Enum.reduce(env, fn {{:identifier, _, name}, value}, acc_env ->
        Environment.add_local_binding(acc_env, name, value)
      end)

    eval(body, env)
  end

  # Lambda call on raw lambda_fn from parser (e.g. inline lambda calls)
  # First convert to closure, then call
  def eval(
        {:lambda_fn_call, {:lambda_fn, _args, _body} = lambda, args},
        env
      ) do
    closure = eval(lambda, env)
    eval({:lambda_fn_call, closure, args}, env)
  end

  # Lambda call on an identifier - resolve to closure and call
  def eval({:lambda_fn_call, {:identifier, _, name}, args}, env) do
    {:ok, closure} = Environment.get_local_binding(env, name)
    eval({:lambda_fn_call, closure, args}, env)
  end

  # Chained lambda calls - evaluate inner call first to get closure, then call with outer args
  def eval({:lambda_fn_call, {:lambda_fn_call, _, _} = inner_call, args}, env) do
    closure = eval(inner_call, env)
    eval({:lambda_fn_call, closure, args}, env)
  end

  # Function call: identifier(args)
  def eval({:function_call, {:identifier, _, name}, args}, env) do
    eval_parens_call(name, {:list, args}, env)
  end

  def eval({{boolean_op, _}, _, _} = boolean_expr, env) when boolean_op in [:and, :or],
    do: eval_boolean_expr(boolean_expr, env)

  def eval({boolean, _}, _env) when boolean in [true, false], do: boolean

  # Arithemtic
  def eval({:+, l, r}, env), do: eval(l, env) + eval(r, env)
  def eval({:-, l, r}, env), do: eval(l, env) - eval(r, env)
  def eval({:*, l, r}, env), do: eval(l, env) * eval(r, env)
  def eval({:/, l, r}, env), do: eval(l, env) / eval(r, env)

  # Access Operator
  def eval({:access_expr, {:access_expr, _, _} = inner_access_expr, {:ascii_string, _, key}}, env) do
    env_var = eval(inner_access_expr, env)
    Map.get(env_var, key)
  end

  def eval({:access_expr, env_var_or_identifier, key}, env) do
    # The acessed type is an env var or an identifier
    map = eval(env_var_or_identifier, env)
    # The key can be a string, or an identifier if used from inside a map/filter/reduce
    key = eval(key, env)
    Map.get(map, key)
  end

  # Comparison
  def eval({{:comparison_expr, {op, _}}, lhs, rhs}, env) when op in ~w(== != < > <= >=)a,
    do: apply(Kernel, op, [eval(lhs, env), eval(rhs, env)])

  # Call on an identifier
  def eval({:parens_call, {:identifier, _, name}, args}, env) do
    eval_parens_call(name, args, env)
  end

  def eval({:parens_call, expr, args_values}, env) do
    # Evaluate the expression to get a closure
    closure = eval(expr, env)
    # Call the closure with args
    eval({:lambda_fn_call, closure, args_values}, env)
  end

  def eval_list({:list, list_elements}, env) do
    Enum.map(list_elements, fn x -> eval(x, env) end)
  end

  # Boolean expressions
  def eval_boolean_expr({{op, _}, lhs, rhs}, env) when op in [:and, :or] do
    lhs = eval(lhs, env)
    rhs = eval(rhs, env)

    cond do
      not is_boolean(lhs) ->
        raise ArgumentError, message: "Left hand side of #{op} must be a boolean"

      not is_boolean(rhs) ->
        raise ArgumentError, message: "Right hand side of #{op} must be a boolean"

      true ->
        apply(:erlang, op, [lhs, rhs])
    end
  end

  @supported_functions SanLang.Kernel.__info__(:functions)
                       |> Enum.map(fn {name, _arity} -> to_string(name) end)
  # This is a call of a known function name
  defp eval_parens_call(name, {:list, args}, env)
       when is_binary(name) and name in @supported_functions do
    args =
      Enum.map(
        args,
        fn
          # Convert lambda_fn to closure, capturing current environment
          {:lambda_fn, _args, _body} = lambda -> eval(lambda, env)
          # The rest of the arguments can be evaluated before they are passed to the function
          x -> eval(x, env)
        end
      )

    # Each of the functions in the Kernel module takes an environment as the last argument
    args = args ++ [env]
    # We've already checked that the function name exists. Somethimes there are strange
    # errors during tests that :map_keys is not an existing atom, even though there is
    # such a function in the SanLang.Kernel module
    # credo:disable-for-next-line
    apply(SanLang.Kernel, String.to_atom(name), args)
  end

  defp eval_parens_call(name, args, env) when is_binary(name) do
    case Environment.get_local_binding(env, name) do
      {:ok, {:closure, _, _, _} = closure} ->
        # Call the closure with the provided args
        eval({:lambda_fn_call, closure, args}, env)

      {:ok, obj} ->
        raise UndefinedFunctionError,
          message: """
          #{name} is not a function or identifier pointing to a function

          Got #{inspect(obj)} instead
          """

      {:error, _error} ->
        raise UndefinedFunctionError,
          message: """
          #{inspect(name)} is undefined.
          """
    end
  end

  defp eval_env_var({:env_var, _, "@" <> key}, env) do
    case Environment.get_env_binding(env, key) do
      {:ok, value} -> value
      {:error, error} -> raise UnboundError, message: error
    end
  end

  defp eval_identifier({:identifier, _, key}, env) do
    case Environment.get_local_binding(env, key) do
      {:ok, value} -> value
      {:error, error} -> raise UnboundError, message: error
    end
  end

end
