from app.services.scope_router_service import _parse_scope_decision, is_greeting_or_small_talk


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


def test_greeting_or_small_talk():
    assert is_greeting_or_small_talk("hey clair")
    assert is_greeting_or_small_talk("Hey CLAiR!")
    assert is_greeting_or_small_talk("hi there")
    assert is_greeting_or_small_talk("kumusta po")
    assert is_greeting_or_small_talk("salamat")
    assert not is_greeting_or_small_talk("what are my tenant rights")
    assert not is_greeting_or_small_talk(
        "write me a python script for binary search"
    )
