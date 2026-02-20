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
end
