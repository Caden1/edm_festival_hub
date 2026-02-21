defmodule EdmFestivalHub.Festivals do
  @moduledoc """
  The Festivals context.

  Owns festivals, venues, official/curated links, socials, community links,
  lineup data, and per-field source provenance.
  """

  import Ecto.Query, warn: false
  alias EdmFestivalHub.Repo

  alias EdmFestivalHub.Festivals.{
    Festival,
    Venue,
    FestivalLinks,
    FestivalSocials,
    CommunityLinks
  }

  @doc """
  Returns a new festival struct with nested associations pre-built so nested forms render.
  """
  def new_festival do
    %Festival{
      venue: %Venue{},
      links: %FestivalLinks{},
      socials: %FestivalSocials{},
      community_links: %CommunityLinks{}
    }
  end

  @doc """
  List festivals with a start date on/after today, ordered soonest-first.
  """
  def list_upcoming_festivals do
    today = Date.utc_today()

    query =
      from f in Festival,
        where: f.start_date >= ^today,
        order_by: [asc: f.start_date, asc: f.name]

    query
    |> Repo.all()
    |> Repo.preload(:venue)
  end

  @doc """
  List *all* festivals (including records missing dates) ordered A→Z.

  Useful for a "Directory" view when some entries don't have reliable dates.
  """
  def list_directory_festivals do
    Festival
    |> order_by([f], asc: f.name)
    |> Repo.all()
    |> Repo.preload(:venue)
  end

  @doc """
  Fetch a festival by slug, with everything needed for the detail page preloaded.
  """
  def get_festival_by_slug!(slug) when is_binary(slug) do
    Festival
    |> Repo.get_by!(slug: slug)
    |> Repo.preload([:venue, :links, :socials, :community_links, lineup_entries: [:artist]])
  end

  @doc """
  Create a festival (supports nested venue/links/socials/community in a single payload).
  """
  def create_festival(attrs \\ %{}) do
    %Festival{}
    |> Festival.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a changeset for a festival.
  """
  def change_festival(%Festival{} = festival, attrs \\ %{}) do
    Festival.changeset(festival, attrs)
  end

  @doc """
  Upsert a venue from Wikidata attributes.

  Requires `:wikidata_qid`.
  """
  def upsert_wikidata_venue(%{wikidata_qid: qid} = attrs) when is_binary(qid) and qid != "" do
    changeset =
      %Venue{}
      |> Venue.changeset(attrs)

    on_conflict = [
      set:
        conflict_set(attrs, Venue, [
          :name,
          :address,
          :city,
          :state,
          :postal_code,
          :latitude,
          :longitude
        ])
    ]

    Repo.insert(changeset,
      conflict_target: [:wikidata_qid],
      on_conflict: on_conflict,
      returning: true
    )
  end

  def upsert_wikidata_venue(attrs) when is_map(attrs) do
    {:error,
     Ecto.Changeset.add_error(
       Ecto.Changeset.change(%Venue{}),
       :wikidata_qid,
       "is required for Wikidata upserts"
     )}
  end

  @doc """
  Upsert a festival from Wikidata attributes.

  Expected attrs shape:

      %{
        wikidata_qid: "Q123",
        name: "Some Festival",
        slug: "some-festival-q123",
        official_url: "https://...",
        start_date: ~D[2026-05-01] | nil,
        end_date: ~D[2026-05-03] | nil,
        city: "Denver" | nil,
        state: "CO" | nil,
        venue: %{wikidata_qid: "Q999", name: "Venue"} | nil
      }

  Only a subset may be present; this is intended for "directory" records.
  """
  def upsert_wikidata_festival(attrs) when is_map(attrs) do
    Repo.transaction(fn ->
      venue_id =
        case Map.get(attrs, :venue) do
          %{} = venue_attrs ->
            case upsert_wikidata_venue(venue_attrs) do
              {:ok, venue} -> venue.id
              {:error, changeset} -> Repo.rollback(changeset)
            end

          _ ->
            nil
        end

      now = DateTime.utc_now()

      festival_attrs =
        attrs
        |> Map.drop([:venue])
        |> maybe_put(:venue_id, venue_id)
        |> Map.put(:verified_at, Map.get(attrs, :verified_at) || now)
        |> Map.put(:updated_at, now)

      changeset = Festival.import_changeset(%Festival{}, festival_attrs)

      on_conflict = [
        set:
          conflict_set(festival_attrs, Festival, [
            :name,
            :slug,
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
      ]

      case Repo.insert(changeset,
             conflict_target: [:wikidata_qid],
             on_conflict: on_conflict,
             returning: true
           ) do
        {:ok, festival} ->
          festival |> Repo.preload(:venue)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, festival} -> {:ok, festival}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  defp conflict_set(attrs, _schema, allowed_fields) do
    now = DateTime.utc_now()

    attrs
    |> Map.take(allowed_fields)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into([])
    |> Keyword.put(:updated_at, now)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
