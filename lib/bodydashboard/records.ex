defmodule Bodydashboard.Records do
  import Ecto.Query
  alias Ecto.Repo
  alias Ecto.Repo
  alias Bodydashboard.Repo
  alias Bodydashboard.Records.BodyRecord

  def create_body_record(user, attrs) do
    user
    |> Ecto.build_assoc(:body_records)
    |> BodyRecord.changeset(attrs)
    |> Repo.insert()
  end

  def update_body_record(id, attrs) do
    case get_body_record(id) do
      nil ->
        {:error, :not_found}

      existing ->
        existing
        |> BodyRecord.changeset(attrs)
        |> Repo.update()
    end
  end

  def get_body_record(id) do
    BodyRecord
    |> Repo.get(id)
  end

  def get_user_records(user) do
    BodyRecord
    |> where(user_id: ^user.id)
    |> Repo.all()
  end

  def get_user_records(user, date) when is_struct(date, Date) do
    BodyRecord
    |> where([b], b.user_id == ^user.id and fragment("DATE(?)", b.record_date) == ^date)
    |> Repo.all()
  end
end
