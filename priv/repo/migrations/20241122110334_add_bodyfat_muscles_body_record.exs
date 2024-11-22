defmodule Bodydashboard.Repo.Migrations.AddBodyfatMusclesBodyRecord do
  use Ecto.Migration

  def change do
    alter table(:body_records) do
      add :body_fat, :float
      add :muscle_mass, :float
      add :bone_density, :float
    end

    rename table(:body_records), to: table(:body_compositions)
  end
end
