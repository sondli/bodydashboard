defmodule Bodydashboard.Repo.Migrations.CreateBodyRecords do
  use Ecto.Migration

  def change do
    create table(:body_records) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :weight_kg, :float

      timestamps()
    end

    create index(:body_records, [:user_id])
  end
end
