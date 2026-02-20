defmodule EdmFestivalHubWeb.FestivalLive.Index do
  use EdmFestivalHubWeb, :live_view

  alias EdmFestivalHub.Festivals

  @impl true
  def mount(_params, _session, socket) do
    festivals = Festivals.list_upcoming_festivals()

    {:ok,
     socket
     |> assign(:page_title, "Upcoming EDM Festivals")
     |> assign(:festivals, festivals)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl p-6 space-y-6">
      <header class="space-y-2">
        <h1 class="text-3xl font-bold">Upcoming EDM Festivals (USA)</h1>
        <p class="opacity-80">
          A curated, easy-to-scan list with official links for tickets, policies, payment plans, and more.
        </p>
      </header>

      <div :if={@festivals == []} class="alert">
        <span>
          No upcoming festivals yet.
          In dev, add one here:
          <.link navigate="/dev/festivals/new" class="link">/dev/festivals/new</.link>
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
              {format_dates(festival.start_date, festival.end_date)} • {festival.city}, {festival.state}
            </p>

            <p :if={festival.venue} class="text-sm opacity-80">
              Venue: {festival.venue.name}
            </p>

            <div class="card-actions justify-end">
              <.link navigate={~p"/festivals/#{festival.slug}"} class="btn btn-primary btn-sm">
                View details
              </.link>
              <a
                :if={is_binary(festival.ticket_url) and festival.ticket_url != ""}
                href={festival.ticket_url}
                class="btn btn-ghost btn-sm"
                target="_blank"
                rel="noopener noreferrer"
              >
                Tickets
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
end
