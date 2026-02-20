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
end
