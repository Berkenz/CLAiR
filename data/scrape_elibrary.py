#!/usr/bin/env python3
"""
Scraper for elibrary.judiciary.gov.ph — Supreme Court E-Library.

⚠️  STATUS: This site uses JavaScript-rendered DataTables with server-side
    processing and CSRF protection. The AJAX API returns 500 errors for
    external requests. Use lawphil.net SC decisions scraper as primary source.
    For supplementary content, download manually from the site.

This is the official repository of the Philippine Supreme Court for decisions
and resolutions. It has a search interface and organized by year.

Note: This site blocks automated scraping via JS rendering + CSRF.
      Manual download is recommended — see README.md for instructions.

Covers:
  - Supreme Court Decisions
  - SC Resolutions

URL Pattern:
  Search:   /thebookshelf/showdocs/1/{page_number}
  Detail:   /thebookshelf/docmonth/search/{year}/{month}
            /thebookshelf/showdocsfriendly/1/xxxxx

Usage:
    python scrape_elibrary.py --year 2024
    python scrape_elibrary.py --year-range 2020 2025
    python scrape_elibrary.py --limit 100
"""

import argparse
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import ELIBRARY_BASE, CATEGORIES
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

MONTHS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]


def fetch_monthly_index(session, year: int, month: str) -> list[tuple[str, str, str]]:
    """
    Fetch the list of SC decisions for a given month/year.
    Returns list of (detail_url, gr_number, case_title).
    """
    url = f"{ELIBRARY_BASE}/thebookshelf/docmonth/search/{year}/{month}"
    logger.info("Fetching e-Library index: %s %d", month, year)

    html = fetch_page(session, url)
    if not html:
        return []

    soup = BeautifulSoup(html, "lxml")
    results = []

    for a_tag in soup.find_all("a", href=True):
        href = a_tag["href"]
        text = a_tag.get_text(strip=True)
        if not text:
            continue

        if "showdocs" in href or "showdocsfriendly" in href:
            full_url = urljoin(url, href)
            gr_match = re.search(r"G\.?R\.?\s*(?:No\.?)?\s*[\w\-]+", text, re.I)
            gr_number = gr_match.group(0) if gr_match else text[:80]
            results.append((full_url, gr_number, text))

    for row in soup.find_all("tr"):
        cells = row.find_all("td")
        if len(cells) < 2:
            continue
        link = row.find("a", href=True)
        if link and "showdocs" in link["href"]:
            full_url = urljoin(url, link["href"])
            cell_texts = [c.get_text(strip=True) for c in cells]
            gr_text = cell_texts[0] if cell_texts else ""
            title_text = cell_texts[1] if len(cell_texts) > 1 else gr_text
            if (full_url, gr_text, title_text) not in results:
                results.append((full_url, gr_text, title_text))

    return results


def extract_elibrary_detail(html: str) -> tuple[str, str]:
    """Extract (full_text, date) from an e-Library detail page."""
    soup = BeautifulSoup(html, "lxml")

    for tag in soup.find_all(["script", "style", "nav"]):
        tag.decompose()

    date = ""
    text_body = soup.get_text()
    date_match = re.search(
        r"(?:Promulgated|Decided|Date)[:\s]*"
        r"((?:January|February|March|April|May|June|July|August|September|"
        r"October|November|December)\s+\d{1,2},?\s*\d{4})",
        text_body,
        re.IGNORECASE,
    )
    if date_match:
        date = date_match.group(1)

    content = (
        soup.find(class_=re.compile(r"document|content|decision|body", re.I))
        or soup.find("article")
        or soup.find("body")
    )
    full_text = clean_text(content.get_text("\n")) if content else ""

    return full_text, date


def scrape_elibrary(session, years: list[int], limit: int | None = None):
    output_dir = CATEGORIES["supreme_court_decisions"]
    existing = load_existing_ids(output_dir)

    for year in years:
        for month in MONTHS:
            polite_sleep()
            entries = fetch_monthly_index(session, year, month)
            logger.info("Found %d decisions for %s %d", len(entries), month, year)

            if limit:
                entries = entries[:limit]

            for detail_url, gr_number, case_title in tqdm(
                entries, desc=f"eLib {month} {year}"
            ):
                file_slug = slugify(gr_number)
                if not file_slug:
                    file_slug = slugify(detail_url.split("/")[-1])

                prefixed_slug = f"elib_{file_slug}"
                if prefixed_slug in existing:
                    continue

                polite_sleep()
                html = fetch_page(session, detail_url)
                if not html:
                    continue

                full_text, date = extract_elibrary_detail(html)
                if not full_text or len(full_text) < 100:
                    continue

                if not date:
                    date = f"{month} {year}"

                record = build_law_record(
                    number=gr_number,
                    title=case_title,
                    date=date,
                    full_text=full_text,
                    source_url=detail_url,
                    category="supreme_court_decisions",
                )
                save_law_json(output_dir, prefixed_slug, record)


def main():
    parser = argparse.ArgumentParser(description="Scrape elibrary.judiciary.gov.ph")
    parser.add_argument("--year", type=int, help="Specific year to scrape")
    parser.add_argument(
        "--year-range", type=int, nargs=2, metavar=("START", "END"),
        help="Range of years (inclusive)",
    )
    parser.add_argument("--limit", type=int)
    args = parser.parse_args()

    if args.year:
        years = [args.year]
    elif args.year_range:
        years = list(range(args.year_range[0], args.year_range[1] + 1))
    else:
        years = list(range(2000, 2027))

    session = get_session()
    scrape_elibrary(session, years, limit=args.limit)
    logger.info("Done scraping elibrary.judiciary.gov.ph.")


if __name__ == "__main__":
    main()
