defmodule Bodydashboard.Records.BodyComposition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "body_compositions" do
    field :weight_kg, :float
    field :record_date, :date
    field :body_fat, :float
    field :muscle_mass, :float
    field :bone_density, :float

    belongs_to :user, Bodydashboard.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(body_composition, attrs) do
    body_composition
    |> cast(attrs, [:weight_kg, :user_id, :record_date, :body_fat, :muscle_mass, :bone_density])
    |> validate_required([:user_id, :record_date])
    |> validate_number(:weight_kg, greater_than: 0)
    |> validate_number(:body_fat, greater_than: 0)
    |> validate_number(:muscle_mass, greater_than: 0)
    |> validate_number(:bone_density, greater_than: 0)
    |> foreign_key_constraint(:user_id)
  end
end
