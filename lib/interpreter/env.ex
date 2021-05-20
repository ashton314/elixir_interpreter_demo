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
end
