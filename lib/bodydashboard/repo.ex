defmodule Bodydashboard.Repo do
  use Ecto.Repo,
    otp_app: :bodydashboard,
    adapter: Ecto.Adapters.Postgres
end
