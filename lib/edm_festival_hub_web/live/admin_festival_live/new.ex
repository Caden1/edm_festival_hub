defmodule EdmFestivalHubWeb.AdminFestivalLive.New do
  use EdmFestivalHubWeb, :live_view

  import EdmFestivalHubWeb.FormComponents, only: [textarea: 1]

  alias EdmFestivalHub.Festivals

  @impl true
  def mount(_params, _session, socket) do
    festival = Festivals.new_festival()
    changeset = Festivals.change_festival(festival)

    {:ok,
     socket
     |> assign(:page_title, "Add festival (dev)")
     |> assign(:festival, festival)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"festival" => params}, socket) do
    changeset =
      socket.assigns.festival
      |> Festivals.change_festival(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"festival" => params}, socket) do
    case Festivals.create_festival(params) do
      {:ok, festival} ->
        {:noreply,
         socket
         |> put_flash(:info, "Festival created!")
         |> push_navigate(to: ~p"/festivals/#{festival.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :validate)))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl p-6 space-y-6">
      <div class="breadcrumbs text-sm">
        <ul>
          <li><.link navigate={~p"/"} class="link">Festivals</.link></li>
          <li>Add festival (dev)</li>
        </ul>
      </div>

      <header class="space-y-2">
        <h1 class="text-2xl font-bold">Add a festival (dev-only route)</h1>
        <p class="opacity-80 text-sm">
          Temporary ingestion screen. We'll replace this with real auth  admin later.
        </p>
      </header>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-8">
        <section class="card bg-base-100 shadow">
          <div class="card-body space-y-4">
            <h2 class="card-title">Festival</h2>

            <.input field={@form[:name]} label="Festival name" required />

            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:start_date]} type="date" label="Start date" required />
              <.input field={@form[:end_date]} type="date" label="End date" required />
            </div>

            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:city]} label="City" required />
              <.input field={@form[:state]} label="State (2-letter)" placeholder="CO" required />
            </div>

            <.input field={@form[:official_url]} type="url" label="Official website URL" required />
            <.input field={@form[:ticket_url]} type="url" label="Tickets URL" />

            <.textarea field={@form[:description]} label="Short description" rows={4} />
          </div>
        </section>

        <section class="card bg-base-100 shadow">
          <div class="card-body space-y-4">
            <h2 class="card-title">Venue</h2>

            <.inputs_for :let={venue_f} field={@form[:venue]}>
              <.input field={venue_f[:name]} label="Venue name" required />
              <.input field={venue_f[:address]} label="Address" />

              <div class="grid gap-4 md:grid-cols-2">
                <.input field={venue_f[:city]} label="City" />
                <.input field={venue_f[:state]} label="State" placeholder="CO" />
              </div>

              <.input field={venue_f[:postal_code]} label="Postal code" />

              <div class="grid gap-4 md:grid-cols-2">
                <.input field={venue_f[:latitude]} type="number" label="Latitude" step="any" />
                <.input field={venue_f[:longitude]} type="number" label="Longitude" step="any" />
              </div>
            </.inputs_for>
          </div>
        </section>

        <section class="card bg-base-100 shadow">
          <div class="card-body space-y-4">
            <h2 class="card-title">Policies & planning links</h2>

            <.inputs_for :let={links_f} field={@form[:links]}>
              <.input field={links_f[:bag_policy_url]} type="url" label="Bag policy URL" />
              <.input field={links_f[:payment_plan_url]} type="url" label="Payment plan URL" />

              <div class="grid gap-4 md:grid-cols-2">
                <.input field={links_f[:allowed_items_url]} type="url" label="Allowed items URL" />
                <.input
                  field={links_f[:prohibited_items_url]}
                  type="url"
                  label="Prohibited items URL"
                />
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <.input field={links_f[:hotels_url]} type="url" label="Nearby hotels URL" />
                <.input field={links_f[:map_url]} type="url" label="Map URL" />
              </div>
            </.inputs_for>
          </div>
        </section>

        <section class="card bg-base-100 shadow">
          <div class="card-body space-y-4">
            <h2 class="card-title">Socials</h2>

            <.inputs_for :let={social_f} field={@form[:socials]}>
              <div class="grid gap-4 md:grid-cols-2">
                <.input field={social_f[:instagram_url]} type="url" label="Instagram URL" />
                <.input field={social_f[:facebook_url]} type="url" label="Facebook URL" />
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <.input field={social_f[:x_url]} type="url" label="X URL" />
                <.input field={social_f[:tiktok_url]} type="url" label="TikTok URL" />
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <.input field={social_f[:youtube_url]} type="url" label="YouTube URL" />
                <.input field={social_f[:discord_url]} type="url" label="Discord URL" />
              </div>
            </.inputs_for>
          </div>
        </section>

        <section class="card bg-base-100 shadow">
          <div class="card-body space-y-4">
            <h2 class="card-title">Community links</h2>

            <.inputs_for :let={c_f} field={@form[:community_links]}>
              <.input field={c_f[:subreddit_url]} type="url" label="Subreddit URL" />
              <.input field={c_f[:facebook_group_url]} type="url" label="Facebook group URL" />
              <.input field={c_f[:forum_url]} type="url" label="Forum URL" />
              <.input field={c_f[:other_discussion_url]} type="url" label="Other discussion URL" />
            </.inputs_for>
          </div>
        </section>

        <div class="flex justify-end">
          <.button class="btn btn-primary">Create festival</.button>
        </div>
      </.form>
    </div>
    """
  end
end
