defmodule EdmFestivalHub.Festivals.WikidataImporter do
  @moduledoc """
  Import a *directory seed list* of EDM festivals from Wikidata Query Service (WDQS).

  This is intentionally conservative:
  - Uses open data (Wikidata) as a seed list
  - Stores provenance-friendly identifiers (`wikidata_qid`)
  - Tries to avoid forcing dates/locations when unknown

  The default query pulls items from the English Wikipedia category:
  "Electronic music festivals in the United States" and then maps those pages
  back to Wikidata items.
  """

  alias EdmFestivalHub.Festivals
  alias EdmFestivalHub.Festivals.Festival

  @endpoint "https://query.wikidata.org/sparql"
  @default_category "Electronic music festivals in the United States"

  @type import_opt ::
          {:category, String.t()}
          | {:page_size, pos_integer()}
          | {:pages, pos_integer()}
          | {:offset, non_neg_integer()}
          | {:sleep_ms, non_neg_integer()}
          | {:user_agent, String.t()}
          | {:dry_run, boolean()}

  @spec import([import_opt()]) ::
          {:ok,
           %{imported: non_neg_integer(), skipped: non_neg_integer(), errors: non_neg_integer()}}
          | {:error, term()}
  def import(opts \\ []) do
    category = Keyword.get(opts, :category, @default_category)
    page_size = Keyword.get(opts, :page_size, 200)
    pages = Keyword.get(opts, :pages, 1)
    offset = Keyword.get(opts, :offset, 0)
    sleep_ms = Keyword.get(opts, :sleep_ms, 1000)
    user_agent = Keyword.get(opts, :user_agent, default_user_agent())
    dry_run? = Keyword.get(opts, :dry_run, false)

    acc = %{imported: 0, skipped: 0, errors: 0}

    0..(pages - 1)
    |> Enum.reduce_while({:ok, acc}, fn page, {:ok, acc} ->
      current_offset = offset + page * page_size
      sparql = sparql_query(category, page_size, current_offset)

      case fetch_json(sparql, user_agent: user_agent) do
        {:ok, %{} = body} ->
          rows = parse_rows(body)

          {imported, skipped, errors} =
            rows
            |> Enum.reduce({0, 0, 0}, fn row, {i, s, e} ->
              case to_import_attrs(row) do
                {:skip, _reason} ->
                  {i, s + 1, e}

                {:ok, attrs} ->
                  if dry_run? do
                    {i + 1, s, e}
                  else
                    case Festivals.upsert_wikidata_festival(attrs) do
                      {:ok, _festival} -> {i + 1, s, e}
                      {:error, _changeset} -> {i, s, e + 1}
                    end
                  end
              end
            end)

          acc = %{
            imported: acc.imported + imported,
            skipped: acc.skipped + skipped,
            errors: acc.errors + errors
          }

          if page < pages - 1 and sleep_ms > 0 do
            Process.sleep(sleep_ms)
          end

          {:cont, {:ok, acc}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp default_user_agent do
    # Wikimedia asks clients to send a descriptive User-Agent with contact info.
    # Prefer setting WIKIDATA_USER_AGENT in your shell.
    vsn =
      case Application.spec(:edm_festival_hub, :vsn) do
        nil -> "dev"
        other -> to_string(other)
      end

    System.get_env("WIKIDATA_USER_AGENT") ||
      "EdmFestivalHub/#{vsn} (non-commercial; contact: set WIKIDATA_USER_AGENT; mix festivals.import_wikidata)"
  end

  defp sparql_query(category, limit, offset) do
    # NOTE: WDQS provides a MWAPI bridge that lets us use a Wikipedia category
    # as a "seed list" without scraping.
    """
    PREFIX mwapi: <https://www.mediawiki.org/ontology#API/>
    PREFIX wikibase: <http://wikiba.se/ontology#>
    PREFIX bd: <http://www.bigdata.com/rdf#>
    PREFIX schema: <http://schema.org/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>

    SELECT ?item ?itemLabel ?officialWebsite ?location ?locationLabel ?locationCoord ?startTime ?endTime WHERE {
      SERVICE wikibase:mwapi {
        bd:serviceParam wikibase:api "Generator" .
        bd:serviceParam wikibase:endpoint "en.wikipedia.org" .
        bd:serviceParam mwapi:generator "categorymembers" .
        bd:serviceParam mwapi:gcmtitle "Category:#{escape_category(category)}" .
        bd:serviceParam mwapi:gcmtype "page" .
        bd:serviceParam mwapi:gcmlimit "max" .
        ?title wikibase:apiOutput mwapi:title .
      }

      ?article schema:about ?item ;
               schema:isPartOf <https://en.wikipedia.org/> ;
               schema:name ?title .

      OPTIONAL { ?item wdt:P856 ?officialWebsite . }
      OPTIONAL { ?item wdt:P276 ?location . }
      OPTIONAL { ?location wdt:P625 ?locationCoord . }
      OPTIONAL { ?item wdt:P580 ?startTime . }
      OPTIONAL { ?item wdt:P582 ?endTime . }

      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    ORDER BY ?itemLabel
    LIMIT #{limit}
    OFFSET #{offset}
    """
  end

  defp escape_category(category) do
    category
    |> String.replace("\"", "\\\"")
  end

  defp fetch_json(sparql, opts) do
    user_agent = Keyword.fetch!(opts, :user_agent)

    req_opts = [
      url: @endpoint,
      params: [format: "json", query: sparql],
      headers: [
        {"accept", "application/sparql-results+json"},
        {"user-agent", user_agent}
      ]
    ]

    retry(fun: fn -> Req.get(req_opts) end, attempts: 3)
  end

  defp retry(fun: fun, attempts: attempts) when attempts > 0 do
    case fun.() do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, decode_json(body)}

      {:ok, %Req.Response{status: 429, headers: headers}} ->
        sleep_ms = retry_after_ms(headers)
        Process.sleep(sleep_ms)
        retry(fun: fun, attempts: attempts - 1)

      {:ok, %Req.Response{status: status, body: body}} when status in 500..599 ->
        _ = body
        Process.sleep(1000)
        retry(fun: fun, attempts: attempts - 1)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp retry(fun: _fun, attempts: 0) do
    {:error, :too_many_retries}
  end

  defp retry_after_ms(headers) do
    # Retry-After is typically in seconds.
    headers
    |> Enum.find_value(1000, fn
      {"retry-after", value} -> parse_retry_after(value)
      {"Retry-After", value} -> parse_retry_after(value)
      _ -> nil
    end)
  end

  defp parse_retry_after(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {seconds, _} when seconds >= 0 -> seconds * 1000
      _ -> 1000
    end
  end

  defp decode_json(body) when is_map(body), do: body

  defp decode_json(body) when is_binary(body) do
    Jason.decode!(body)
  end

  defp parse_rows(%{"results" => %{"bindings" => bindings}}) when is_list(bindings), do: bindings
  defp parse_rows(_), do: []

  defp to_import_attrs(binding) when is_map(binding) do
    qid = binding |> get_in(["item", "value"]) |> qid_from_uri()
    name = get_in(binding, ["itemLabel", "value"])
    official_url = get_in(binding, ["officialWebsite", "value"])

    {start_date, end_date} =
      {get_in(binding, ["startTime", "value"]), get_in(binding, ["endTime", "value"])}
      |> parse_and_sanitize_dates()

    venue =
      case {get_in(binding, ["location", "value"]) |> qid_from_uri(),
            get_in(binding, ["locationLabel", "value"])} do
        {venue_qid, venue_name}
        when is_binary(venue_qid) and venue_qid != "" and is_binary(venue_name) and
               venue_name != "" ->
          {lat, lon} = parse_point(get_in(binding, ["locationCoord", "value"]))

          %{
            wikidata_qid: venue_qid,
            name: venue_name,
            latitude: lat,
            longitude: lon
          }

        _ ->
          nil
      end

    cond do
      not (is_binary(qid) and qid != "") ->
        {:skip, :missing_qid}

      not (is_binary(name) and String.trim(name) != "") ->
        {:skip, :missing_name}

      not (is_binary(official_url) and String.trim(official_url) != "") ->
        {:skip, :missing_official_url}

      true ->
        slug = Festival.slugify("#{name} #{qid}")

        {:ok,
         %{
           wikidata_qid: qid,
           name: name,
           slug: slug,
           official_url: official_url,
           start_date: start_date,
           end_date: end_date,
           venue: venue,
           verified_at: DateTime.utc_now()
         }}
    end
  end

  defp qid_from_uri(nil), do: nil

  defp qid_from_uri(uri) when is_binary(uri) do
    uri
    |> String.trim()
    |> String.split("/")
    |> List.last()
    |> case do
      "" -> nil
      other -> other
    end
  end

  defp parse_point(nil), do: {nil, nil}

  defp parse_point(point) when is_binary(point) do
    # WDQS encodes coordinates as: "Point(LON LAT)"
    case Regex.run(~r/^Point\(([-0-9\.]+)\s+([-0-9\.]+)\)$/i, String.trim(point)) do
      [_, lon, lat] ->
        {parse_float(lat), parse_float(lon)}

      _ ->
        {nil, nil}
    end
  end

  defp parse_float(nil), do: nil

  defp parse_float(str) when is_binary(str) do
    case Float.parse(str) do
      {f, _} -> f
      _ -> nil
    end
  end

  defp parse_and_sanitize_dates({start_raw, end_raw}) do
    today = Date.utc_today()

    start_date = parse_date(start_raw)
    end_date = parse_date(end_raw)

    start_date = sanitize_date_window(start_date, today)
    end_date = sanitize_date_window(end_date, today)

    end_date =
      cond do
        is_nil(start_date) -> nil
        is_nil(end_date) -> start_date
        Date.compare(end_date, start_date) == :lt -> start_date
        true -> end_date
      end

    {start_date, end_date}
  end

  defp sanitize_date_window(nil, _today), do: nil

  defp sanitize_date_window(%Date{} = date, %Date{} = today) do
    # Heuristic: keep only dates that look like a specific edition rather than
    # "inception" / historic metadata on the series.
    # Default window: within the last 30 days and next ~2 years.
    diff = Date.diff(date, today)

    if diff >= -30 and diff <= 730 do
      date
    else
      nil
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(value) when is_binary(value) do
    value = String.trim(value)

    cond do
      value == "" ->
        nil

      String.contains?(value, "T") ->
        case DateTime.from_iso8601(value) do
          {:ok, dt, _offset} -> DateTime.to_date(dt)
          _ -> nil
        end

      true ->
        case Date.from_iso8601(value) do
          {:ok, d} -> d
          _ -> nil
        end
    end
  end
end
