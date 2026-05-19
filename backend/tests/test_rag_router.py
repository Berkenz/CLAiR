from app.services.rag_router_service import _parse_router_decision
from app.services.vector_service import _filter_by_retrieval_confidence


def test_parse_router_yes():
    assert _parse_router_decision("YES") is True
    assert _parse_router_decision("yes") is True
    assert _parse_router_decision("YES.") is True


def test_parse_router_no():
    assert _parse_router_decision("NO") is False
    assert _parse_router_decision("no") is False


def test_parse_router_unparseable():
    assert _parse_router_decision("") is None
    assert _parse_router_decision("maybe") is None


def test_filter_by_retrieval_confidence():
    weak = [{"similarity": 0.68, "number": "RA 1"}]
    assert _filter_by_retrieval_confidence(weak) == []

    strong = [
        {"similarity": 0.75, "number": "RA 1"},
        {"similarity": 0.73, "number": "RA 2"},
    ]
    out = _filter_by_retrieval_confidence(strong)
    assert len(out) == 2
