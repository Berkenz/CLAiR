import re

from app.services.rag_relevance_service import _parse_verdicts
from app.services.vector_service import (
    _ra_pd_number_regex,
    _stored_number_cites_law,
    extract_cited_law_numbers,
    finalize_rag_sources_for_display,
)


def test_parse_verdicts():
    raw = "1 YES\n2 NO\n3 YES"
    v = _parse_verdicts(raw, 3)
    assert v[1] is True
    assert v[2] is False
    assert v[3] is True


def test_finalize_rag_sources_only_cited():
    cited_only = [
        {
            "number": "G.R. No. 117610",
            "title": "Wrong case",
            "similarity": 0.78,
            "source_url": "https://example.com/gr",
        },
        {
            "number": "R.A. No. 7610",
            "title": "Child abuse",
            "similarity": 0.76,
            "source_url": "https://example.com/ra7610",
        },
    ]
    reply = "This is governed by **Republic Act No. 7610**."
    # finalize is async — test sync helper logic via citation filter
    cited = extract_cited_law_numbers(reply)
    assert cited == ["7610"]
    matching = [
        s
        for s in cited_only
        if any(_stored_number_cites_law(s.get("number") or "", n) for n in cited)
    ]
    assert len(matching) == 1
    assert "7610" in (matching[0].get("number") or "")


def test_gr_not_matched_as_ra_7610():
    assert not _stored_number_cites_law("G.R. No. 117610", "7610")
    pat = _ra_pd_number_regex("7610")
    assert not re.search(pat, "G.R. No. 117610")
