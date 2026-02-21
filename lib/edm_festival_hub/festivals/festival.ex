defmodule EdmFestivalHub.Festivals.Festival do
  use Ecto.Schema
  import Ecto.Changeset

  alias EdmFestivalHub.Festivals.{
    CommunityLinks,
    FestivalLinks,
    FestivalSocials,
    LineupEntry,
    Venue
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "festivals" do
    field :name, :string
    field :slug, :string
    field :wikidata_qid, :string
    field :start_date, :date
    field :end_date, :date
    field :city, :string
    field :state, :string
    field :official_url, :string
    field :ticket_url, :string
    field :description, :string
    field :verified_at, :utc_datetime_usec

    belongs_to :venue, Venue

    has_one :links, FestivalLinks, on_replace: :update
    has_one :socials, FestivalSocials, on_replace: :update
    has_one :community_links, CommunityLinks, on_replace: :update

    has_many :lineup_entries, LineupEntry

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(festival, attrs) do
    festival
    |> cast(attrs, [
      :name,
      :slug,
      :wikidata_qid,
      :start_date,
      :end_date,
      :city,
      :state,
      :official_url,
      :ticket_url,
      :description
    ])
    |> trim_fields([:name, :slug, :city, :state, :official_url, :ticket_url])
    |> normalize_state(:state)
    |> maybe_slugify_provided_slug()
    |> maybe_generate_slug()
    |> maybe_set_verified_at()
    |> validate_required([:name, :slug, :start_date, :end_date, :city, :state, :official_url])
    |> validate_length(:state, is: 2)
    |> validate_end_date_after_start_date()
    |> validate_url(:official_url, required: true)
    |> validate_url(:ticket_url, required: false)
    |> validate_length(:name, min: 2, max: 120)
    |> validate_length(:slug, min: 2, max: 160)
    |> cast_assoc(:venue, required: true, with: &Venue.changeset/2)
    |> cast_assoc(:links, with: &FestivalLinks.changeset/2)
    |> cast_assoc(:socials, with: &FestivalSocials.changeset/2)
    |> cast_assoc(:community_links, with: &CommunityLinks.changeset/2)
    |> unique_constraint(:slug)
    |> unique_constraint(:wikidata_qid)
  end

  @doc """
  A more permissive changeset intended for automated imports.

  This allows partial "directory" records where dates/locations are unknown,
  and permits setting a `venue_id` directly (without nested venue forms).
  """
  def import_changeset(festival, attrs) do
    festival
    |> cast(attrs, [
      :name,
      :slug,
      :wikidata_qid,
      :start_date,
      :end_date,
      :city,
      :state,
      :venue_id,
      :official_url,
      :ticket_url,
      :description,
      :verified_at
    ])
    |> trim_fields([:name, :slug, :city, :state, :official_url, :ticket_url])
    |> normalize_state(:state)
    |> maybe_slugify_provided_slug()
    |> maybe_generate_slug()
    |> maybe_set_verified_at()
    |> validate_required([:name, :slug, :official_url, :wikidata_qid])
    |> validate_length(:state, is: 2)
    |> validate_end_date_after_start_date()
    |> validate_url(:official_url, required: true)
    |> validate_url(:ticket_url, required: false)
    |> validate_length(:name, min: 2, max: 120)
    |> validate_length(:slug, min: 2, max: 160)
    |> unique_constraint(:slug)
    |> unique_constraint(:wikidata_qid)
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

  defp maybe_slugify_provided_slug(changeset) do
    case get_change(changeset, :slug) do
      value when is_binary(value) and value != "" ->
        put_change(changeset, :slug, slugify(value))

      _ ->
        changeset
    end
  end

  defp maybe_generate_slug(changeset) do
    slug = get_field(changeset, :slug)
    name = get_field(changeset, :name)
    start_date = get_field(changeset, :start_date)
    wikidata_qid = get_field(changeset, :wikidata_qid)

    if (is_nil(slug) or slug == "") and is_binary(name) and name != "" do
      base =
        cond do
          match?(%Date{}, start_date) -> "#{name} #{Date.to_iso8601(start_date)}"
          is_binary(wikidata_qid) and wikidata_qid != "" -> "#{name} #{wikidata_qid}"
          true -> name
        end

      put_change(changeset, :slug, slugify(base))
    else
      changeset
    end
  end

  defp maybe_set_verified_at(changeset) do
    # On insert, default verified_at if not provided.
    case {changeset.data.__meta__.state, get_field(changeset, :verified_at)} do
      {:built, nil} -> put_change(changeset, :verified_at, DateTime.utc_now())
      _ -> changeset
    end
  end

  defp validate_end_date_after_start_date(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    case {start_date, end_date} do
      {%Date{} = s, %Date{} = e} ->
        if Date.compare(e, s) == :lt do
          add_error(changeset, :end_date, "must be on or after start_date")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_url(changeset, field, opts) do
    required? = Keyword.get(opts, :required, false)

    changeset
    |> empty_string_to_nil(field)
    |> validate_change(field, fn ^field, value ->
      cond do
        is_nil(value) and required? ->
          [{field, "can't be blank"}]

        is_nil(value) ->
          []

        valid_http_url?(value) ->
          []

        true ->
          [{field, "must be a valid http(s) URL"}]
      end
    end)
  end

  defp empty_string_to_nil(changeset, field) do
    case get_change(changeset, field) do
      "" -> put_change(changeset, field, nil)
      value when is_binary(value) -> put_change(changeset, field, String.trim(value))
      _ -> changeset
    end
  end

  defp valid_http_url?(value) when is_binary(value) do
    case URI.parse(value) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and is_binary(host) ->
        true

      _ ->
        false
    end
  end

  def slugify(str) when is_binary(str) do
    str
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/[\s_-]/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "festival"
      other -> other
    end
  end
end
