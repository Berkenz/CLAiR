"""Unit tests for Tavily search trigger logic (no live API calls)."""

from app.services.tavily_service import (
    RealtimeSearchPlan,
    _is_legal_news_query,
    _is_time_sensitive,
    _plan_for_realtime_intent,
    _resolve_search_plan,
    _should_search_law,
    _should_search_legal_news,
    heuristic_needs_realtime_search,
)


def test_time_sensitive_triggers_law_search():
    assert _is_time_sensitive("What is the latest RA on data privacy?")
    assert _should_search_law("latest republic act on cybercrime", rag_chunk_count=3)


def test_empty_rag_long_query_triggers_law_search():
    q = "How do I file a small claims case against my landlord in Cebu?"
    assert _should_search_law(q, rag_chunk_count=0)


def test_short_query_no_rag_does_not_trigger_law_search():
    assert not _should_search_law("tenant rights", rag_chunk_count=0)


def test_legal_news_keywords():
    assert _is_legal_news_query("What is the latest legal news about divorce?")
    assert _is_legal_news_query("Any supreme court news this week?")
    assert _should_search_legal_news("recent news on labor law")


def test_time_sensitive_with_news_triggers_legal_news():
    assert _should_search_legal_news("latest news on the new tax law")


def test_static_law_question_no_news_search():
    assert not _should_search_legal_news("What is estafa under the RPC?")
    assert not _is_legal_news_query("Can my landlord evict me without notice?")


def test_heuristic_arrest_question_triggers_realtime():
    q = "is bato dela rosa gonna be arrested"
    assert heuristic_needs_realtime_search(q)
    plan = _plan_for_realtime_intent(q, rag_chunk_count=5, source="heuristic")
    assert plan.search_news is True
    assert plan.search_law is False


def test_heuristic_latest_status_triggers_news():
    q = "what is the current status of the ICC case against duterte"
    assert heuristic_needs_realtime_search(q)
    plan = _plan_for_realtime_intent(q, 0, source="heuristic")
    assert plan.search_news is True


def test_resolve_plan_uses_realtime_over_keywords():
    q = "is bato dela rosa gonna be arrested"
    plan = _resolve_search_plan(
        q,
        3,
        RealtimeSearchPlan(search_news=True, search_law=False, source="heuristic"),
    )
    assert plan.search_news is True
    assert plan.search_law is False


def test_estafa_no_heuristic():
    assert not heuristic_needs_realtime_search("What is estafa under the RPC?")
