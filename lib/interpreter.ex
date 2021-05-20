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

  @doc """
  Eval-the one, true, mighty, meta-circular evaluator!

  This is the primary evaluation routine for our interpreter.
  """
  @spec eval(expr :: ast(), env :: Env.t()) :: Values.denotable_value()

  # Self-evaluating values
  def eval(b, _) when is_boolean(b), do: b
  def eval(n, _) when is_number(n), do: n
  def eval(s, _) when is_binary(s), do: s

  # variable lookup
  def eval(a, env) when is_atom(a), do: Env.lookup(a, env)

  # Binary math operators
  def eval({op, arg1, arg2}, env) when op in @binary_operations do
    left = eval(arg1, env)
    right = eval(arg2, env)

    case op do
      :+ -> left + right
      :- -> left - right
      :/ -> left / right
      :* -> left * right
      := -> left == right
    end
  end

  # Unary operators
  def eval({op, arg}, env) when op in @unary_operations do
    arg_e = eval(arg, env)

    not arg_e
  end

  # Conditionals
  def eval({:if, c, t_case, f_case}, env) do
    if eval(c, env) do
      eval(t_case, env)
    else
      eval(f_case, env)
    end
  end

  # Closures
  def eval({:lambda, params, body}, env) do
    %Closure{params: params, body: body, env: env}
  end

  def eval({:app, func, args}, env) do
    # Note how we first evaluate the function: in a well-typed
    # program, the first argument to an appliation is either a
    # litteral lambda, or it is a variable that is bound to a closure.
    # In either case, evaluating it gives us a new closure that we can
    # call.

    with %Closure{params: xs, body: body, env: cenv} <- eval(func, env),
         # Now with the function reference safely evaluated, we can
         # evaluate the arguments
         evaled_args <- Enum.map(args, fn a -> eval(a, env) end) do
      # Now bind the arguments to the parameters of the closure
      new_pad = Enum.zip(xs, evaled_args) |> Enum.into(%{})
      new_env = Env.extend(cenv, new_pad)

      eval(body, new_env)
    end
  end

  def eval({op, _, _}, _), do: raise("Unknown binary operator: #{op}")
  def eval({op, _}, _), do: raise("Unknown unary operator: #{op}")
end
