#!/usr/bin/env python3
"""
Scraper for lawphil.net — the most comprehensive free Philippine legal database.

Covers:
  - Republic Acts
  - Presidential Decrees
  - Executive Orders
  - Batas Pambansa
  - Commonwealth Acts
  - Supreme Court Decisions
  - Administrative Orders (SC admin orders)

Usage:
    python scrape_lawphil.py                 # scrape everything
    python scrape_lawphil.py --category ra   # only Republic Acts
    python scrape_lawphil.py --category sc   # only SC decisions
    python scrape_lawphil.py --year 2024     # only SC decisions for 2024
    python scrape_lawphil.py --limit 50      # scrape first 50 items per category
"""

import argparse
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import LAWPHIL_BASE, CATEGORIES
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

# ── Index page URLs ──────────────────────────────────────────────────────────

INDEX_URLS = {
    "republic_acts": f"{LAWPHIL_BASE}/statutes/repacts/repacts.html",
    "commonwealth_acts": f"{LAWPHIL_BASE}/statutes/comacts/comacts.html",
    "batas_pambansa": f"{LAWPHIL_BASE}/statutes/bataspam/bataspam.html",
    "executive_orders": f"{LAWPHIL_BASE}/executive/execord/execord.html",
    "administrative_orders": f"{LAWPHIL_BASE}/courts/supreme/ao/ao.html",
}

CATEGORY_MAP = {
    "ra": "republic_acts",
    "pd": "presidential_decrees",
    "eo": "executive_orders",
    "bp": "batas_pambansa",
    "ca": "commonwealth_acts",
    "sc": "supreme_court_decisions",
    "ao": "administrative_orders",
}

# SC Decisions are organized by year/month
SC_YEARS = list(range(1901, 2027))
SC_MONTHS = [
    "jan", "feb", "mar", "apr", "may", "jun",
    "jul", "aug", "sep", "oct", "nov", "dec",
]


def is_individual_law_page(url: str) -> bool:
    """Check if a URL points to an individual law/EO/RA page, not an index."""
    fname = url.rstrip("/").split("/")[-1].replace(".html", "")
    if re.match(r"^(eo|ra|pd|ca|bp|ao|am)\d{4}$", fname):
        return False
    if re.match(r"^\d{4}$", fname):
        return False
    if fname in ("repacts", "comacts", "bataspam", "execord", "presdecs", "ao"):
        return False
    if re.match(r"^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\d{4}$", fname):
        return False
    if re.match(r"^(ra|eo|pd|ca|bp|ao|am)_\w+", fname):
        return True
    if re.search(r"(gr|no|act)[-_]?\d", fname, re.I):
        return True
    if re.match(r"^irr_", fname):
        return True
    return len(fname) > 8


def parse_index_links(html: str, base_url: str) -> list[tuple[str, str, str]]:
    """
    Parse a lawphil index page and extract (url, number/title_text, date_text) tuples.
    Filters out sub-index links (year pages, category indexes).
    """
    soup = BeautifulSoup(html, "lxml")
    results = []
    seen_urls: set[str] = set()

    for a_tag in soup.find_all("a", href=True):
        href = a_tag["href"]
        if not href.endswith(".html"):
            continue
        full_url = urljoin(base_url, href)
        if full_url == base_url or full_url in seen_urls:
            continue

        if not is_individual_law_page(full_url):
            continue

        seen_urls.add(full_url)

        row_text = ""
        parent_td = a_tag.find_parent("td")
        if parent_td:
            parent_tr = parent_td.find_parent("tr")
            if parent_tr:
                row_text = parent_tr.get_text(" ", strip=True)

        link_text = a_tag.get_text(strip=True)
        if not link_text:
            continue

        date_match = re.search(
            r"((?:January|February|March|April|May|June|July|August|September|"
            r"October|November|December)\s+\d{1,2},?\s*\d{4})",
            row_text,
        )
        date_str = date_match.group(1) if date_match else ""

        results.append((full_url, link_text, date_str))

    return results


def extract_law_content(html: str) -> tuple[str, str, str]:
    """
    From a single law page on lawphil, extract (title, date, full_text).
    """
    soup = BeautifulSoup(html, "lxml")

    for tag in soup.find_all(["script", "style", "nav", "footer", "header"]):
        tag.decompose()

    title = ""
    title_tag = soup.find("title")
    if title_tag:
        title = title_tag.get_text(strip=True)

    date = ""
    text_block = soup.get_text()
    date_patterns = [
        r"(?:Approved|Enacted|Promulgated|Signed)[:\s]*"
        r"((?:January|February|March|April|May|June|July|August|September|"
        r"October|November|December)\s+\d{1,2},?\s*\d{4})",
        r"(\d{1,2}\s+(?:day|st|nd|rd|th)\s+(?:day\s+)?of\s+"
        r"(?:January|February|March|April|May|June|July|August|September|"
        r"October|November|December),?\s*\d{4})",
    ]
    for pattern in date_patterns:
        m = re.search(pattern, text_block, re.IGNORECASE)
        if m:
            date = m.group(1) if m.lastindex else m.group(0)
            break

    body = soup.find("body")
    if body:
        full_text = clean_text(body.get_text("\n"))
    else:
        full_text = clean_text(soup.get_text("\n"))

    return title, date, full_text


def scrape_index_category(
    session, category: str, limit: int | None = None
):
    """Scrape all laws from a single lawphil index page."""
    index_url = INDEX_URLS.get(category)
    if not index_url:
        logger.warning("No index URL configured for category: %s", category)
        return

    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    logger.info("Fetching index: %s", index_url)
    html = fetch_page(session, index_url)
    if not html:
        logger.error("Could not fetch index for %s", category)
        return

    links = parse_index_links(html, index_url)
    logger.info("Found %d links for %s", len(links), category)

    if limit:
        links = links[:limit]

    for url, link_text, date_from_index in tqdm(links, desc=category):
        file_slug = slugify(link_text)
        if not file_slug:
            file_slug = slugify(url.split("/")[-1].replace(".html", ""))
        if file_slug in existing:
            continue

        polite_sleep()
        page_html = fetch_page(session, url)
        if not page_html:
            continue

        title, date, full_text = extract_law_content(page_html)
        if not full_text or len(full_text) < 50:
            logger.warning("Skipping %s — content too short", url)
            continue

        number = link_text
        if not date:
            date = date_from_index

        record = build_law_record(
            number=number,
            title=title or link_text,
            date=date,
            full_text=full_text,
            source_url=url,
            category=category,
        )
        save_law_json(output_dir, file_slug, record)


def scrape_sc_decisions(session, year: int | None = None, limit: int | None = None):
    """
    Scrape Supreme Court decisions from lawphil.
    Organized by year → month → individual decisions.
    """
    output_dir = CATEGORIES["supreme_court_decisions"]
    existing = load_existing_ids(output_dir)
    years = [year] if year else SC_YEARS

    for yr in years:
        for month in SC_MONTHS:
            month_url = (
                f"{LAWPHIL_BASE}/judjuris/juri{yr}/{month}{yr}/{month}{yr}.html"
            )
            polite_sleep()
            html = fetch_page(session, month_url)
            if not html:
                continue

            links = parse_sc_month_page(html, month_url)
            logger.info("Found %d decisions for %s %d", len(links), month, yr)

            if limit:
                links = links[:limit]

            for url, gr_number, case_title, date_str in tqdm(
                links, desc=f"SC {month} {yr}"
            ):
                file_slug = slugify(gr_number) if gr_number else slugify(
                    url.split("/")[-1].replace(".html", "")
                )
                if file_slug in existing:
                    continue

                polite_sleep()
                page_html = fetch_page(session, url)
                if not page_html:
                    continue

                _, date, full_text = extract_law_content(page_html)
                if not full_text or len(full_text) < 50:
                    continue

                if not date:
                    date = date_str

                record = build_law_record(
                    number=gr_number,
                    title=case_title,
                    date=date,
                    full_text=full_text,
                    source_url=url,
                    category="supreme_court_decisions",
                )
                save_law_json(output_dir, file_slug, record)


def parse_sc_month_page(
    html: str, base_url: str
) -> list[tuple[str, str, str, str]]:
    """Parse an SC monthly index page. Returns (url, gr_number, title, date)."""
    soup = BeautifulSoup(html, "lxml")
    results = []

    for a_tag in soup.find_all("a", href=True):
        href = a_tag["href"]
        if not href.endswith(".html"):
            continue
        full_url = urljoin(base_url, href)
        if full_url == base_url:
            continue

        link_text = a_tag.get_text(strip=True)
        if not link_text:
            continue

        gr_match = re.search(r"G\.?R\.?\s*(?:No\.?)?\s*[\w\-]+", link_text, re.I)
        gr_number = gr_match.group(0) if gr_match else link_text

        parent_tr = a_tag.find_parent("tr")
        row_text = parent_tr.get_text(" ", strip=True) if parent_tr else link_text

        date_match = re.search(
            r"((?:January|February|March|April|May|June|July|August|September|"
            r"October|November|December)\s+\d{1,2},?\s*\d{4})",
            row_text,
        )
        date_str = date_match.group(1) if date_match else ""

        case_title = row_text
        if len(case_title) > 300:
            case_title = case_title[:300] + "..."

        results.append((full_url, gr_number, case_title, date_str))

    return results


def scrape_presidential_decrees(session, limit: int | None = None):
    """
    Presidential Decrees on lawphil are embedded in executive issuance pages.
    We search for PD links across known URL patterns.
    """
    output_dir = CATEGORIES["presidential_decrees"]
    existing = load_existing_ids(output_dir)

    pd_index_urls = [
        f"{LAWPHIL_BASE}/executive/presdec/pd{yr}/pd{yr}.html"
        for yr in range(1972, 1987)
    ]
    pd_index_urls.append(f"{LAWPHIL_BASE}/executive/presdec/presdecs.html")

    all_links = []
    for index_url in pd_index_urls:
        polite_sleep()
        html = fetch_page(session, index_url)
        if not html:
            continue
        links = parse_index_links(html, index_url)
        all_links.extend(links)

    logger.info("Found %d Presidential Decree links", len(all_links))
    if limit:
        all_links = all_links[:limit]

    for url, link_text, date_from_index in tqdm(all_links, desc="presidential_decrees"):
        file_slug = slugify(link_text)
        if not file_slug:
            file_slug = slugify(url.split("/")[-1].replace(".html", ""))
        if file_slug in existing:
            continue

        polite_sleep()
        page_html = fetch_page(session, url)
        if not page_html:
            continue

        title, date, full_text = extract_law_content(page_html)
        if not full_text or len(full_text) < 50:
            continue
        if not date:
            date = date_from_index

        record = build_law_record(
            number=link_text,
            title=title or link_text,
            date=date,
            full_text=full_text,
            source_url=url,
            category="presidential_decrees",
        )
        save_law_json(output_dir, file_slug, record)


def main():
    parser = argparse.ArgumentParser(description="Scrape lawphil.net for Philippine laws")
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
        help="Which category to scrape (default: all)",
    )
    parser.add_argument("--year", type=int, help="For SC decisions: specific year")
    parser.add_argument("--limit", type=int, help="Max items to scrape per category")
    args = parser.parse_args()

    session = get_session()

    if args.category == "all":
        cats = list(CATEGORY_MAP.values())
    else:
        cats = [CATEGORY_MAP[args.category]]

    for cat in cats:
        logger.info("═" * 60)
        logger.info("Scraping category: %s", cat)
        logger.info("═" * 60)

        if cat == "supreme_court_decisions":
            scrape_sc_decisions(session, year=args.year, limit=args.limit)
        elif cat == "presidential_decrees":
            scrape_presidential_decrees(session, limit=args.limit)
        elif cat in INDEX_URLS:
            scrape_index_category(session, cat, limit=args.limit)
        else:
            logger.warning("No scraper implemented for %s on lawphil", cat)

    logger.info("Done scraping lawphil.net.")


if __name__ == "__main__":
    main()
