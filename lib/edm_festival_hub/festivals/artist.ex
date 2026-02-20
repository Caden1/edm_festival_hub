defmodule EdmFestivalHub.Festivals.Artist do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "artists" do
    field :name, :string
    field :spotify_url, :string
    field :soundcloud_url, :string
    field :apple_music_url, :string
    field :youtube_url, :string
    field :instagram_url, :string
    field :x_url, :string
    field :tiktok_url, :string

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(artist, attrs) do
    artist
    |> cast(attrs, [
      :name,
      :spotify_url,
      :soundcloud_url,
      :apple_music_url,
      :youtube_url,
      :instagram_url,
      :x_url,
      :tiktok_url
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 120)
  end
end
