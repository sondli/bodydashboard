defmodule Bodydashboard.Records do
  import Ecto.Query
  alias Ecto.Repo
  alias Ecto.Repo
  alias Bodydashboard.Repo
  alias Bodydashboard.Records.BodyComposition

  def create_body_composition(user, attrs) do
    user
    |> Ecto.build_assoc(:body_compositions)
    |> BodyComposition.changeset(attrs)
    |> Repo.insert()
  end

  def update_body_composition(id, attrs) do
    case get_body_composition(id) do
      nil ->
        {:error, :not_found}

      existing ->
        existing
        |> BodyComposition.changeset(attrs)
        |> Repo.update()
    end
  end

  def get_body_composition(id) do
    BodyComposition
    |> Repo.get(id)
  end

  def get_user_body_composition(user) do
    BodyComposition
    |> where(user_id: ^user.id)
    |> Repo.all()
  end

  def get_user_body_composition(user, date) when is_struct(date, Date) do
    BodyComposition
    |> where([b], b.user_id == ^user.id and fragment("DATE(?)", b.record_date) == ^date)
    |> Repo.one()
  end
end
