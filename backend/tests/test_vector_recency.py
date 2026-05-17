from datetime import date

from app.services.vector_service import (
    _combined_rank_score,
    _parse_date_enacted,
    _recency_score,
    _rerank_by_recency,
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
