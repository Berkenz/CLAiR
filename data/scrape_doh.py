#!/usr/bin/env python3
"""
Scraper for DOH (Department of Health) Philippines issuances.

Covers:
  - Administrative Orders    (AO)
  - Department Circulars     (DC)
  - Department Memoranda     (DM)

Primary source: https://doh.gov.ph
  Issuances are listed at:
    /category/issuances/administrative-orders/
    /category/issuances/department-circulars/
    /category/issuances/department-memoranda/

  The DOH site is WordPress-based with standard paginated archives.

Usage:
    python scrape_doh.py                    # scrape all DOH issuance types
    python scrape_doh.py --category ao      # only Administrative Orders
    python scrape_doh.py --category dc      # only Department Circulars
    python scrape_doh.py --category dm      # only Department Memoranda
    python scrape_doh.py --limit 20         # first 20 per category (testing)
"""

import argparse
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import (
    CATEGORIES,
    DOH_BASE,
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

# ── Category map ──────────────────────────────────────────────────────────────
CATEGORY_MAP = {
    "ao": "doh_administrative_orders",
    "dc": "doh_department_circulars",
    "dm": "doh_department_memoranda",
}

# ── Index paths on doh.gov.ph (WordPress) ────────────────────────────────────
DOH_INDEX = {
    "doh_administrative_orders": "/category/issuances/administrative-orders/",
    "doh_department_circulars":  "/category/issuances/department-circulars/",
    "doh_department_memoranda":  "/category/issuances/department-memoranda/",
}

# ── WordPress paginator ───────────────────────────────────────────────────────

def iter_wp_pages(session, base_url: str):
    """
    Yield (html, soup) for each page of a WordPress category archive.
    Handles standard /page/N/ pagination.
    """
    page = 1
    while True:
        url = base_url if page == 1 else f"{base_url}page/{page}/"
        logger.info("  DOH index page %d: %s", page, url)
        html = fetch_page(session, url)
        if not html:
            break

        soup = BeautifulSoup(html, "lxml")

        # WordPress article list or custom list
        articles = (
            soup.select("article.post")
            or soup.select("article")
            or soup.select(".issuances-list li")
            or soup.select(".entry-content li")
            or soup.select("table tbody tr")
        )
        if not articles:
            break

        yield html, soup, articles

        next_link = (
            soup.select_one("a.next.page-numbers")
            or soup.select_one(".nav-next a")
            or soup.select_one("a[rel='next']")
        )
        if not next_link:
            break
        page += 1
        polite_sleep()


# ── Index fetcher ─────────────────────────────────────────────────────────────

def fetch_index_doh(session, category: str) -> list[dict]:
    """
    Scrape the DOH WordPress archive for a given category.
    Returns list of dicts: {url, citation, title, date}
    """
    index_path = DOH_INDEX.get(category)
    if not index_path:
        return []

    base_url = f"{DOH_BASE}{index_path}"
    entries: list[dict] = []
    seen: set[str] = set()

    for _, soup, articles in iter_wp_pages(session, base_url):
        for item in articles:
            # --- WordPress article card ---
            title_el = (
                item.select_one("h2.entry-title a")
                or item.select_one("h3 a")
                or item.select_one(".issuance-title a")
                or item.select_one("a")
            )
            if not title_el:
                continue
            title = title_el.get_text(strip=True)
            href = title_el.get("href", "")
            if not href:
                continue
            abs_url = urljoin(base_url, href)
            if abs_url in seen:
                continue
            seen.add(abs_url)

            date_el = (
                item.select_one("time")
                or item.select_one(".entry-date")
                or item.select_one(".date")
                or item.select_one(".post-date")
            )
            date = ""
            if date_el:
                date = date_el.get("datetime", "") or date_el.get_text(strip=True)

            # Extract issuance number from title
            # e.g. "Administrative Order No. 2021-0001" / "DC No. 2022-456"
            num_match = re.search(
                r"(?:A\.?O\.?|D\.?C\.?|D\.?M\.?|Administrative Order|"
                r"Department Circular|Department Memorandum|No\.?)\s*([\d\-\.s]+)",
                title, re.IGNORECASE,
            )
            citation = num_match.group(0).strip() if num_match else title[:80]

            entries.append({"url": abs_url, "citation": citation, "title": title, "date": date})

    logger.info("doh.gov.ph index → %d entries for %s", len(entries), category)
    return entries


# ── Detail page extractor ─────────────────────────────────────────────────────

def extract_detail(html: str) -> tuple[str, str]:
    """
    Extract (full_text, date) from a DOH issuance detail page.
    """
    soup = BeautifulSoup(html, "lxml")
    for tag in soup.find_all(["script", "style", "nav", "footer", "header", "aside"]):
        tag.decompose()

    # Date
    date = ""
    time_el = soup.find("time")
    if time_el:
        date = time_el.get("datetime", "") or time_el.get_text(strip=True)

    if not date:
        body_text = soup.get_text()
        m = re.search(
            r"((?:January|February|March|April|May|June|July|August|September|"
            r"October|November|December)\s+\d{1,2},?\s*\d{4})",
            body_text, re.IGNORECASE,
        )
        if m:
            date = m.group(1)

    # Content
    content = (
        soup.find("article")
        or soup.find(class_=re.compile(r"entry-content|post-content|main-content|content-area", re.I))
        or soup.find("div", id=re.compile(r"content|primary|main", re.I))
        or soup.find("body")
    )
    full_text = clean_text(content.get_text("\n")) if content else clean_text(soup.get_text("\n"))
    return full_text, date


# ── Category scraper ──────────────────────────────────────────────────────────

def scrape_category(session, category: str, limit: int | None = None):
    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    entries = fetch_index_doh(session, category)
    logger.info("Total entries for %s: %d", category, len(entries))

    if limit:
        entries = entries[:limit]

    for entry in tqdm(entries, desc=category):
        if entry["url"].lower().endswith(".pdf"):
            logger.debug("Skipping PDF: %s", entry["url"])
            continue

        file_slug = (
            slugify(entry["citation"])
            or slugify(entry["title"])
            or slugify(entry["url"].split("/")[-1])
        )
        if file_slug in existing:
            continue

        polite_sleep()
        html = fetch_page(session, entry["url"])
        if not html:
            continue

        full_text, date = extract_detail(html)
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
    parser = argparse.ArgumentParser(description="Scrape DOH Philippines issuances")
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
        help="Which DOH issuance type to scrape",
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

    logger.info("Done scraping DOH issuances.")


if __name__ == "__main__":
    main()
