defmodule Interpreter.Env do
  @moduledoc """
  Environment for our interpreter

  Environments are just represented as a map of variable names to
  values, and a parent environment to search if the variable we're
  looking up is not in the current map.
  """

  alias __MODULE__
  alias Interpreter.Values

  @type t :: %Env{
          pad: %{(String.t() | atom()) => Values.denotable_value()},
          parent: t()
        }

  defstruct [:pad, :parent]

  @doc """
  Look up a variable in an environment. Raise an error if not found.
  """
  @spec lookup(var :: atom(), env :: t()) :: Interpreter.maybe_value()
  def lookup(var, nil), do: {:error, "Unbound variable: #{var}"}

  def lookup(var, %Env{pad: pad, parent: parent}) do
    case Map.fetch(pad, var) do
      {:ok, val} ->
        {:ok, val}

      :error ->
        # Not found, try one higher
        lookup(var, parent)
    end
  end

  @doc """
  Extend an environment with a new set of bindings that shadow old ones.
  """
  @spec extend(env :: t(), new_binds :: %{atom() => Values.denotable_value()}) :: t()
  def extend(env, new_binds), do: %Env{pad: new_binds, parent: env}
end
