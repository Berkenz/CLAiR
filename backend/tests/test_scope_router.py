from app.services.scope_router_service import _parse_scope_decision


def test_parse_scope_in_scope():
    assert _parse_scope_decision("IN_SCOPE") is True
    assert _parse_scope_decision("in scope") is True
    assert _parse_scope_decision("IN-SCOPE") is True


def test_parse_scope_out_of_scope():
    assert _parse_scope_decision("OUT_OF_SCOPE") is False
    assert _parse_scope_decision("out of scope") is False
    assert _parse_scope_decision("OUT-OF-SCOPE") is False


def test_parse_scope_unparseable():
    assert _parse_scope_decision("") is None
    assert _parse_scope_decision("maybe") is None
