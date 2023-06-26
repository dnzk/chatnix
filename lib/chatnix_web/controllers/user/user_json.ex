defmodule ChatnixWeb.UserJSON do
  def sign_up(%{user: user}) do
    %{data: %{user: user}}
  end

  def sign_up(%{error: error}) do
    %{data: %{error: error}}
  end

  def sign_in(%{access_token: token}) do
    %{data: %{access_token: token}}
  end

  def sign_in(%{error: error}) do
    %{data: %{error: error}}
  end
end
