defmodule Chatnix.TestHelpers.EctoChangeset do
  @moduledoc """
  Test helpers for Ecto.Changeset
  """
  def fetch_error_constraint(%Ecto.Changeset{errors: errors}, error_key, error_constraint) do
    constraint_properties = elem(errors[error_key], 1)
    constraint_properties[error_constraint]
  end
end
