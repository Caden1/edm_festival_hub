alias EdmFestivalHub.Festivals

today = Date.utc_today()

Festivals.create_festival(%{
  name: "Example Fest",
  start_date: Date.add(today, 30),
  end_date: Date.add(today, 32),
  city: "Denver",
  state: "CO",
  official_url: "https://example.com",
  ticket_url: "https://example.com/tickets",
  description: "Starter seed festival for EDM Festival Hub.",
  venue: %{
    name: "Example Venue",
    address: "123 Main St",
    city: "Denver",
    state: "CO",
    postal_code: "80202"
  },
  links: %{
    bag_policy_url: "https://example.com/bag-policy",
    payment_plan_url: "https://example.com/payment-plans",
    hotels_url: "https://example.com/hotels",
    map_url: "https://maps.google.com"
  },
  socials: %{
    instagram_url: "https://instagram.com/examplefest",
    facebook_url: "https://facebook.com/examplefest"
  },
  community_links: %{
    subreddit_url: "https://reddit.com/r/examplefest"
  }
})
