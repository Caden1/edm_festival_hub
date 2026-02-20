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
end
