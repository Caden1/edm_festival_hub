defmodule EdmFestivalHub.Festivals.CommunityLinks do
  use Ecto.Schema
  import Ecto.Changeset

  alias EdmFestivalHub.Festivals.Festival

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "community_links" do
    field :subreddit_url, :string
    field :facebook_group_url, :string
    field :forum_url, :string
    field :other_discussion_url, :string

    belongs_to :festival, Festival

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(community, attrs) do
    community
    |> cast(attrs, [:subreddit_url, :facebook_group_url, :forum_url, :other_discussion_url])
    |> normalize_urls([:subreddit_url, :facebook_group_url, :forum_url, :other_discussion_url])
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
