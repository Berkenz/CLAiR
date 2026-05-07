#!/usr/bin/env python3
"""
Scraper for officialgazette.gov.ph — the official publication of the Philippine government.

Covers:
  - Republic Acts
  - Executive Orders
  - Presidential Decrees
  - Administrative Orders
  - Proclamations

The Official Gazette organizes content by type:
  /downloads/executive-issuances/executive-orders/
  /downloads/republic-acts/
  /downloads/presidential-decrees/
  ...

Note: This site can be slow and sometimes requires manual download.
      The scraper handles what it can; for anything it misses, do manual download.

Usage:
    python scrape_gazette.py                 # scrape everything
    python scrape_gazette.py --category eo   # only Executive Orders
    python scrape_gazette.py --limit 50
"""

import argparse
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import GAZETTE_BASE, CATEGORIES
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
    "eo": "executive_orders",
    "pd": "presidential_decrees",
    "ao": "administrative_orders",
}

INDEX_PATHS = {
    "republic_acts": "/downloads/republic-acts/",
    "executive_orders": "/downloads/executive-issuances/executive-orders/",
    "presidential_decrees": "/downloads/executive-issuances/presidential-decrees/",
    "administrative_orders": "/downloads/executive-issuances/administrative-orders/",
}


def fetch_gazette_index(session, category: str) -> list[tuple[str, str]]:
    """
    The Official Gazette lists items as paginated WordPress-style posts.
    Returns list of (detail_url, title_text).
    """
    base_path = INDEX_PATHS.get(category)
    if not base_path:
        return []

    all_links: list[tuple[str, str]] = []
    page = 1

    while True:
        if page == 1:
            url = f"{GAZETTE_BASE}{base_path}"
        else:
            url = f"{GAZETTE_BASE}{base_path}page/{page}/"

        logger.info("Fetching gazette index page %d: %s", page, url)
        html = fetch_page(session, url)
        if not html:
            break

        soup = BeautifulSoup(html, "lxml")
        entries = soup.find_all("article") or soup.find_all(
            class_=re.compile(r"entry|post|law-entry", re.I)
        )

        if not entries:
            links_in_list = soup.find_all("a", href=True)
            new_found = []
            for a in links_in_list:
                href = a["href"]
                text = a.get_text(strip=True)
                if text and ("/republic-act" in href or "/executive-order" in href
                             or "/presidential-decree" in href or "/administrative-order" in href):
                    new_found.append((urljoin(url, href), text))
            if not new_found:
                break
            all_links.extend(new_found)
        else:
            for entry in entries:
                a_tag = entry.find("a", href=True)
                if a_tag:
                    detail_url = urljoin(url, a_tag["href"])
                    title = a_tag.get_text(strip=True)
                    all_links.append((detail_url, title))

        next_link = soup.find("a", class_=re.compile(r"next", re.I))
        if not next_link:
            nav = soup.find(class_=re.compile(r"pagination|nav-links", re.I))
            if nav:
                next_link = nav.find("a", string=re.compile(r"Next|Older|»|›", re.I))
        if not next_link:
            break

        page += 1
        polite_sleep()

    return all_links


def extract_gazette_detail(html: str) -> tuple[str, str, str]:
    """Extract (title, date, full_text) from a gazette detail page."""
    soup = BeautifulSoup(html, "lxml")

    for tag in soup.find_all(["script", "style", "nav", "footer", "header"]):
        tag.decompose()

    title = ""
    h1 = soup.find("h1")
    if h1:
        title = h1.get_text(strip=True)

    date = ""
    time_tag = soup.find("time")
    if time_tag:
        date = time_tag.get("datetime", "") or time_tag.get_text(strip=True)
    if not date:
        date_el = soup.find(class_=re.compile(r"date|published", re.I))
        if date_el:
            date = date_el.get_text(strip=True)

    content_div = (
        soup.find(class_=re.compile(r"entry-content|post-content|article-body", re.I))
        or soup.find("article")
    )
    if content_div:
        full_text = clean_text(content_div.get_text("\n"))
    else:
        body = soup.find("body")
        full_text = clean_text(body.get_text("\n")) if body else ""

    return title, date, full_text


def scrape_category(session, category: str, limit: int | None = None):
    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    entries = fetch_gazette_index(session, category)
    logger.info("Found %d entries for %s on Official Gazette", len(entries), category)

    if limit:
        entries = entries[:limit]

    for detail_url, index_title in tqdm(entries, desc=f"gazette-{category}"):
        file_slug = slugify(index_title)
        if not file_slug:
            file_slug = slugify(detail_url.rstrip("/").split("/")[-1])
        if file_slug in existing:
            continue

        polite_sleep()
        html = fetch_page(session, detail_url)
        if not html:
            continue

        title, date, full_text = extract_gazette_detail(html)
        if not full_text or len(full_text) < 50:
            continue

        number_match = re.search(
            r"(?:Republic Act|Executive Order|Presidential Decree|Administrative Order)"
            r"\s*(?:No\.?)?\s*([\d\-]+)",
            title or index_title,
            re.IGNORECASE,
        )
        number = number_match.group(0) if number_match else index_title

        record = build_law_record(
            number=number,
            title=title or index_title,
            date=date,
            full_text=full_text,
            source_url=detail_url,
            category=category,
        )
        save_law_json(output_dir, file_slug, record)


def main():
    parser = argparse.ArgumentParser(description="Scrape officialgazette.gov.ph")
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
    )
    parser.add_argument("--limit", type=int)
    args = parser.parse_args()

    session = get_session()

    if args.category == "all":
        cats = list(CATEGORY_MAP.values())
    else:
        cats = [CATEGORY_MAP[args.category]]

    for cat in cats:
        logger.info("═" * 60)
        logger.info("Scraping %s from Official Gazette", cat)
        logger.info("═" * 60)
        scrape_category(session, cat, limit=args.limit)

    logger.info("Done scraping officialgazette.gov.ph.")


if __name__ == "__main__":
    main()
