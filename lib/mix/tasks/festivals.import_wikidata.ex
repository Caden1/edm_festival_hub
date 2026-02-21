defmodule Mix.Tasks.Festivals.ImportWikidata do
  use Mix.Task

  @shortdoc "Imports a seed festival directory from Wikidata (WDQS)"

  @moduledoc """
  Imports a seed list of EDM festivals from Wikidata Query Service (WDQS).

  This task is designed to be:
  - Free/open-data friendly
  - Conservative (doesn't force dates/locations if unknown)
  - Polite to Wikimedia infra (descriptive User-Agent, simple rate limiting)

  ## Usage

      mix festivals.import_wikidata

  Options:

    * `--category`  Wikipedia category name (default: "Electronic music festivals in the United States")
    * `--page-size` Number of results per page (default: 200)
    * `--pages`     Number of pages to fetch (default: 1)
    * `--offset`    Offset for the first page (default: 0)
    * `--sleep-ms`  Sleep between pages (default: 1000)
    * `--dry-run`   Parse  count only; do not write to DB
    * `--user-agent` Override User-Agent (otherwise use WIKIDATA_USER_AGENT env var)

  Tip: Wikimedia asks that automated clients send a descriptive User-Agent.
  Set `WIKIDATA_USER_AGENT` in your shell, e.g.:

      export WIKIDATA_USER_AGENT='EDM Festival Hub (non-commercial; contact: you@example.com)'
  """

  alias EdmFestivalHub.Festivals.WikidataImporter

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          category: :string,
          page_size: :integer,
          pages: :integer,
          offset: :integer,
          sleep_ms: :integer,
          dry_run: :boolean,
          user_agent: :string
        ]
      )

    importer_opts =
      opts
      |> Enum.map(fn
        {:page_size, v} -> {:page_size, max(v, 1)}
        {:pages, v} -> {:pages, max(v, 1)}
        {:offset, v} -> {:offset, max(v, 0)}
        {:sleep_ms, v} -> {:sleep_ms, max(v, 0)}
        other -> other
      end)

    Mix.shell().info("Fetching festivals from WDQS…")

    case WikidataImporter.import(importer_opts) do
      {:ok, %{imported: imported, skipped: skipped, errors: errors}} ->
        Mix.shell().info("\nDone.")
        Mix.shell().info("Imported: #{imported}")
        Mix.shell().info("Skipped:  #{skipped}")
        Mix.shell().info("Errors:   #{errors}")

      {:error, reason} ->
        Mix.raise("Wikidata import failed: #{inspect(reason)}")
    end
  end
end
