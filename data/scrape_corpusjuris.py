#!/usr/bin/env python3
"""
Scraper for thecorpusjuris.com — comprehensive Philippine statute and case database.

Covers:
  - Republic Acts (RA 1 – present, ~12,000+)
  - Presidential Decrees (~2,050)
  - Commonwealth Acts
  - Batas Pambansa
  - Executive Orders
  - Supreme Court Decisions (~58,000+)

URL patterns:
  Index:   /legislative/republic-acts/       (paginated or full list)
  Detail:  /legislative/republic-acts/ra-no-1.php
  PDs:     /legislative/presidential-decrees/pd-no-1.php
  SC:      /jurisprudence/supreme-court-decisions/  (paginated)

Usage:
    python scrape_corpusjuris.py                 # scrape all statutes
    python scrape_corpusjuris.py --category ra   # only Republic Acts
    python scrape_corpusjuris.py --category pd   # only Presidential Decrees
    python scrape_corpusjuris.py --limit 100     # first 100 per category
"""

import argparse
import re
import warnings
from urllib.parse import urljoin

import urllib3
from bs4 import BeautifulSoup
from tqdm import tqdm

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from config import CORPUS_JURIS_BASE, CATEGORIES
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

CATEGORY_MAP = {
    "ra": "republic_acts",
    "pd": "presidential_decrees",
    "eo": "executive_orders",
    "bp": "batas_pambansa",
    "ca": "commonwealth_acts",
    "sc": "supreme_court_decisions",
}

INDEX_PATHS = {
    "republic_acts": "/legislative/republic-acts/",
    "presidential_decrees": "/legislative/presidential-decrees/",
    "executive_orders": "/legislative/executive-orders/",
    "batas_pambansa": "/legislative/batas-pambansa/",
    "commonwealth_acts": "/legislative/commonwealth-acts/",
    "supreme_court_decisions": "/jurisprudence/supreme-court-decisions/",
}

DETAIL_URL_PATTERNS = {
    "republic_acts": re.compile(r"ra-no-[\w-]+\.php"),
    "presidential_decrees": re.compile(r"pd-no-[\w-]+\.php"),
    "executive_orders": re.compile(r"eo-no-[\w-]+\.php"),
    "batas_pambansa": re.compile(r"bp-(?:blg|no)-[\w-]+\.php"),
    "commonwealth_acts": re.compile(r"ca-no-[\w-]+\.php"),
    "supreme_court_decisions": re.compile(r"gr-no-[\w-]+\.php"),
}


def fetch_index_all_pages(session, category: str) -> list[tuple[str, str, str, str]]:
    """
    Fetch the index page for a category and parse all law links.
    Corpus Juris renders the full table client-side (JS DataTables) so
    all entries are in the HTML of the first page — no server pagination.
    Returns: list of (detail_url, citation, title, date)
    """
    base_path = INDEX_PATHS.get(category)
    if not base_path:
        logger.warning("No index path for category: %s", category)
        return []

    url = f"{CORPUS_JURIS_BASE}{base_path}"
    logger.info("Fetching index: %s", url)
    html = fetch_page(session, url)
    if not html:
        return []

    soup = BeautifulSoup(html, "lxml")
    entries: list[tuple[str, str, str, str]] = []
    seen_urls: set[str] = set()

    for a_tag in soup.find_all("a", href=True):
        href = a_tag["href"]
        if not href.endswith(".php"):
            continue
        detail_url = urljoin(url, href)
        if detail_url in seen_urls:
            continue

        pattern = DETAIL_URL_PATTERNS.get(category)
        if pattern and not pattern.search(href):
            continue

        seen_urls.add(detail_url)
        title_text = a_tag.get_text(strip=True)

        parent_tr = a_tag.find_parent("tr")
        citation_text = ""
        date_text = ""
        if parent_tr:
            cells = parent_tr.find_all("td")
            if cells:
                citation_text = cells[0].get_text(strip=True)
            if len(cells) >= 3:
                date_text = cells[2].get_text(strip=True)

        if not citation_text:
            citation_text = title_text

        entries.append((detail_url, citation_text, title_text, date_text))

    logger.info("Parsed %d unique entries for %s", len(entries), category)
    return entries


def extract_detail_page(html: str) -> tuple[str, str]:
    """
    Extract the full text and approval date from a Corpus Juris detail page.
    Returns (full_text, date).
    """
    soup = BeautifulSoup(html, "lxml")

    for tag in soup.find_all(["script", "style", "nav", "footer", "header"]):
        tag.decompose()

    sidebar = soup.find("aside") or soup.find(class_=re.compile(r"sidebar", re.I))
    if sidebar:
        sidebar.decompose()

    date = ""
    h1 = soup.find("h1")
    if h1:
        h1_text = h1.get_text(strip=True)
        date_match = re.search(r"(\d{1,2}\s+\w+\s+\d{4})", h1_text)
        if date_match:
            date = date_match.group(1)

    text_body = soup.get_text()
    date_patterns = [
        r"(?:Approved|Enacted|Promulgated|Signed)[:\s]*"
        r"((?:January|February|March|April|May|June|July|August|September|"
        r"October|November|December)\s+\d{1,2},?\s*\d{4})",
        r"(\d{4}-\d{2}-\d{2})",
    ]
    if not date:
        for pattern in date_patterns:
            m = re.search(pattern, text_body, re.IGNORECASE)
            if m:
                date = m.group(1) if m.lastindex else m.group(0)
                break

    main_content = soup.find("article") or soup.find(class_=re.compile(r"content|entry|post", re.I))
    if main_content:
        full_text = clean_text(main_content.get_text("\n"))
    else:
        body = soup.find("body")
        full_text = clean_text(body.get_text("\n")) if body else clean_text(soup.get_text("\n"))

    return full_text, date


def scrape_category(session, category: str, limit: int | None = None):
    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    entries = fetch_index_all_pages(session, category)
    logger.info("Total entries for %s: %d", category, len(entries))

    if limit:
        entries = entries[:limit]

    for detail_url, citation, title, date_from_index in tqdm(entries, desc=category):
        file_slug = slugify(citation) if citation else slugify(title)
        if not file_slug:
            file_slug = slugify(detail_url.split("/")[-1].replace(".php", ""))
        if file_slug in existing:
            continue

        polite_sleep()
        html = fetch_page(session, detail_url)
        if not html:
            continue

        full_text, date = extract_detail_page(html)
        if not full_text or len(full_text) < 50:
            logger.warning("Skipping %s — content too short", detail_url)
            continue

        if not date:
            date = date_from_index

        record = build_law_record(
            number=citation,
            title=title,
            date=date,
            full_text=full_text,
            source_url=detail_url,
            category=category,
        )
        save_law_json(output_dir, file_slug, record)


def main():
    parser = argparse.ArgumentParser(description="Scrape thecorpusjuris.com")
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
    )
    parser.add_argument("--limit", type=int, help="Max items per category")
    args = parser.parse_args()

    session = get_session(verify_ssl=False)

    if args.category == "all":
        cats = list(CATEGORY_MAP.values())
    else:
        cats = [CATEGORY_MAP[args.category]]

    for cat in cats:
        logger.info("═" * 60)
        logger.info("Scraping %s from Corpus Juris", cat)
        logger.info("═" * 60)
        scrape_category(session, cat, limit=args.limit)

    logger.info("Done scraping thecorpusjuris.com.")


if __name__ == "__main__":
    main()
