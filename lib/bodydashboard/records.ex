defmodule Bodydashboard.Records do
  import Ecto.Query
  alias Ecto.Repo
  alias Bodydashboard.Repo
  alias Bodydashboard.Records.BodyRecord

  def create_body_record(user, attrs) do
    user
    |> Ecto.build_assoc(:body_records)
    |> BodyRecord.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_records(user) do
    BodyRecord
    |> where(user_id: ^user.id)
    |> Repo.all()
  end
end
