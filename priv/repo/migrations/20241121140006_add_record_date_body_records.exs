defmodule Bodydashboard.Repo.Migrations.AddRecordDateBodyRecords do
  use Ecto.Migration

  def change do
    alter table(:body_records) do
      add :record_date, :date
    end

  end
end
