#!/usr/bin/env python3
"""
Scraper for BIR (Bureau of Internal Revenue) Philippines issuances.

Covers:
  - Revenue Regulations            (RR)
  - Revenue Memorandum Orders      (RMO)
  - Revenue Memorandum Circulars   (RMC)
  - Revenue Bulletins              (RB)

Primary source: https://www.bir.gov.ph
  The BIR portal organises issuances under:
    /index.php/revenue-issuances/revenue-regulations
    /index.php/revenue-issuances/revenue-memorandum-orders
    /index.php/revenue-issuances/revenue-memorandum-circulars
    /index.php/revenue-issuances/revenue-bulletins

Fallback: https://lawphil.net/revenue/ (older RRs in plain text)

Usage:
    python scrape_bir.py                    # scrape all BIR issuance types
    python scrape_bir.py --category rr      # only Revenue Regulations
    python scrape_bir.py --category rmo     # only Revenue Memorandum Orders
    python scrape_bir.py --category rmc     # only Revenue Memorandum Circulars
    python scrape_bir.py --category rb      # only Revenue Bulletins
    python scrape_bir.py --limit 20         # first 20 per category (testing)
"""

import argparse
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import (
    CATEGORIES,
    BIR_BASE,
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

# ── Category map ──────────────────────────────────────────────────────────────
CATEGORY_MAP = {
    "rr":  "bir_revenue_regulations",
    "rmo": "bir_revenue_memorandum_orders",
    "rmc": "bir_revenue_memorandum_circulars",
    "rb":  "bir_revenue_bulletins",
}

# ── Index paths on bir.gov.ph ─────────────────────────────────────────────────
# Each page lists issuances in a table; Joomla pagination via ?start=N (step 20)
BIR_INDEX = {
    "bir_revenue_regulations":          "/index.php/revenue-issuances/revenue-regulations",
    "bir_revenue_memorandum_orders":    "/index.php/revenue-issuances/revenue-memorandum-orders",
    "bir_revenue_memorandum_circulars": "/index.php/revenue-issuances/revenue-memorandum-circulars",
    "bir_revenue_bulletins":            "/index.php/revenue-issuances/revenue-bulletins",
}

# LawPhil supplement for older Revenue Regulations
LAWPHIL_BIR_INDEX = {
    "bir_revenue_regulations": "/revenue/",
}

PAGE_STEP = 20   # Joomla default items per page

# ── Index fetchers ────────────────────────────────────────────────────────────

def fetch_index_bir(session, category: str) -> list[dict]:
    """
    Paginate through the BIR Joomla listing table and collect all issuance rows.
    BIR uses ?start=0, ?start=20, ?start=40 … pagination.
    Returns list of dicts: {url, citation, title, date}
    """
    index_path = BIR_INDEX.get(category)
    if not index_path:
        return []

    entries = []
    seen: set[str] = set()
    start = 0

    while True:
        url = f"{BIR_BASE}{index_path}?start={start}" if start else f"{BIR_BASE}{index_path}"
        logger.info("  Fetching BIR index (start=%d): %s", start, url)
        html = fetch_page(session, url)
        if not html:
            break

        soup = BeautifulSoup(html, "lxml")

        # BIR table rows — each row has: number | title | date | download link
        rows = soup.select("table.category tbody tr") or soup.select("table tbody tr")
        if not rows:
            # Fallback: grab any anchor that looks like a BIR issuance PDF/page
            links = soup.find_all("a", href=True)
            rows_found = 0
            for a in links:
                href = a["href"]
                if not re.search(r"\.(pdf|php)$", href, re.I):
                    continue
                abs_url = urljoin(url, href)
                if abs_url in seen:
                    continue
                seen.add(abs_url)
                title = a.get_text(strip=True)
                entries.append({"url": abs_url, "citation": title, "title": title, "date": ""})
                rows_found += 1
            if not rows_found:
                break
            start += PAGE_STEP
            polite_sleep()
            continue

        rows_this_page = 0
        for row in rows:
            cells = row.find_all("td")
            if len(cells) < 2:
                continue

            # First cell: issuance number / citation
            citation = cells[0].get_text(strip=True)

            # Second cell: title with a link to the document
            link_el = cells[1].find("a", href=True) if len(cells) > 1 else None
            if not link_el:
                continue
            title = link_el.get_text(strip=True)
            href = link_el["href"]
            abs_url = urljoin(url, href)

            if abs_url in seen:
                continue
            seen.add(abs_url)

            # Third cell: date (if present)
            date = cells[2].get_text(strip=True) if len(cells) >= 3 else ""

            if not citation:
                citation = title

            entries.append({"url": abs_url, "citation": citation, "title": title, "date": date})
            rows_this_page += 1

        if rows_this_page == 0:
            break

        start += PAGE_STEP
        polite_sleep()

    logger.info("bir.gov.ph index → %d entries for %s", len(entries), category)
    return entries


def fetch_index_lawphil_bir(session, category: str) -> list[dict]:
    """Supplement from lawphil.net for older BIR Revenue Regulations."""
    index_path = LAWPHIL_BIR_INDEX.get(category)
    if not index_path:
        return []

    url = f"{LAWPHIL_BASE}{index_path}"
    logger.info("Fetching LawPhil BIR index: %s", url)
    html = fetch_page(session, url)
    if not html:
        return []

    soup = BeautifulSoup(html, "lxml")
    entries = []
    seen: set[str] = set()

    for a in soup.find_all("a", href=True):
        href = a["href"]
        if not re.search(r"revenue|bir|rr", href, re.IGNORECASE):
            continue
        abs_url = urljoin(url, href)
        if abs_url in seen:
            continue
        seen.add(abs_url)
        title = a.get_text(strip=True)
        if len(title) < 5:
            continue
        entries.append({"url": abs_url, "citation": title, "title": title, "date": ""})

    logger.info("LawPhil BIR index → %d entries for %s", len(entries), category)
    return entries


# ── Detail page extractor ─────────────────────────────────────────────────────

def extract_detail(html: str) -> tuple[str, str]:
    """
    Extract (full_text, date) from a BIR issuance detail page.
    Handles both bir.gov.ph Joomla pages and lawphil.net plain-text pages.
    PDFs are identified by the calling code and skipped (text only here).
    """
    soup = BeautifulSoup(html, "lxml")
    for tag in soup.find_all(["script", "style", "nav", "footer", "header", "aside"]):
        tag.decompose()

    # Date extraction
    date = ""
    body_text = soup.get_text()
    m = re.search(
        r"((?:January|February|March|April|May|June|July|August|September|"
        r"October|November|December)\s+\d{1,2},?\s*\d{4})",
        body_text, re.IGNORECASE,
    )
    if m:
        date = m.group(1)
    if not date:
        m2 = re.search(r"(\d{4}-\d{2}-\d{2})", body_text)
        if m2:
            date = m2.group(1)

    # Content
    content = (
        soup.find(class_=re.compile(r"item-page|entry-content|post-content|article-content|content-inner", re.I))
        or soup.find("article")
        or soup.find("div", id=re.compile(r"content|main", re.I))
        or soup.find("body")
    )
    full_text = clean_text(content.get_text("\n")) if content else clean_text(soup.get_text("\n"))
    return full_text, date


# ── Category scraper ──────────────────────────────────────────────────────────

def scrape_category(session, category: str, limit: int | None = None):
    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    entries_dict: dict[str, dict] = {}
    for e in fetch_index_bir(session, category):
        entries_dict[e["url"]] = e
    for e in fetch_index_lawphil_bir(session, category):
        entries_dict.setdefault(e["url"], e)

    entries = list(entries_dict.values())
    logger.info("Total combined entries for %s: %d", category, len(entries))

    if limit:
        entries = entries[:limit]

    for entry in tqdm(entries, desc=category):
        # Skip PDFs — we only ingest HTML text for now
        if entry["url"].lower().endswith(".pdf"):
            logger.debug("Skipping PDF: %s", entry["url"])
            continue

        file_slug = slugify(entry["citation"]) or slugify(entry["title"]) or slugify(entry["url"].split("/")[-1])
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
    parser = argparse.ArgumentParser(description="Scrape BIR Philippines issuances")
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
        help="Which BIR issuance type to scrape",
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

    logger.info("Done scraping BIR issuances.")


if __name__ == "__main__":
    main()
