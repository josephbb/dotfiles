"""Build OpenAlex /works params from config.toml [query.*] sections.

Lean port of the query helpers from josephbb/LLMDiscourse — enough to express
years, type, journals, citations, search mode/terms, sort, and domain filters.
Disclosure / institutions / scrape live in the full project, not here.
"""

from __future__ import annotations

from typing import Any

# OpenAlex primary_topic.domain.id for Social Sciences
OPENALEX_SOCIAL_SCIENCES_DOMAIN_ID = "2"

SEARCH_PARAM_BY_MODE = {
    "title_and_abstract": "search.title_and_abstract",
    "title_and_abstract.exact": "search.title_and_abstract.exact",
    "fulltext": "search",
    "fulltext.exact": "search.exact",
}


def format_search_terms(terms: list[str]) -> str:
    """Join search terms into an OpenAlex OR query (for search.* params)."""
    formatted: list[str] = []
    for term in terms:
        cleaned = term.strip()
        if not cleaned:
            continue
        if " " in cleaned or "-" in cleaned:
            formatted.append(f'"{cleaned}"')
        else:
            formatted.append(cleaned)
    return " OR ".join(formatted)


def format_publication_year_filter(years: dict[str, Any]) -> str:
    """Format publication_year filter; omit end for an open range (e.g. 2022-)."""
    start = years["start"]
    end = years.get("end")
    if end is None:
        return f"{start}-"
    return f"{start}-{end}"


def format_min_citations_filter(min_citations: int) -> str:
    """Format cited_by_count for a minimum citation threshold."""
    if min_citations < 1:
        raise ValueError(f"min_citations must be >= 1, got {min_citations}")
    if min_citations == 1:
        return ">0"
    return f">{min_citations - 1}"


def corpus_query(cfg: dict[str, Any]) -> dict[str, Any]:
    """Build the primary OpenAlex Works query from config [query]."""
    query_config = cfg["query"]
    search_config = query_config["search"]
    terms = list(search_config["terms"])
    mode = search_config.get("mode", "title_and_abstract")

    filters: dict[str, str] = {
        "publication_year": format_publication_year_filter(query_config["years"]),
    }
    journals_cfg = query_config.get("journals", {})
    if journals_cfg.get("enabled", False):
        journal_ids = journals_cfg.get("ids") or []
        if journal_ids:
            filters["primary_location.source.id"] = "|".join(journal_ids)
    if works_type := query_config.get("works", {}).get("type"):
        filters["type"] = works_type
    if query_config.get("abstract", {}).get("required", False):
        filters["has_abstract"] = "true"
    if query_config.get("domain", {}).get("social_sciences", False):
        filters["primary_topic.domain.id"] = OPENALEX_SOCIAL_SCIENCES_DOMAIN_ID
    if (min_citations := query_config.get("citations", {}).get("min")) is not None:
        min_citations = int(min_citations)
        if min_citations >= 1:
            filters["cited_by_count"] = format_min_citations_filter(min_citations)

    result: dict[str, Any] = {
        "mode": mode,
        "terms": terms,
        "filter": filters,
    }
    if sort_by := query_config.get("sort", {}).get("by"):
        result["sort"] = sort_by

    if mode not in SEARCH_PARAM_BY_MODE:
        raise ValueError(
            f"Unsupported query.search.mode: {mode!r}. "
            f"Expected one of: {', '.join(sorted(SEARCH_PARAM_BY_MODE))}"
        )
    result[SEARCH_PARAM_BY_MODE[mode]] = format_search_terms(terms)
    return result


def openalex_works_params(
    query: dict[str, Any],
    *,
    per_page: int = 200,
    sort: str | None = None,
    cursor: str | None = None,
) -> dict[str, str]:
    """Build query-string parameters for GET /works."""
    params: dict[str, str] = {
        "filter": ",".join(f"{key}:{value}" for key, value in query["filter"].items()),
        "per-page": str(per_page),
    }
    for key, value in query.items():
        if key.startswith("search"):
            params[key] = value
    params["sort"] = sort or query.get("sort", "relevance_score:desc")
    if cursor is not None:
        params["cursor"] = cursor
    return params
