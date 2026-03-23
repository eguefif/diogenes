import diogenes.{
  type Client, type Error, JsonError, UnexpectedHttpStatusCodeError,
  meilisearch_error_from_json,
}
import diogenes/sansio/settings.{type Locales, locale_to_string}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/http
import gleam/http/request.{type Request}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import internal/http_tooling.{create_base_request}

pub fn search_with_get(
  client: Client,
  index_uid,
  search_params: SearchParams,
  document_decoder: Decoder(document),
) -> #(
  Request(String),
  fn(Int, String) -> Result(SearchResponse(document), Error),
) {
  let request =
    create_base_request(client, "/indexes/" <> index_uid <> "/search")
    |> request.set_method(http.Get)
    |> request.set_query(search_params_to_query(search_params))

  let parser = fn(status: Int, body: String) {
    case status {
      200 ->
        case json.parse(body, search_response_decoder(document_decoder)) {
          Ok(response) -> Ok(response)
          Error(error) -> Error(JsonError(error))
        }
      401 | 404 -> Error(meilisearch_error_from_json(body))
      _ -> Error(UnexpectedHttpStatusCodeError(status, body))
    }
  }
  #(request, parser)
}

pub type SearchResponse(document) {
  SearchResponse(
    pagination: Pagination,
    hits: List(Hit(document)),
    query: String,
    processing_time_ms: Int,
    query_vector: Option(List(Float)),
    facet_distribution: Option(Dict(String, Dict(String, Int))),
    facet_stats: Option(Dict(String, FacetStat)),
  )
}

fn search_response_decoder(
  document_decoder: Decoder(document),
) -> Decoder(SearchResponse(document)) {
  use pagination <- decode.then(pagination_decoder())
  use hits <- decode.field("hits", decode.list(hit_decoder(document_decoder)))
  use query <- decode.field("query", decode.string)
  use processing_time_ms <- decode.field("processingTimeMs", decode.int)
  use query_vector <- decode.optional_field(
    "queryVector",
    None,
    decode.optional(decode.list(decode.float)),
  )
  use facet_distribution <- decode.optional_field(
    "facetDistribution",
    None,
    decode.optional(decode.dict(
      decode.string,
      decode.dict(decode.string, decode.int),
    )),
  )

  use facet_stats <- decode.optional_field(
    "facetStats",
    None,
    decode.optional(decode.dict(decode.string, facet_stat_decoder())),
  )
  decode.success(SearchResponse(
    pagination:,
    hits:,
    query:,
    processing_time_ms:,
    query_vector:,
    facet_distribution:,
    facet_stats:,
  ))
}

pub type FacetStat {
  FacetStat(min: Float, max: Float)
}

fn facet_stat_decoder() -> Decoder(FacetStat) {
  use min <- decode.field("min", decode.float)
  use max <- decode.field("max", decode.float)
  decode.success(FacetStat(min:, max:))
}

pub type Hit(document) {
  Hit(document: document, metadata: HitMetadata)
}

fn hit_decoder(
  document_decoder: Decoder(document),
) -> decode.Decoder(Hit(document)) {
  use document <- decode.then(document_decoder)
  use metadata <- decode.then(hit_metadata_decoder())
  decode.success(Hit(document:, metadata:))
}

pub type HitMetadata {
  HitMetadata(ranking_score: Option(Float))
}

fn hit_metadata_decoder() -> Decoder(HitMetadata) {
  use ranking_score <- decode.optional_field(
    "ranking_score",
    None,
    decode.optional(decode.float),
  )
  decode.success(HitMetadata(ranking_score:))
}

pub type Pagination {
  Offset(limit: Int, offset: Int, estimated_hits: Int)
  Page(hits_per_page: Int, page: Int, total_pages: Int, total_hits: Int)
  PaginationError
}

fn pagination_decoder() -> Decoder(Pagination) {
  let offset_decoder = {
    use limit <- decode.field("limit", decode.int)
    use offset <- decode.field("offset", decode.int)
    use estimated_hits <- decode.field("estimatedTotalHits", decode.int)
    decode.success(Offset(limit:, offset:, estimated_hits:))
  }
  let page_decoder = {
    use hits_per_page <- decode.field("hitsPerPage", decode.int)
    use page <- decode.field("page", decode.int)
    use total_pages <- decode.field("totalPages", decode.int)
    use total_hits <- decode.field("totalHits", decode.int)
    decode.success(Page(hits_per_page:, page:, total_pages:, total_hits:))
  }
  decode.one_of(offset_decoder, [page_decoder])
}

pub fn default_search_params() -> SearchParams {
  SearchParams(
    q: None,
    offset: Some(0),
    limit: Some(20),
    page: None,
    hits_per_page: None,
    attributes_to_retrieve: Default,
    attributes_to_crop: Default,
    crop_length: None,
    crop_marker: None,
    attributes_to_highlight: Default,
    highlight_pre_tag: None,
    highlight_post_tag: None,
    show_matches_position: False,
    filter: ArrayString([]),
    sort: None,
    distinct: None,
    facets: Default,
    matching_strategy: Last,
    attributes_to_search_on: Default,
    ranking_score_threshold: None,
    locales: None,
    hybrid: None,
    vector: [],
    retrieve_vectors: False,
    personalize: None,
    use_network: None,
    show_ranking_score: False,
    show_ranking_score_details: False,
  )
}

pub type SearchParams {
  SearchParams(
    q: Option(String),
    offset: Option(Int),
    limit: Option(Int),
    page: Option(Int),
    hits_per_page: Option(Int),
    attributes_to_retrieve: Selection,
    attributes_to_crop: Selection,
    crop_length: Option(Int),
    crop_marker: Option(String),
    attributes_to_highlight: Selection,
    highlight_pre_tag: Option(String),
    highlight_post_tag: Option(String),
    show_matches_position: Bool,
    filter: SearchFilter,
    sort: Option(List(String)),
    distinct: Option(String),
    facets: Selection,
    matching_strategy: MatchingStrategy,
    attributes_to_search_on: Selection,
    ranking_score_threshold: Option(Float),
    locales: Option(List(Locales)),
    hybrid: Option(HybridParams),
    vector: List(Float),
    retrieve_vectors: Bool,
    // TODO: media
    personalize: Option(PersonalizeParams),
    use_network: Option(Bool),
    show_ranking_score: Bool,
    show_ranking_score_details: Bool,
  )
}

pub type Selection {
  All
  Select(List(String))
  Default
}

pub type PersonalizeParams {
  PersonalizeParams(user_context: String)
}

pub type HybridParams {
  HybridParams(embedder: String, semantic_ratio: Float)
}

pub type SearchFilter {
  SingleString(String)
  ArrayString(List(String))
  Geo
  // TODO
}

pub type MatchingStrategy {
  Last
  AllStrategy
  Frequency
}

fn search_params_to_query(params: SearchParams) -> List(#(String, String)) {
  let bool_to_string = fn(b) {
    case b {
      True -> "true"
      False -> "false"
    }
  }

  let required = [
    #("offset", case params.offset {
      Some(value) -> int.to_string(value)
      None -> "0"
    }),
    #("limit", case params.limit {
      Some(value) -> int.to_string(value)
      None -> "20"
    }),
    #("cropLength", case params.crop_length {
      Some(value) -> int.to_string(value)
      None -> "10"
    }),
    #("cropMarker", case params.crop_marker {
      Some(value) -> value
      None -> "..."
    }),
    #(
      "showMatchesPosition",
      bool.to_string(params.show_matches_position) |> string.lowercase,
    ),
    #("matchingStrategy", matching_strategy_to_string(params.matching_strategy)),
    #(
      "retrieveVectors",
      bool.to_string(params.retrieve_vectors) |> string.lowercase,
    ),
    #(
      "showRankingScore",
      bool.to_string(params.retrieve_vectors) |> string.lowercase,
    ),
    #(
      "showRankingScore",
      bool.to_string(params.show_ranking_score) |> string.lowercase,
    ),
    #(
      "showRankingScoreDetails",
      bool.to_string(params.show_ranking_score_details) |> string.lowercase,
    ),
    #("filter", search_filter_to_string(params.filter)),
  ]

  let optional =
    [
      option.map(params.q, fn(v) { #("q", v) }),

      option.map(params.page, fn(v) { #("page", int.to_string(v)) }),
      option.map(params.hits_per_page, fn(v) {
        #("hitsPerPage", int.to_string(v))
      }),

      case params.attributes_to_retrieve {
        All -> Some(#("attributesToRetrieve", "[*]"))
        Select(selection) ->
          Some(#("attributesToRetrieve", string.join(selection, ",")))
        Default -> None
      },
      case params.attributes_to_crop {
        All -> Some(#("attributesToCrop", "[*]"))
        Select(selection) ->
          Some(#("attributesToCrop", string.join(selection, ",")))
        Default -> None
      },
      case params.attributes_to_crop {
        All -> Some(#("attributesToHighlight", "[*]"))
        Select(selection) ->
          Some(#("attributesTohighlight", string.join(selection, ",")))
        Default -> None
      },
      option.map(params.highlight_pre_tag, fn(v) { #("highLightPreTag", v) }),
      option.map(params.highlight_post_tag, fn(v) { #("highLightPostTag", v) }),
      option.map(params.sort, fn(v) { #("sort", string.join(v, ",")) }),
      option.map(params.distinct, fn(v) { #("distinct", v) }),
      case params.facets {
        All -> Some(#("facets", "[*]"))
        Select(selection) -> Some(#("facets", string.join(selection, ",")))
        Default -> None
      },
      case params.attributes_to_search_on {
        All -> Some(#("facets", "[*]"))
        Select(selection) -> Some(#("facets", string.join(selection, ",")))
        Default -> None
      },
      option.map(params.ranking_score_threshold, fn(v) {
        #("rankingScoreThreshold", float.to_string(v))
      }),
      option.map(params.locales, fn(v) {
        #("locales", string.join(list.map(v, locale_to_string), ","))
      }),
      option.map(params.hybrid, fn(v) { #("hybridEmbedder", v.embedder) }),
      option.map(params.hybrid, fn(v) {
        #("hybridSemanticRatio", float.to_string(v.semantic_ratio))
      }),
      option.map(params.personalize, fn(v) {
        #("personalizeUserContext", v.user_context)
      }),
      option.map(params.use_network, fn(v) {
        #("useNetwork", bool_to_string(v))
      }),
      case params.vector {
        [] -> None
        _ ->
          Some(#(
            "vector",
            "["
              <> string.join(list.map(params.vector, float.to_string), ",")
              <> "]",
          ))
      },
    ]
    |> list.filter_map(fn(opt) {
      case opt {
        Some(pair) -> Ok(pair)
        None -> Error(Nil)
      }
    })

  list.flatten([required, optional])
}

fn matching_strategy_to_string(strategy: MatchingStrategy) -> String {
  case strategy {
    Last -> "last"
    AllStrategy -> "all"
    Frequency -> "frequency"
  }
}

fn search_filter_to_string(filter: SearchFilter) -> String {
  case filter {
    SingleString(s) -> s
    ArrayString(parts) -> string.join(parts, " AND ")
    Geo -> ""
  }
}
