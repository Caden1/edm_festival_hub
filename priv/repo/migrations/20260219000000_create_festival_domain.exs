defmodule EdmFestivalHub.Repo.Migrations.CreateFestivalDomain do
  use Ecto.Migration

  def change do
    create table(:venues, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :address, :string
      add :city, :string
      add :state, :string, size: 2
      add :postal_code, :string
      add :latitude, :float
      add :longitude, :float

      timestamps(type: :utc_datetime_usec)
    end

    create index(:venues, [:state, :city])
    create index(:venues, [:name])

    create table(:festivals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :city, :string, null: false
      add :state, :string, size: 2, null: false
      add :venue_id, references(:venues, type: :binary_id, on_delete: :nilify_all), null: false
      add :official_url, :string, null: false
      add :ticket_url, :string
      add :description, :text
      add :verified_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:festivals, [:slug])
    create index(:festivals, [:start_date])
    create index(:festivals, [:state, :city])

    create table(:festival_links, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :festival_id, references(:festivals, type: :binary_id, on_delete: :delete_all),
        null: false

      add :bag_policy_url, :string
      add :allowed_items_url, :string
      add :prohibited_items_url, :string
      add :payment_plan_url, :string
      add :hotels_url, :string
      add :map_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:festival_links, [:festival_id])

    create table(:festival_socials, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :festival_id, references(:festivals, type: :binary_id, on_delete: :delete_all),
        null: false

      add :instagram_url, :string
      add :facebook_url, :string
      add :x_url, :string
      add :tiktok_url, :string
      add :youtube_url, :string
      add :discord_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:festival_socials, [:festival_id])

    create table(:community_links, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :festival_id, references(:festivals, type: :binary_id, on_delete: :delete_all),
        null: false

      add :subreddit_url, :string
      add :facebook_group_url, :string
      add :forum_url, :string
      add :other_discussion_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:community_links, [:festival_id])

    create table(:artists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :spotify_url, :string
      add :soundcloud_url, :string
      add :apple_music_url, :string
      add :youtube_url, :string
      add :instagram_url, :string
      add :x_url, :string
      add :tiktok_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:artists, [:name])

    create table(:lineup_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :festival_id, references(:festivals, type: :binary_id, on_delete: :delete_all),
        null: false

      add :artist_id, references(:artists, type: :binary_id, on_delete: :delete_all), null: false
      add :billed_as, :string
      add :day, :date
      add :set_time, :time
      add :stage, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:lineup_entries, [:festival_id])
    create index(:lineup_entries, [:artist_id])
    create index(:lineup_entries, [:festival_id, :day])

    create table(:source_provenances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :record_type, :string, null: false
      add :record_id, :binary_id, null: false
      add :field, :string, null: false
      add :source_url, :string, null: false
      add :fetched_at, :utc_datetime_usec, null: false
      add :confidence, :float
      add :notes, :text

      timestamps(type: :utc_datetime_usec)
    end

    create index(:source_provenances, [:record_type, :record_id])
    create index(:source_provenances, [:record_type, :record_id, :field])
    create index(:source_provenances, [:fetched_at])
  end
end
