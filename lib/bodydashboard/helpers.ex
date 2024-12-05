defmodule Bodydashboard.Helpers do
  def get_error_messages(changeset) when is_struct(changeset, Ecto.Changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field} #{errors}" end)
    |> Enum.join(", ")
  end
end
