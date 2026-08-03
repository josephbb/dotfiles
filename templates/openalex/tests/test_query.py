"""Unit tests for [query.*] → OpenAlex param builders (stdlib unittest)."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from query import (  # noqa: E402
    corpus_query,
    format_min_citations_filter,
    format_publication_year_filter,
    format_search_terms,
    openalex_works_params,
)


def _minimal_cfg(**query_overrides):
    query = {
        "years": {"start": 2022},
        "works": {"type": "article"},
        "abstract": {"required": False},
        "journals": {"enabled": False, "ids": []},
        "citations": {"min": 0},
        "search": {
            "mode": "title_and_abstract.exact",
            "terms": ["ChatGPT", "large language model"],
        },
        "sort": {"by": "relevance_score:desc"},
        "download": {"per_page": 200},
        "domain": {"social_sciences": False},
    }
    for key, value in query_overrides.items():
        if isinstance(value, dict) and isinstance(query.get(key), dict):
            query[key] = {**query[key], **value}
        else:
            query[key] = value
    return {"query": query}


class QueryBuilderTests(unittest.TestCase):
    def test_year_open_range(self) -> None:
        self.assertEqual(format_publication_year_filter({"start": 2022}), "2022-")
        self.assertEqual(
            format_publication_year_filter({"start": 2022, "end": 2026}),
            "2022-2026",
        )

    def test_citations(self) -> None:
        self.assertEqual(format_min_citations_filter(1), ">0")
        self.assertEqual(format_min_citations_filter(2), ">1")
        q = corpus_query(_minimal_cfg(citations={"min": 0}))
        self.assertNotIn("cited_by_count", q["filter"])
        q2 = corpus_query(_minimal_cfg(citations={"min": 2}))
        self.assertEqual(q2["filter"]["cited_by_count"], ">1")

    def test_search_terms(self) -> None:
        self.assertEqual(
            format_search_terms(["Large Language Models", "ChatGPT", "LLM"]),
            '"Large Language Models" OR ChatGPT OR LLM',
        )

    def test_corpus_query_and_params(self) -> None:
        cfg = _minimal_cfg(
            journals={"enabled": True, "ids": ["S137773608", "S3880285"]},
            domain={"social_sciences": True},
        )
        query = corpus_query(cfg)
        self.assertEqual(query["filter"]["publication_year"], "2022-")
        self.assertEqual(query["filter"]["type"], "article")
        self.assertEqual(
            query["filter"]["primary_location.source.id"],
            "S137773608|S3880285",
        )
        self.assertEqual(query["filter"]["primary_topic.domain.id"], "2")
        self.assertNotIn("has_abstract", query["filter"])
        self.assertIn("search.title_and_abstract.exact", query)
        self.assertNotIn("search.title_and_abstract", query)

        params = openalex_works_params(query, per_page=50, cursor="*")
        self.assertEqual(params["per-page"], "50")
        self.assertEqual(params["cursor"], "*")
        self.assertEqual(params["sort"], "relevance_score:desc")
        self.assertIn("type:article", params["filter"])
        self.assertIn("primary_topic.domain.id:2", params["filter"])


if __name__ == "__main__":
    unittest.main()
