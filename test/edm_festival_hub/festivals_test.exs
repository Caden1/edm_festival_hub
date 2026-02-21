defmodule EdmFestivalHub.FestivalsTest do
  use EdmFestivalHub.DataCase, async: true

  alias EdmFestivalHub.Festivals
  alias EdmFestivalHub.Festivals.Festival

  import EdmFestivalHub.FestivalsFixtures

  describe "create_festival/1" do
    test "creates a festival with nested data" do
      attrs = festival_attrs(%{name: "My Fest"})
      assert {:ok, %Festival{} = festival} = Festivals.create_festival(attrs)
      assert festival.slug =~ "my-fest"

      loaded = Festivals.get_festival_by_slug!(festival.slug)
      assert loaded.venue.name == "Red Rocks Amphitheatre"
      assert loaded.links.bag_policy_url == "https://example.com/bag-policy"
      assert loaded.socials.instagram_url == "https://instagram.com/examplefest"
      assert loaded.community_links.subreddit_url == "https://reddit.com/r/examplefest"
    end
  end

  describe "list_upcoming_festivals/0" do
    test "lists upcoming festivals" do
      festival = festival_fixture()
      names = Festivals.list_upcoming_festivals() |> Enum.map(& &1.name)
      assert festival.name in names
    end
  end

  describe "upsert_wikidata_festival/1" do
    test "upserts by wikidata_qid" do
      qid = "QTEST#{System.unique_integer([:positive])}"

      {:ok, f1} =
        Festivals.upsert_wikidata_festival(%{
          wikidata_qid: qid,
          name: "Wikidata One",
          slug: Festival.slugify("Wikidata One #{qid}"),
          official_url: "https://example.com/#{qid}"
        })

      {:ok, f2} =
        Festivals.upsert_wikidata_festival(%{
          wikidata_qid: qid,
          name: "Wikidata One (Renamed)",
          slug: Festival.slugify("Wikidata One Renamed #{qid}"),
          official_url: "https://example.com/#{qid}"
        })

      assert f1.id == f2.id
      assert f2.name == "Wikidata One (Renamed)"
    end
  end
end
