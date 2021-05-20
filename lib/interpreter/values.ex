defmodule Interpreter.Values do
  @type denotable_value :: number() | boolean() | String.t() | Interpreter.Closure.t()
end
