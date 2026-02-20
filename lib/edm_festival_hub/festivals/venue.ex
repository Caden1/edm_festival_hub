defmodule EdmFestivalHub.Festivals.Venue do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "venues" do
    field :name, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :postal_code, :string
    field :latitude, :float
    field :longitude, :float

    has_many :festivals, EdmFestivalHub.Festivals.Festival

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(venue, attrs) do
    venue
    |> cast(attrs, [:name, :address, :city, :state, :postal_code, :latitude, :longitude])
    |> trim_fields([:name, :address, :city, :state, :postal_code])
    |> normalize_state(:state)
    |> validate_required([:name])
    |> validate_optional_state(:state)
  end

  defp trim_fields(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, acc ->
      case get_change(acc, field) do
        value when is_binary(value) -> put_change(acc, field, String.trim(value))
        _ -> acc
      end
    end)
  end

  defp normalize_state(changeset, field) do
    case get_change(changeset, field) do
      value when is_binary(value) ->
        put_change(changeset, field, value |> String.trim() |> String.upcase())

      _ ->
        changeset
    end
  end

  defp validate_optional_state(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      value = String.trim(value || "")

      cond do
        value == "" -> []
        String.length(value) == 2 -> []
        true -> [{field, "must be a 2-letter US state code (e.g. CO)"}]
      end
    end)
  end
end
