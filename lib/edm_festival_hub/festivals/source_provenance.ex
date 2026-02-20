defmodule EdmFestivalHub.Festivals.SourceProvenance do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "source_provenances" do
    field :record_type, :string
    field :record_id, :binary_id
    field :field, :string
    field :source_url, :string
    field :fetched_at, :utc_datetime_usec
    field :confidence, :float
    field :notes, :string

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(prov, attrs) do
    prov
    |> cast(attrs, [
      :record_type,
      :record_id,
      :field,
      :source_url,
      :fetched_at,
      :confidence,
      :notes
    ])
    |> validate_required([:record_type, :record_id, :field, :source_url, :fetched_at])
  end
end
