defmodule EdmFestivalHub.Festivals.LineupEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias EdmFestivalHub.Festivals.{Artist, Festival}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "lineup_entries" do
    field :billed_as, :string
    field :day, :date
    field :set_time, :time
    field :stage, :string

    belongs_to :festival, Festival
    belongs_to :artist, Artist

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:billed_as, :day, :set_time, :stage, :festival_id, :artist_id])
    |> validate_required([:festival_id, :artist_id])
  end
end
