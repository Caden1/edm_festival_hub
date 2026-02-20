defmodule EdmFestivalHub.Festivals.FestivalLinks do
  use Ecto.Schema
  import Ecto.Changeset

  alias EdmFestivalHub.Festivals.Festival

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "festival_links" do
    field :bag_policy_url, :string
    field :allowed_items_url, :string
    field :prohibited_items_url, :string
    field :payment_plan_url, :string
    field :hotels_url, :string
    field :map_url, :string

    belongs_to :festival, Festival

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(links, attrs) do
    links
    |> cast(attrs, [
      :bag_policy_url,
      :allowed_items_url,
      :prohibited_items_url,
      :payment_plan_url,
      :hotels_url,
      :map_url
    ])
    |> normalize_urls([
      :bag_policy_url,
      :allowed_items_url,
      :prohibited_items_url,
      :payment_plan_url,
      :hotels_url,
      :map_url
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
