defmodule Bodydashboard.Records.BodyRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "body_records" do
    field :weight_kg, :float

    belongs_to :user, Bodydashboard.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(body_record, attrs) do
    body_record
    |> cast(attrs, [:weight_kg, :user_id])
    |> validate_required([:weight_kg, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end