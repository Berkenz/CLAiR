#!/usr/bin/env python3
"""
Scraper for SEC (Securities and Exchange Commission) Philippines issuances.

Covers:
  - Memorandum Circulars  (MC)
  - SEC Opinions
  - SEC Notices / Advisories

Primary source: https://www.sec.gov.ph
Fallback / supplement: https://lawphil.net (hosts some SEC issuances in plain text)

URL patterns (sec.gov.ph):
  MCs:      /memorandum-circulars/
  Opinions: /opinions/
  Notices:  /notices/

Usage:
    python scrape_sec.py                       # scrape all SEC issuance types
    python scrape_sec.py --category mc         # only Memorandum Circulars
    python scrape_sec.py --category opinions   # only SEC Opinions
    python scrape_sec.py --category notices    # only Notices
    python scrape_sec.py --limit 20            # first 20 per category (testing)
"""

import argparse
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import (
    CATEGORIES,
    SEC_BASE,
    LAWPHIL_BASE,
)
from utils import (
    get_session,
    fetch_page,
    polite_sleep,
    clean_text,
    slugify,
    save_law_json,
    load_existing_ids,
    build_law_record,
    logger,
)

# ── Category map exposed to scrape_all.py ─────────────────────────────────────
CATEGORY_MAP = {
    "mc":       "sec_memorandum_circulars",
    "opinions": "sec_opinions",
    "notices":  "sec_notices",
}

# ── Index paths on sec.gov.ph ─────────────────────────────────────────────────
# The portal uses WordPress-style paginated archives.
SEC_INDEX = {
    "sec_memorandum_circulars": "/memorandum-circulars/",
    "sec_opinions":             "/opinions/",
    "sec_notices":              "/sec-notices/",
}

# Lawphil mirrors some older SEC MCs under /sec/
LAWPHIL_SEC_INDEX = {
    "sec_memorandum_circulars": "/sec/",
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def _iter_wp_pages(session, base_url: str):
    """
    Yield HTML from paginated WordPress archive pages (?page=N).
    Stops when a page returns no list items or a 404.
    """
    page = 1
    while True:
        url = base_url if page == 1 else f"{base_url}page/{page}/"
        logger.info("  Fetching index page %d: %s", page, url)
        html = fetch_page(session, url)
        if not html:
            break
        soup = BeautifulSoup(html, "lxml")
        # WordPress list articles or table rows
        items = (
            soup.select("article.post")
            or soup.select("table tbody tr")
            or soup.select("ul.issuances-list li")
            or soup.select(".entry-content li")
        )
        if not items:
            break
        yield html, soup, items
        # Check for a "next page" link
        next_link = soup.select_one("a.next.page-numbers") or soup.select_one(".nav-next a")
        if not next_link:
            break
        page += 1
        polite_sleep()


def _extract_links_from_soup(soup, base_url: str, pattern: re.Pattern | None = None) -> list[tuple[str, str]]:
    """
    Return (absolute_url, link_text) pairs from <a> tags, optionally filtered
    by a regex pattern against the href.
    """
    results = []
    seen = set()
    for a in soup.find_all("a", href=True):
        href = a["href"]
        abs_url = urljoin(base_url, href)
        if abs_url in seen:
            continue
        if pattern and not pattern.search(href):
            continue
        seen.add(abs_url)
        results.append((abs_url, a.get_text(strip=True)))
    return results


# ── Index fetchers ────────────────────────────────────────────────────────────

def fetch_index_sec(session, category: str) -> list[dict]:
    """
    Scrape the sec.gov.ph portal index for a given category.
    Returns list of dicts: {url, citation, title, date}
    """
    index_path = SEC_INDEX.get(category)
    if not index_path:
        return []

    base_url = f"{SEC_BASE}{index_path}"
    entries = []

    for html, soup, items in _iter_wp_pages(session, base_url):
        for item in items:
            # WordPress article card
            title_el = item.select_one("h2.entry-title a") or item.select_one("h3 a") or item.select_one("a")
            if not title_el:
                continue
            title = title_el.get_text(strip=True)
            url = urljoin(base_url, title_el.get("href", ""))

            date_el = item.select_one("time") or item.select_one(".entry-date") or item.select_one(".date")
            date = date_el.get("datetime", "") or (date_el.get_text(strip=True) if date_el else "")

            # Try to extract the issuance number from the title
            # e.g. "SEC Memorandum Circular No. 3, Series of 2023"
            num_match = re.search(
                r"(?:Memorandum Circular|Opinion|Notice|Advisory|MC|No\.?)\s*([\w\-\.]+)",
                title, re.IGNORECASE,
            )
            citation = num_match.group(0) if num_match else title[:60]

            entries.append({"url": url, "citation": citation, "title": title, "date": date})

    logger.info("sec.gov.ph index → %d entries for %s", len(entries), category)
    return entries


def fetch_index_lawphil_sec(session, category: str) -> list[dict]:
    """
    Scrape lawphil.net/sec/ as a supplement for older SEC MCs.
    """
    index_path = LAWPHIL_SEC_INDEX.get(category)
    if not index_path:
        return []

    url = f"{LAWPHIL_BASE}{index_path}"
    logger.info("Fetching LawPhil SEC index: %s", url)
    html = fetch_page(session, url)
    if not html:
        return []

    soup = BeautifulSoup(html, "lxml")
    entries = []
    seen = set()

    for a in soup.find_all("a", href=True):
        href = a["href"]
        if not re.search(r"/sec/", href, re.IGNORECASE):
            continue
        abs_url = urljoin(url, href)
        if abs_url in seen:
            continue
        seen.add(abs_url)
        title = a.get_text(strip=True)
        if len(title) < 5:
            continue
        entries.append({"url": abs_url, "citation": title, "title": title, "date": ""})

    logger.info("LawPhil SEC index → %d entries for %s", len(entries), category)
    return entries


# ── Detail page extractor ─────────────────────────────────────────────────────

def extract_detail(html: str, source_url: str) -> tuple[str, str]:
    """
    Extract (full_text, date) from a SEC issuance detail page.
    Works for both sec.gov.ph (WordPress) and lawphil.net layouts.
    """
    soup = BeautifulSoup(html, "lxml")
    for tag in soup.find_all(["script", "style", "nav", "footer", "header", "aside"]):
        tag.decompose()

    # Date: prefer <time> element, then search body text
    date = ""
    time_el = soup.find("time")
    if time_el:
        date = time_el.get("datetime", time_el.get_text(strip=True))

    if not date:
        body_text = soup.get_text()
        m = re.search(
            r"((?:January|February|March|April|May|June|July|August|September|"
            r"October|November|December)\s+\d{1,2},?\s*\d{4})",
            body_text, re.IGNORECASE,
        )
        if m:
            date = m.group(1)

    # Full text: article content, then fallback to body
    content = (
        soup.find("article")
        or soup.find(class_=re.compile(r"entry-content|post-content|main-content|content", re.I))
        or soup.find("div", id=re.compile(r"content|main", re.I))
        or soup.find("body")
    )
    full_text = clean_text(content.get_text("\n")) if content else clean_text(soup.get_text("\n"))

    return full_text, date


# ── Category scraper ──────────────────────────────────────────────────────────

def scrape_category(session, category: str, limit: int | None = None):
    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    # Merge entries from both sources; deduplicate by URL
    entries_dict: dict[str, dict] = {}
    for e in fetch_index_sec(session, category):
        entries_dict[e["url"]] = e
    for e in fetch_index_lawphil_sec(session, category):
        entries_dict.setdefault(e["url"], e)

    entries = list(entries_dict.values())
    logger.info("Total combined entries for %s: %d", category, len(entries))

    if limit:
        entries = entries[:limit]

    for entry in tqdm(entries, desc=category):
        file_slug = slugify(entry["citation"]) or slugify(entry["title"]) or slugify(entry["url"].split("/")[-1])
        if file_slug in existing:
            continue

        polite_sleep()
        html = fetch_page(session, entry["url"])
        if not html:
            continue

        full_text, date = extract_detail(html, entry["url"])
        if not full_text or len(full_text) < 50:
            logger.warning("Skipping %s — content too short", entry["url"])
            continue

        if not date:
            date = entry["date"]

        record = build_law_record(
            number=entry["citation"],
            title=entry["title"],
            date=date,
            full_text=full_text,
            source_url=entry["url"],
            category=category,
        )
        save_law_json(output_dir, file_slug, record)


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Scrape SEC Philippines issuances")
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
        help="Which SEC issuance type to scrape",
    )
    parser.add_argument("--limit", type=int, help="Max items per category (for testing)")
    args = parser.parse_args()

    session = get_session(verify_ssl=True)

    cats = list(CATEGORY_MAP.values()) if args.category == "all" else [CATEGORY_MAP[args.category]]

    for cat in cats:
        logger.info("═" * 60)
        logger.info("Scraping %s", cat)
        logger.info("═" * 60)
        scrape_category(session, cat, limit=args.limit)

    logger.info("Done scraping SEC issuances.")


if __name__ == "__main__":
    main()
