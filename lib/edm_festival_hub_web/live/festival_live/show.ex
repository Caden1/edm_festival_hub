defmodule EdmFestivalHubWeb.FestivalLive.Show do
  use EdmFestivalHubWeb, :live_view

  alias EdmFestivalHub.Festivals

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    festival = Festivals.get_festival_by_slug!(slug)

    {:ok,
     socket
     |> assign(:page_title, festival.name)
     |> assign(:festival, festival)
     |> assign(:ai_question, "")
     |> assign(:ai_answer, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl p-6 space-y-8">
      <div class="breadcrumbs text-sm">
        <ul>
          <li><.link navigate={~p"/"} class="link">Festivals</.link></li>
          <li>{@festival.name}</li>
        </ul>
      </div>

      <header class="space-y-3">
        <h1 class="text-3xl font-bold">{@festival.name}</h1>
        <p class="opacity-80">
          {format_dates(@festival.start_date, @festival.end_date)} • {format_location(@festival)}
          <span :if={@festival.venue}>({@festival.venue.name})</span>
        </p>

        <div class="flex flex-wrap gap-2">
          <a
            :if={present?(@festival.official_url)}
            class="btn btn-primary btn-sm"
            href={@festival.official_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            Official site
          </a>
          <a
            :if={present?(@festival.ticket_url)}
            class="btn btn-secondary btn-sm"
            href={@festival.ticket_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            Tickets
          </a>
        </div>

        <p :if={present?(@festival.description)} class="max-w-prose">
          {@festival.description}
        </p>

        <p :if={@festival.verified_at} class="text-xs opacity-70">
          Last verified: {Calendar.strftime(@festival.verified_at, "%b %d, %Y %H:%M UTC")}
        </p>
      </header>

      <section class="grid gap-6 md:grid-cols-2">
        <.links_card festival={@festival} />
        <.socials_card festival={@festival} />
        <.community_card festival={@festival} />
        <.hotels_card festival={@festival} />
      </section>

      <section class="card bg-base-100 shadow">
        <div class="card-body space-y-4">
          <h2 class="card-title">Ask AI about this festival (stub)</h2>
          <p class="opacity-80 text-sm">
            This will be wired to your curated sources  database records. For now, it only echoes your question.
          </p>

          <form phx-submit="ask_ai" class="space-y-3">
            <textarea
              name="question"
              class="textarea textarea-bordered w-full"
              rows="3"
              placeholder="Ask about bag policy, payment plans, hotels, lineup, etc."
            ><%= @ai_question %></textarea>
            <button type="submit" class="btn btn-accent btn-sm">Ask</button>
          </form>

          <div :if={@ai_answer} class="alert alert-info">
            <span>{@ai_answer}</span>
          </div>
        </div>
      </section>

      <section :if={@festival.lineup_entries != []} class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">Lineup</h2>
          <ul class="list-disc pl-6">
            <li :for={entry <- @festival.lineup_entries}>
              {entry.billed_as || entry.artist.name}
              <span :if={entry.day} class="opacity-70">
                — {Calendar.strftime(entry.day, "%b %d, %Y")}
              </span>
              <span :if={present?(entry.stage)} class="opacity-70"> —            {entry.stage}</span>
            </li>
          </ul>
        </div>
      </section>
    </div>
    """
  end

  @impl true
  def handle_event("ask_ai", %{"question" => question}, socket) do
    question = String.trim(question || "")

    answer =
      if question == "" do
        "Ask a question above 🙂"
      else
        "Stub answer (will be replaced): You asked: “#{question}”"
      end

    {:noreply, assign(socket, ai_answer: answer, ai_question: question)}
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

  attr :festival, :any, required: true

  defp links_card(assigns) do
    links = assigns.festival.links || %{}
    assigns = assign(assigns, :links, links)

    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body space-y-2">
        <h2 class="card-title">Policies & planning</h2>

        <.maybe_link label="Bag policy" url={@links.bag_policy_url} />
        <.maybe_link label="What you can bring" url={@links.allowed_items_url} />
        <.maybe_link label="Prohibited items" url={@links.prohibited_items_url} />
        <.maybe_link label="Payment plans" url={@links.payment_plan_url} />
      </div>
    </div>
    """
  end

  attr :festival, :any, required: true

  defp socials_card(assigns) do
    socials = assigns.festival.socials || %{}
    assigns = assign(assigns, :socials, socials)

    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body space-y-2">
        <h2 class="card-title">Official socials</h2>

        <.maybe_link label="Instagram" url={@socials.instagram_url} />
        <.maybe_link label="Facebook" url={@socials.facebook_url} />
        <.maybe_link label="X" url={@socials.x_url} />
        <.maybe_link label="TikTok" url={@socials.tiktok_url} />
        <.maybe_link label="YouTube" url={@socials.youtube_url} />
        <.maybe_link label="Discord" url={@socials.discord_url} />
      </div>
    </div>
    """
  end

  attr :festival, :any, required: true

  defp community_card(assigns) do
    community = assigns.festival.community_links || %{}
    assigns = assign(assigns, :community, community)

    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body space-y-2">
        <h2 class="card-title">Community</h2>

        <.maybe_link label="Subreddit" url={@community.subreddit_url} />
        <.maybe_link label="Facebook group" url={@community.facebook_group_url} />
        <.maybe_link label="Forum" url={@community.forum_url} />
        <.maybe_link label="Other discussion" url={@community.other_discussion_url} />
      </div>
    </div>
    """
  end

  attr :festival, :any, required: true

  defp hotels_card(assigns) do
    links = assigns.festival.links || %{}
    assigns = assign(assigns, :links, links)

    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body space-y-2">
        <h2 class="card-title">Hotels & maps</h2>

        <.maybe_link label="Nearby hotels" url={@links.hotels_url} />
        <.maybe_link label="Map" url={@links.map_url} />
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :url, :string, default: nil

  defp maybe_link(assigns) do
    ~H"""
    <div>
      <span class="font-semibold">{@label}:</span>
      <span :if={present?(@url)}>
        <a href={@url} target="_blank" rel="noopener noreferrer" class="link">{@url}</a>
      </span>
      <span :if={!present?(@url)} class="opacity-60">Not added yet</span>
    </div>
    """
  end
end
