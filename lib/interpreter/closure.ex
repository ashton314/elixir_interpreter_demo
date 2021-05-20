defmodule Interpreter.Closure do
  @moduledoc """
  Our language supports closures

  Closures are just a lambda paired with an environment.
  """
  alias __MODULE__

  defstruct [:params, :body, :env]

  @type t :: %Closure{
          params: [atom()],
          body: Interpreter.expr(),
          env: Interpreter.Env.t()
        }
end
