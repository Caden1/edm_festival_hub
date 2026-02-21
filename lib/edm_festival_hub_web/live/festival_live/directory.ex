defmodule EdmFestivalHubWeb.FestivalLive.Directory do
  use EdmFestivalHubWeb, :live_view

  alias EdmFestivalHub.Festivals

  @impl true
  def mount(_params, _session, socket) do
    festivals = Festivals.list_directory_festivals()

    {:ok,
     socket
     |> assign(:page_title, "Festival Directory")
     |> assign(:festivals, festivals)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl p-6 space-y-6">
      <header class="space-y-3">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <h1 class="text-3xl font-bold">Festival Directory (USA)</h1>

          <div class="join">
            <.link navigate={~p"/"} class="btn btn-sm join-item">Upcoming</.link>
            <span class="btn btn-sm join-item btn-active" aria-current="page">Directory</span>
          </div>
        </div>

        <p class="opacity-80">
          A broader list that may include festivals with unknown dates. Great for exploration and
          gradually enriching with official links and policies.
        </p>
      </header>

      <div :if={@festivals == []} class="alert">
        <span>
          No festivals yet.
          Try importing a seed list: <code class="ml-1">mix festivals.import_wikidata</code>
        </span>
      </div>

      <div class="grid gap-4 md:grid-cols-2">
        <div :for={festival <- @festivals} class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">
              <.link navigate={~p"/festivals/#{festival.slug}"} class="link link-hover">
                {festival.name}
              </.link>
            </h2>

            <p class="text-sm opacity-80">
              {format_dates(festival.start_date, festival.end_date)} • {format_location(festival)}
            </p>

            <p :if={festival.venue} class="text-sm opacity-80">Venue: {festival.venue.name}</p>

            <div class="card-actions justify-end">
              <.link navigate={~p"/festivals/#{festival.slug}"} class="btn btn-primary btn-sm">
                View details
              </.link>
              <a
                :if={present?(festival.official_url)}
                href={festival.official_url}
                class="btn btn-ghost btn-sm"
                target="_blank"
                rel="noopener noreferrer"
              >
                Official site
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_dates(%Date{} = start_date, %Date{} = end_date) do
    start_str = Calendar.strftime(start_date, "%b %d, %Y")
    end_str = Calendar.strftime(end_date, "%b %d, %Y")
    if start_str == end_str, do: start_str, else: "#{start_str} – #{end_str}"
  end

  defp format_dates(%Date{} = start_date, nil) do
    Calendar.strftime(start_date, "%b %d, %Y")
  end

  defp format_dates(_, _), do: "Dates TBD"

  defp format_location(festival) do
    cond do
      present?(festival.city) and present?(festival.state) ->
        "#{festival.city}, #{festival.state}"

      present?(festival.state) ->
        festival.state

      festival.venue && present?(festival.venue.city) && present?(festival.venue.state) ->
        "#{festival.venue.city}, #{festival.venue.state}"

      true ->
        "Location TBD"
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_), do: false
end
