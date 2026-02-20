defmodule EdmFestivalHub.Festivals.FestivalSocials do
  use Ecto.Schema
  import Ecto.Changeset

  alias EdmFestivalHub.Festivals.Festival

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "festival_socials" do
    field :instagram_url, :string
    field :facebook_url, :string
    field :x_url, :string
    field :tiktok_url, :string
    field :youtube_url, :string
    field :discord_url, :string

    belongs_to :festival, Festival

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(socials, attrs) do
    socials
    |> cast(attrs, [
      :instagram_url,
      :facebook_url,
      :x_url,
      :tiktok_url,
      :youtube_url,
      :discord_url
    ])
    |> normalize_urls([
      :instagram_url,
      :facebook_url,
      :x_url,
      :tiktok_url,
      :youtube_url,
      :discord_url
    ])
  end

  defp normalize_urls(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, acc ->
      case get_change(acc, field) do
        "" -> put_change(acc, field, nil)
        value when is_binary(value) -> put_change(acc, field, String.trim(value))
        _ -> acc
      end
    end)
  end
end
