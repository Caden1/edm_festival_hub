defmodule EdmFestivalHubWeb.FestivalLiveTest do
  use EdmFestivalHubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import EdmFestivalHub.FestivalsFixtures

  test "index lists upcoming festivals", %{conn: conn} do
    festival = festival_fixture(%{name: "Ultra Test"})

    {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "Upcoming EDM Festivals"
    assert html =~ "Ultra Test"
    assert html =~ festival.slug
  end

  test "show displays festival details", %{conn: conn} do
    festival = festival_fixture(%{name: "Show Fest"})

    {:ok, _lv, html} = live(conn, ~p"/festivals/#{festival.slug}")
    assert html =~ "Show Fest"
    assert html =~ "Bag policy"
    assert html =~ "https://example.com/bag-policy"
  end

  test "directory lists festivals, including entries without dates", %{conn: conn} do
    _upcoming = festival_fixture(%{name: "Upcoming Fest"})
    directory_festival = wikidata_festival_fixture(%{name: "Directory Only"})

    {:ok, _lv, html} = live(conn, ~p"/directory")
    assert html =~ "Festival Directory"
    assert html =~ "Upcoming Fest"
    assert html =~ "Directory Only"
    assert html =~ directory_festival.slug
    assert html =~ "Dates TBD"
  end

  test "show handles festivals with unknown dates and location", %{conn: conn} do
    festival = wikidata_festival_fixture(%{name: "Mystery Fest"})

    {:ok, _lv, html} = live(conn, ~p"/festivals/#{festival.slug}")
    assert html =~ "Mystery Fest"
    assert html =~ "Dates TBD"
    assert html =~ "Location TBD"
  end
end
