defmodule EdmFestivalHub.Repo.Migrations.AddWikidataIdsAndAllowPartialFestivals do
  use Ecto.Migration

  def change do
    alter table(:venues) do
      add :wikidata_qid, :string
    end

    create unique_index(:venues, [:wikidata_qid])

    alter table(:festivals) do
      add :wikidata_qid, :string
    end

    create unique_index(:festivals, [:wikidata_qid])

    # Allow partial festival records so we can ingest directory-style entries
    # from open data sources (ex: Wikidata) without forcing dates/locations.
    execute(
      "ALTER TABLE festivals ALTER COLUMN start_date DROP NOT NULL",
      "ALTER TABLE festivals ALTER COLUMN start_date SET NOT NULL"
    )

    execute(
      "ALTER TABLE festivals ALTER COLUMN end_date DROP NOT NULL",
      "ALTER TABLE festivals ALTER COLUMN end_date SET NOT NULL"
    )

    execute(
      "ALTER TABLE festivals ALTER COLUMN city DROP NOT NULL",
      "ALTER TABLE festivals ALTER COLUMN city SET NOT NULL"
    )

    execute(
      "ALTER TABLE festivals ALTER COLUMN state DROP NOT NULL",
      "ALTER TABLE festivals ALTER COLUMN state SET NOT NULL"
    )

    execute(
      "ALTER TABLE festivals ALTER COLUMN venue_id DROP NOT NULL",
      "ALTER TABLE festivals ALTER COLUMN venue_id SET NOT NULL"
    )
  end
end
