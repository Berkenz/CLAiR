#!/usr/bin/env python3
"""
Scraper for PhilHealth (Philippine Health Insurance Corporation) issuances.

Covers:
  - PhilHealth Circulars         (PC)
  - Board Resolutions            (BR)

Primary source: https://www.philhealth.gov.ph
  Issuances are listed at:
    /about_us/corp_issuances/philhealth_circulars.html  (static HTML table)
    /about_us/corp_issuances/board_resolutions.html

  PhilHealth's portal is a static HTML site — each index page is a table of
  links, mostly to PDFs. For PDFs we log a skip; for HTML pages we scrape.
  If a page title references a downloadable PDF, we store the URL but mark
  full_text as the title/summary only (PDF extraction is out of scope here).

Usage:
    python scrape_philhealth.py                    # scrape all PhilHealth issuances
    python scrape_philhealth.py --category pc      # only PhilHealth Circulars
    python scrape_philhealth.py --category br      # only Board Resolutions
    python scrape_philhealth.py --limit 20         # first 20 per category (testing)
    python scrape_philhealth.py --include-pdf-meta # save metadata even for PDF items
"""

import argparse
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import (
    CATEGORIES,
    PHILHEALTH_BASE,
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
    "pc": "philhealth_circulars",
    "br": "philhealth_board_resolutions",
}

# ── Index URLs (static HTML, no pagination) ───────────────────────────────────
PHILHEALTH_INDEX = {
    "philhealth_circulars":         "/about_us/corp_issuances/philhealth_circulars.html",
    "philhealth_board_resolutions": "/about_us/corp_issuances/board_resolutions.html",
}

# Alternate index paths that may exist on the portal
PHILHEALTH_ALT_INDEX = {
    "philhealth_circulars": [
        "/downloads/publications/corp_issuances/",
        "/about_us/corp_issuances/",
    ],
}

# ── Index fetcher ─────────────────────────────────────────────────────────────

def fetch_index_philhealth(session, category: str) -> list[dict]:
    """
    Scrape the PhilHealth static HTML index page for issuance links.
    Returns list of dicts: {url, citation, title, date, is_pdf}
    """
    index_path = PHILHEALTH_INDEX.get(category)
    if not index_path:
        return []

    index_url = f"{PHILHEALTH_BASE}{index_path}"
    logger.info("Fetching PhilHealth index: %s", index_url)
    html = fetch_page(session, index_url)

    # Try alternate paths if primary not found
    if not html:
        for alt_path in PHILHEALTH_ALT_INDEX.get(category, []):
            alt_url = f"{PHILHEALTH_BASE}{alt_path}"
            logger.info("Trying alternate index: %s", alt_url)
            html = fetch_page(session, alt_url)
            if html:
                index_url = alt_url
                break

    if not html:
        logger.warning("Could not fetch any index for %s", category)
        return []

    soup = BeautifulSoup(html, "lxml")
    entries: list[dict] = []
    seen: set[str] = set()

    # PhilHealth pages use <table> with rows: number | title/link | date
    rows = soup.select("table tbody tr") or soup.select("table tr")

    if rows:
        for row in rows:
            cells = row.find_all("td")
            if not cells:
                continue

            # First cell: issuance number
            citation_text = cells[0].get_text(strip=True)

            # Find the link — may be in any cell
            link_el = row.find("a", href=True)
            if not link_el:
                continue

            href = link_el["href"]
            abs_url = urljoin(index_url, href)
            if abs_url in seen:
                continue
            seen.add(abs_url)

            title = link_el.get_text(strip=True)
            if not title:
                title = citation_text

            # Date: last cell or second-to-last
            date = ""
            if len(cells) >= 3:
                date = cells[-1].get_text(strip=True)
                # Validate it looks like a date
                if not re.search(r"\d{4}", date):
                    date = cells[-2].get_text(strip=True) if len(cells) >= 4 else ""

            is_pdf = abs_url.lower().endswith(".pdf")

            if not citation_text:
                citation_text = title

            entries.append({
                "url": abs_url,
                "citation": citation_text,
                "title": title,
                "date": date,
                "is_pdf": is_pdf,
            })

    else:
        # Fallback: grab any <a> with .pdf or .html that looks like an issuance
        pattern = re.compile(r"(pc|br|circular|resolution|philhealth)", re.I)
        for a in soup.find_all("a", href=True):
            href = a["href"]
            if not pattern.search(href) and not pattern.search(a.get_text()):
                continue
            abs_url = urljoin(index_url, href)
            if abs_url in seen:
                continue
            seen.add(abs_url)
            title = a.get_text(strip=True)
            if len(title) < 3:
                continue
            is_pdf = abs_url.lower().endswith(".pdf")
            entries.append({
                "url": abs_url,
                "citation": title,
                "title": title,
                "date": "",
                "is_pdf": is_pdf,
            })

    logger.info("philhealth.gov.ph index → %d entries for %s", len(entries), category)
    return entries


# ── Detail page extractor ─────────────────────────────────────────────────────

def extract_detail(html: str) -> tuple[str, str]:
    """
    Extract (full_text, date) from a PhilHealth HTML issuance page.
    """
    soup = BeautifulSoup(html, "lxml")
    for tag in soup.find_all(["script", "style", "nav", "footer", "header", "aside"]):
        tag.decompose()

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

    content = (
        soup.find(class_=re.compile(r"entry-content|post-content|content-area|main-content|article-body", re.I))
        or soup.find("article")
        or soup.find("div", id=re.compile(r"content|main|primary", re.I))
        or soup.find("body")
    )
    full_text = clean_text(content.get_text("\n")) if content else clean_text(soup.get_text("\n"))
    return full_text, date


# ── Category scraper ──────────────────────────────────────────────────────────

def scrape_category(session, category: str, limit: int | None = None, include_pdf_meta: bool = False):
    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    entries = fetch_index_philhealth(session, category)
    logger.info("Total entries for %s: %d", category, len(entries))

    if limit:
        entries = entries[:limit]

    for entry in tqdm(entries, desc=category):
        file_slug = (
            slugify(entry["citation"])
            or slugify(entry["title"])
            or slugify(entry["url"].split("/")[-1].rsplit(".", 1)[0])
        )
        if file_slug in existing:
            continue

        # PDF handling
        if entry.get("is_pdf"):
            if include_pdf_meta:
                # Save metadata record without full_text; useful for later PDF extraction
                record = build_law_record(
                    number=entry["citation"],
                    title=entry["title"],
                    date=entry["date"],
                    full_text=f"[PDF] {entry['title']}",
                    source_url=entry["url"],
                    category=category,
                    status="pdf_pending",
                )
                save_law_json(output_dir, file_slug, record)
            else:
                logger.debug("Skipping PDF (use --include-pdf-meta to save metadata): %s", entry["url"])
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
    parser = argparse.ArgumentParser(description="Scrape PhilHealth Philippines issuances")
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
        help="Which PhilHealth issuance type to scrape",
    )
    parser.add_argument("--limit", type=int, help="Max items per category (for testing)")
    parser.add_argument(
        "--include-pdf-meta",
        action="store_true",
        help="Save metadata records for PDF issuances (no full_text extraction)",
    )
    args = parser.parse_args()

    session = get_session(verify_ssl=True)

    cats = list(CATEGORY_MAP.values()) if args.category == "all" else [CATEGORY_MAP[args.category]]

    for cat in cats:
        logger.info("═" * 60)
        logger.info("Scraping %s", cat)
        logger.info("═" * 60)
        scrape_category(session, cat, limit=args.limit, include_pdf_meta=args.include_pdf_meta)

    logger.info("Done scraping PhilHealth issuances.")


if __name__ == "__main__":
    main()
