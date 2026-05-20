from datetime import date

from app.services.vector_service import (
    _combined_rank_score,
    _expand_retrieval_query,
    _is_caselaw_query,
    _metadata_search_terms,
    _parse_date_enacted,
    _postgres_ra_pd_number_pattern,
    _recency_score,
    _rerank_by_recency,
    _rerank_candidates,
    _stored_number_cites_law,
    extract_cited_law_numbers,
)


def test_parse_date_enacted_formats():
    assert _parse_date_enacted("2018-06-11") == date(2018, 6, 11)
    assert _parse_date_enacted("June 11, 2018") == date(2018, 6, 11)
    assert _parse_date_enacted("April 10, 1990") == date(1990, 4, 10)
    assert _parse_date_enacted("Promulgated 2024") == date(2024, 6, 15)
    assert _parse_date_enacted("") is None
    assert _parse_date_enacted(None) is None


def test_recency_score_orders_years():
    old = _recency_score(date(1974, 1, 1), today=date(2026, 5, 1))
    new = _recency_score(date(2018, 1, 1), today=date(2026, 5, 1))
    assert new > old
    assert _recency_score(None) == 0.45


def test_rerank_prefers_newer_when_similarity_close():
    candidates = [
        {
            "text": "old",
            "similarity": 0.72,
            "date_enacted": "January 1, 1974",
            "number": "PD 442",
        },
        {
            "text": "new",
            "similarity": 0.70,
            "date_enacted": "2018-06-11",
            "number": "RA 11032",
        },
    ]
    ranked = _rerank_by_recency(candidates, top_k=1)
    assert ranked[0]["number"] == "RA 11032"


def test_rerank_keeps_higher_similarity_when_gap_large():
    candidates = [
        {
            "text": "old",
            "similarity": 0.90,
            "date_enacted": "January 1, 1974",
            "number": "PD 442",
        },
        {
            "text": "new",
            "similarity": 0.62,
            "date_enacted": "2018-06-11",
            "number": "RA 11032",
        },
    ]
    ranked = _rerank_by_recency(candidates, top_k=1)
    assert ranked[0]["number"] == "PD 442"


def test_combined_score_blend():
    assert _combined_rank_score(1.0, 1.0) > _combined_rank_score(1.0, 0.0)


def test_expand_retrieval_query_bullying():
    expanded = _expand_retrieval_query("I need help someone bullied me")
    assert "10627" in expanded
    assert "Anti-Bullying" in expanded


def test_extract_cited_law_numbers():
    text = "under **Republic Act No. 10627**, also known as the Anti-Bullying Act"
    assert extract_cited_law_numbers(text) == ["10627"]


def test_extract_cited_law_numbers_bare_ra():
    text = "This involves RA 10173 and RA 9972."
    assert extract_cited_law_numbers(text) == ["10173", "9972"]


def test_metadata_search_terms_skip_vague_words():
    assert "concern" not in _metadata_search_terms("I have a legal concern")


def test_confidence_filter_keeps_exact_statute_lookup():
    from app.config import settings
    from app.services.vector_service import _filter_by_retrieval_confidence

    chunks = [
        {
            "number": "R.A. No. 7610",
            "similarity": 0.72,
            "_exact_statute_lookup": True,
            "text": "child abuse",
        },
    ]
    out = _filter_by_retrieval_confidence(chunks)
    assert len(out) == 1
    assert float(out[0]["similarity"]) >= settings.RAG_MIN_TOP_SIMILARITY


def test_is_caselaw_query():
    assert _is_caselaw_query("What did the Supreme Court rule in GR No 123456?")
    assert not _is_caselaw_query("What is the maternity leave under RA 11210?")


def test_stored_number_cites_law_not_gr_substring():
    assert _stored_number_cites_law("R.A. No. 7610", "7610")
    assert not _stored_number_cites_law("G.R. No. 117610", "7610")
    assert not _stored_number_cites_law("GR 117610", "7610")


def test_postgres_ra_pd_pattern_avoids_gr_substring():
    import re

    from app.services.vector_service import _ra_pd_number_regex

    pat = _ra_pd_number_regex("7610")
    assert re.search(pat, "R.A. No. 7610")
    assert not re.search(pat, "G.R. No. 117610")


def test_expand_retrieval_query_child_abuse():
    expanded = _expand_retrieval_query(
        "What RA is the protection of kids against abuse"
    )
    assert "7610" in expanded


def test_metadata_search_terms_child_abuse_includes_7610():
    terms = _metadata_search_terms("protection of kids against abuse")
    assert "7610" in terms


def test_rerank_prefers_statutes_over_sc_for_general_question():
    candidates = [
        {
            "text": "sc",
            "similarity": 0.78,
            "date_enacted": "2024-01-01",
            "number": "G.R. No. 999",
            "category": "supreme_court_decisions",
        },
        {
            "text": "ra",
            "similarity": 0.76,
            "date_enacted": "2019-06-11",
            "number": "RA 11210",
            "category": "republic_acts",
        },
        {
            "text": "sc2",
            "similarity": 0.77,
            "date_enacted": "2023-01-01",
            "number": "G.R. No. 998",
            "category": "supreme_court_decisions",
        },
    ]
    ranked = _rerank_candidates(
        candidates,
        top_k=2,
        query="What is maternity leave for employees?",
    )
    assert ranked[0]["category"] == "republic_acts"
    assert sum(1 for c in ranked if c["category"] == "supreme_court_decisions") <= 1
