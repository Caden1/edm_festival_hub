defmodule EdmFestivalHub.FestivalsFixtures do
  @moduledoc false

  alias EdmFestivalHub.Festivals

  def venue_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Red Rocks Amphitheatre",
      city: "Morrison",
      state: "CO"
    })
  end

  def festival_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Fest",
      start_date: Date.add(Date.utc_today(), 10),
      end_date: Date.add(Date.utc_today(), 11),
      city: "Denver",
      state: "CO",
      official_url: "https://example.com",
      ticket_url: "https://example.com/tickets",
      description: "A test festival",
      venue: venue_attrs(),
      links: %{bag_policy_url: "https://example.com/bag-policy"},
      socials: %{instagram_url: "https://instagram.com/examplefest"},
      community_links: %{subreddit_url: "https://reddit.com/r/examplefest"}
    })
  end

  def festival_fixture(attrs \\ %{}) do
    {:ok, festival} =
      attrs
      |> festival_attrs()
      |> Festivals.create_festival()

    festival
  end

  def wikidata_festival_fixture(attrs \\ %{}) do
    qid = Map.get(attrs, :wikidata_qid, "QTEST#{System.unique_integer([:positive])}")
    name = Map.get(attrs, :name, "Wikidata Fest")

    base_attrs = %{
      wikidata_qid: qid,
      name: name,
      slug: EdmFestivalHub.Festivals.Festival.slugify("#{name} #{qid}"),
      official_url: Map.get(attrs, :official_url, "https://example.com/#{qid}"),
      start_date: Map.get(attrs, :start_date),
      end_date: Map.get(attrs, :end_date),
      city: Map.get(attrs, :city),
      state: Map.get(attrs, :state),
      venue: Map.get(attrs, :venue)
    }

    {:ok, festival} = Festivals.upsert_wikidata_festival(base_attrs)
    festival
  end
end
