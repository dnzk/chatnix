defmodule ChatnixWeb.UserJSON do
  def sign_up(%{user: user}) do
    %{data: %{user: user}}
  end

  def sign_up(%{error: error}) do
    %{data: %{error: error}}
  end
end
