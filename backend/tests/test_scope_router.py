from app.services.scope_router_service import (
    ScopeTier,
    _parse_scope_tier,
    is_assistant_meta_question,
    is_clearly_off_topic_message,
    is_greeting_or_small_talk,
    off_topic_category,
)


def test_parse_scope_tiers():
    assert _parse_scope_tier("IN_SCOPE") == ScopeTier.LEGAL
    assert _parse_scope_tier("in scope") == ScopeTier.LEGAL
    assert _parse_scope_tier("PIVOT") == ScopeTier.PIVOT
    assert _parse_scope_tier("OUT_OF_SCOPE") == ScopeTier.REJECT
    assert _parse_scope_tier("out of scope") == ScopeTier.REJECT
    assert _parse_scope_tier("") is None
    assert _parse_scope_tier("maybe") is None


def test_off_topic_category():
    assert off_topic_category("1+1") == "math"
    assert off_topic_category("write python code") == "coding"
    assert off_topic_category("who won the game") == "general"


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


def test_assistant_meta_questions_in_scope():
    assert is_assistant_meta_question("do you have access to recent news")
    assert is_assistant_meta_question("Do you have access to recent legal news?")
    assert is_assistant_meta_question("what can you do")
    assert is_assistant_meta_question("what is CLAiR")
    assert is_assistant_meta_question("how does CLAiR work")
    assert not is_assistant_meta_question("what are my rights as a tenant")
    assert not is_assistant_meta_question("write me a python script for binary search")
    assert not is_assistant_meta_question("can you help me file an annulment")


def test_clearly_off_topic_math_and_coding():
    assert is_clearly_off_topic_message("1+1")
    assert is_clearly_off_topic_message("1 + 1")
    assert is_clearly_off_topic_message("what is 1+1")
    assert is_clearly_off_topic_message("2 * 3")
    assert is_clearly_off_topic_message("write me a python script")
    assert not is_clearly_off_topic_message("do you have access to recent news")
    assert not is_clearly_off_topic_message("what are my rights as a tenant")
    assert not is_clearly_off_topic_message("penalty under RA 7610")
