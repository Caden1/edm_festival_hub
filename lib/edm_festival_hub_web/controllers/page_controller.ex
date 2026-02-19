defmodule EdmFestivalHubWeb.PageController do
  use EdmFestivalHubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
