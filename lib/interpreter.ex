defmodule Interpreter do
  @moduledoc """
  Core interpreter for a little language
  """

  alias Interpreter.Env
  alias Interpreter.Values
  alias Interpreter.Closure

  @typedoc """
  An AST is just an expression

  NOTE: In a *real* interpreter, you would want to carry with you a
  bunch of information in the AST that can help with later parsing.
  For instance, you would want to carry some debugging information
  like line numbers.
  """
  @type ast :: expr

  @typedoc """
  Top-level expression type
  """
  @type expr ::
          boolean()
          | number()
          | String.t()
          | atom()
          | {binop(), expr(), expr()}
          | {unop(), expr()}
          | {:if, expr(), expr(), expr()}
          | {:lambda, params :: [atom()], body :: expr()}
          | {:app, fref :: expr(), args :: [expr()]}
          | {:letrec, [{var :: atom(), binding :: expr()}], body :: expr()}
          | {:let, [{var :: atom(), binding :: expr()}], body :: expr()}
          | {:begin, [expr()]}

  @type binop :: :+ | :- | :* | :/ | :=
  @binary_operations ~w(+ - * / =)a

  @type unop :: :not
  @unary_operations ~w(not)a

  @typedoc """
  We handle errors explicitly in our interpreter. This means
  computation can return either a value or an error.
  """
  @type maybe_value :: {:ok, Values.denotable_value()} | {:error, String.t()}

  @doc """
  Eval-the one, true, mighty, meta-circular evaluator!

  This is the primary evaluation routine for our interpreter.
  """
  @spec eval(expr :: ast(), env :: Env.t()) :: maybe_value()

  # Self-evaluating values
  def eval(b, _) when is_boolean(b), do: {:ok, b}
  def eval(n, _) when is_number(n), do: {:ok, n}
  def eval(s, _) when is_binary(s), do: {:ok, s}

  # variable lookup
  def eval(a, env) when is_atom(a), do: Env.lookup(a, env)

  # Binary math operators
  def eval({op, arg1, arg2}, env) when op in @binary_operations do
    with {:ok, left} <- eval(arg1, env),
         {:ok, right} <- eval(arg2, env) do
      case op do
        :+ -> {:ok, left + right}
        :- -> {:ok, left - right}
        :/ -> if right != 0, do: {:ok, left / right}, else: {:error, "Division by zero!"}
        :* -> {:ok, left * right}
        := -> {:ok, left == right}
      end
    end
  end

  # Unary operators
  def eval({op, arg}, env) when op in @unary_operations do
    with {:ok, v} <- eval(arg, env), do: {:ok, not v}
  end

  # Conditionals
  def eval({:if, c, t_case, f_case}, env) do
    with {:ok, c?} <- eval(c, env) do
      # Note how we just fall back to how Elixir treats values as
      # truthy/falsy. We could easily define our own semantics here
      # for what can be passed to an `if`
      if c? do
        eval(t_case, env)
      else
        eval(f_case, env)
      end
    end
  end

  # Closures
  def eval({:lambda, params, body}, env) do
    {:ok, %Closure{params: params, body: body, env: env}}
  end

  def eval({:app, func, args}, env) do
    # Note how we first evaluate the function: in a well-typed
    # program, the first argument to an appliation is either a
    # litteral lambda, or it is a variable that is bound to a closure.
    # In either case, evaluating it gives us a new closure that we can
    # call.

    with {:ok, %Closure{params: xs, body: body, env: cenv}} <- eval(func, env),
         # Now with the function reference safely evaluated, we can
         # evaluate the arguments
         {:ok, evaled_args} <- eval_args(args, env) do
      # Now bind the arguments to the parameters of the closure
      new_pad = Enum.zip(xs, evaled_args) |> Enum.into(%{})
      new_env = Env.extend(cenv, new_pad)

      eval(body, new_env)
    end
  end

  def eval({:letrec, [bindings], body}, env) do
  end

  def eval({op, _, _}, _), do: {:error, "Unknown binary operator: #{op}"}
  def eval({op, _}, _), do: {:error, "Unknown unary operator: #{op}"}

  @doc """
  Evaluate a list of expressions

  Used when evaluating the arguments to a function. If any one of the
  arguments fails, the whole function will return `{:error, "error
  message"}`. If it succeeds, it returns `{:ok, [1, 2, 3]}`, where the
  list of values are *not* maybe tuples.
  """
  @spec eval_args([expr()], env :: Env.t()) ::
          {:ok, [Values.denotable_value()]} | {:error, String.t()}
  def eval_args([], _env), do: {:ok, []}

  def eval_args([x | rest], env) do
    with {:ok, v} <- eval(x, env),
         {:ok, vs} <- eval_args(rest, env) do
      {:ok, [v | vs]}
    end
  end
end
