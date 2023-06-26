defmodule Chatnix.Guardian do
  @moduledoc """
  Guardian implementation module
  """
  use Guardian, otp_app: :chatnix

  def subject_for_token(%{id: id}, _claims) do
    sub = to_string(id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, "Missing id"}
  end

  def resource_from_claims(%{"sub" => id}) do
    user = Chatnix.Auth.get_user(%{id: id})
    {:ok, user}
  end

  def resource_from_claims(_) do
    {:error, "Invalid token"}
  end
end
