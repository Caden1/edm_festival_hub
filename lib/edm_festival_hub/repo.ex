defmodule EdmFestivalHub.Repo do
  use Ecto.Repo,
    otp_app: :edm_festival_hub,
    adapter: Ecto.Adapters.Postgres
end
