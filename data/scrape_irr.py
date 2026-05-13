#!/usr/bin/env python3
"""
Scraper for IRR (Implementing Rules and Regulations) Philippines.

Covers IRRs organised by the branch or agency that issued/administers them:

  Executive branch IRRs  → irr_executive
  Judiciary IRRs         → irr_judiciary
  Legislative IRRs       → irr_legislative
  SEC IRRs               → irr_sec
  BIR IRRs               → irr_bir
  DOH IRRs               → irr_doh
  PhilHealth IRRs        → irr_philhealth

Primary sources:
  - lawphil.net          — most comprehensive; has a dedicated IRR section
  - officialgazette.gov.ph — official publication of IRRs
  - Agency portals       — SEC, BIR, DOH, PhilHealth (cross-references)

LawPhil URL patterns:
  /irr/                      — main IRR index (all branches)
  /irr/executive/            — Executive department IRRs
  /irr/judiciary/            — Judiciary IRRs (SC Rules)
  /irr/legislative/          — Legislative IRRs (Congress Rules)

Official Gazette search:
  /search/?s=implementing+rules+and+regulations

Usage:
    python scrape_irr.py                         # scrape all IRR categories
    python scrape_irr.py --category executive    # only Executive branch IRRs
    python scrape_irr.py --category sec          # only SEC IRRs
    python scrape_irr.py --limit 20              # first 20 per category (testing)
"""

import argparse
import re
from urllib.parse import urljoin, quote_plus

from bs4 import BeautifulSoup
from tqdm import tqdm

from config import (
    CATEGORIES,
    LAWPHIL_BASE,
    GAZETTE_BASE,
    SEC_BASE,
    BIR_BASE,
    DOH_BASE,
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

# ── Category map exposed to scrape_all.py ─────────────────────────────────────
CATEGORY_MAP = {
    "executive":  "irr_executive",
    "judiciary":  "irr_judiciary",
    "legislative":"irr_legislative",
    "sec":        "irr_sec",
    "bir":        "irr_bir",
    "doh":        "irr_doh",
    "philhealth": "irr_philhealth",
}

# ── LawPhil IRR index paths ───────────────────────────────────────────────────
# LawPhil organises IRRs under /irr/<branch>/ subdirectories.
# Each page is a flat HTML list of links to individual IRR pages.
LAWPHIL_IRR_PATHS = {
    "irr_executive":   ["/irr/", "/irr/executive/"],
    "irr_judiciary":   ["/irr/judiciary/", "/irr/"],
    "irr_legislative": ["/irr/legislative/", "/irr/"],
    "irr_sec":         ["/irr/sec/", "/sec/irr/", "/irr/"],
    "irr_bir":         ["/irr/bir/", "/revenue/irr/", "/irr/"],
    "irr_doh":         ["/irr/doh/", "/irr/health/", "/irr/"],
    "irr_philhealth":  ["/irr/philhealth/", "/irr/"],
}

# Keywords used to filter IRR links when scanning a shared index page
CATEGORY_KEYWORDS = {
    "irr_executive":   re.compile(r"executive|office\s+of\s+the\s+president|op\s*irr|ra\s+\d+", re.I),
    "irr_judiciary":   re.compile(r"judiciar|supreme\s+court|court\s+of\s+appeals|rules\s+of\s+court", re.I),
    "irr_legislative": re.compile(r"legislat|congress|senate|house\s+of\s+representative", re.I),
    "irr_sec":         re.compile(r"\bsec\b|securities\s+and\s+exchange|corporation\s+code", re.I),
    "irr_bir":         re.compile(r"\bbir\b|bureau\s+of\s+internal\s+revenue|revenue\s+regulat", re.I),
    "irr_doh":         re.compile(r"\bdoh\b|department\s+of\s+health|health\s+code|sanitation", re.I),
    "irr_philhealth":  re.compile(r"philhealth|national\s+health\s+insurance", re.I),
}

# ── Official Gazette search URL ───────────────────────────────────────────────
GAZETTE_SEARCH_URL = f"{GAZETTE_BASE}/search/?s=implementing+rules+and+regulations&post_type=issuance"

# ── Agency-specific IRR index pages ──────────────────────────────────────────
AGENCY_IRR_PAGES = {
    "irr_sec":        [f"{SEC_BASE}/implementing-rules-and-regulations/",
                       f"{SEC_BASE}/irr/"],
    "irr_bir":        [f"{BIR_BASE}/index.php/revenue-issuances/revenue-regulations",],
    "irr_doh":        [f"{DOH_BASE}/category/issuances/implementing-rules/",
                       f"{DOH_BASE}/irr/"],
    "irr_philhealth": [f"{PHILHEALTH_BASE}/about_us/corp_issuances/irr.html"],
}

# ── LawPhil index fetcher ─────────────────────────────────────────────────────

def fetch_lawphil_irr(session, category: str) -> list[dict]:
    """
    Walk LawPhil IRR index paths and collect relevant links filtered by
    CATEGORY_KEYWORDS for the given category.
    """
    paths = LAWPHIL_IRR_PATHS.get(category, ["/irr/"])
    keyword_re = CATEGORY_KEYWORDS.get(category)
    entries: list[dict] = []
    seen: set[str] = set()

    for path in paths:
        url = f"{LAWPHIL_BASE}{path}"
        logger.info("  LawPhil IRR index: %s", url)
        html = fetch_page(session, url)
        if not html:
            continue

        soup = BeautifulSoup(html, "lxml")

        for a in soup.find_all("a", href=True):
            href = a["href"]
            abs_url = urljoin(url, href)
            if abs_url in seen:
                continue

            # Must look like a law/IRR page — not an image, CSS, etc.
            if re.search(r"\.(css|js|png|jpg|gif|ico)$", href, re.I):
                continue

            link_text = a.get_text(strip=True)
            if len(link_text) < 5:
                continue

            # Apply keyword filter on both href and link text
            if keyword_re and not (keyword_re.search(href) or keyword_re.search(link_text)):
                continue

            seen.add(abs_url)
            num_match = re.search(
                r"(?:IRR|Implementing\s+Rules?|R\.?A\.?\s*\d+|E\.?O\.?\s*\d+|"
                r"A\.?O\.?\s*\d+)\s*[^\n]{0,60}",
                link_text, re.IGNORECASE,
            )
            citation = num_match.group(0).strip() if num_match else link_text[:80]

            entries.append({"url": abs_url, "citation": citation, "title": link_text, "date": ""})

        polite_sleep()

    logger.info("LawPhil → %d IRR entries for %s", len(entries), category)
    return entries


# ── Official Gazette IRR fetcher ──────────────────────────────────────────────

def fetch_gazette_irr(session, category: str) -> list[dict]:
    """
    Search the Official Gazette for IRR documents and filter by category keywords.
    Gazette uses WordPress search pagination: ?s=...&paged=N
    """
    keyword_re = CATEGORY_KEYWORDS.get(category)
    entries: list[dict] = []
    seen: set[str] = set()
    page = 1

    while page <= 10:   # cap at 10 pages to avoid runaway
        url = GAZETTE_SEARCH_URL if page == 1 else f"{GAZETTE_SEARCH_URL}&paged={page}"
        logger.info("  Gazette IRR search page %d: %s", page, url)
        html = fetch_page(session, url)
        if not html:
            break

        soup = BeautifulSoup(html, "lxml")
        articles = soup.select("article.post") or soup.select(".search-results article")
        if not articles:
            break

        found_this_page = 0
        for article in articles:
            title_el = article.select_one("h2 a") or article.select_one("h3 a") or article.select_one("a")
            if not title_el:
                continue
            title = title_el.get_text(strip=True)
            href = title_el.get("href", "")
            if not href:
                continue

            abs_url = urljoin(GAZETTE_BASE, href)
            if abs_url in seen:
                continue

            if keyword_re and not keyword_re.search(title):
                continue

            seen.add(abs_url)
            date_el = article.select_one("time")
            date = (date_el.get("datetime", "") or date_el.get_text(strip=True)) if date_el else ""

            entries.append({"url": abs_url, "citation": title[:80], "title": title, "date": date})
            found_this_page += 1

        if found_this_page == 0:
            break

        next_link = soup.select_one("a.next.page-numbers")
        if not next_link:
            break

        page += 1
        polite_sleep()

    logger.info("Gazette → %d IRR entries for %s", len(entries), category)
    return entries


# ── Agency portal IRR fetcher ─────────────────────────────────────────────────

def fetch_agency_irr(session, category: str) -> list[dict]:
    """
    Check the relevant agency portal for IRR pages and collect links.
    """
    pages = AGENCY_IRR_PAGES.get(category, [])
    entries: list[dict] = []
    seen: set[str] = set()

    for index_url in pages:
        logger.info("  Agency IRR page: %s", index_url)
        html = fetch_page(session, index_url)
        if not html:
            continue

        soup = BeautifulSoup(html, "lxml")
        for a in soup.find_all("a", href=True):
            href = a["href"]
            if re.search(r"\.(css|js|png|jpg|gif|ico)$", href, re.I):
                continue
            abs_url = urljoin(index_url, href)
            if abs_url in seen:
                continue

            link_text = a.get_text(strip=True)
            if len(link_text) < 5:
                continue

            if not re.search(r"irr|implementing|rules\s+and\s+reg", link_text + href, re.I):
                continue

            seen.add(abs_url)
            entries.append({"url": abs_url, "citation": link_text[:80], "title": link_text, "date": ""})

        polite_sleep()

    logger.info("Agency portals → %d IRR entries for %s", len(entries), category)
    return entries


# ── Detail page extractor ─────────────────────────────────────────────────────

def extract_detail(html: str) -> tuple[str, str]:
    """
    Extract (full_text, date) from an IRR detail page.
    Handles LawPhil, Official Gazette, and agency portal layouts.
    """
    soup = BeautifulSoup(html, "lxml")
    for tag in soup.find_all(["script", "style", "nav", "footer", "header", "aside"]):
        tag.decompose()

    date = ""
    time_el = soup.find("time")
    if time_el:
        date = time_el.get("datetime", "") or time_el.get_text(strip=True)

    if not date:
        body_text = soup.get_text()
        for pattern in [
            r"((?:January|February|March|April|May|June|July|August|September|"
            r"October|November|December)\s+\d{1,2},?\s*\d{4})",
            r"(\d{4}-\d{2}-\d{2})",
        ]:
            m = re.search(pattern, body_text, re.IGNORECASE)
            if m:
                date = m.group(1)
                break

    content = (
        soup.find("article")
        or soup.find(class_=re.compile(r"entry-content|post-content|content-area|main-content|lawtext", re.I))
        or soup.find("div", id=re.compile(r"content|main|primary|law", re.I))
        or soup.find("body")
    )
    full_text = clean_text(content.get_text("\n")) if content else clean_text(soup.get_text("\n"))
    return full_text, date


# ── Category scraper ──────────────────────────────────────────────────────────

def scrape_category(session, category: str, limit: int | None = None):
    output_dir = CATEGORIES[category]
    existing = load_existing_ids(output_dir)

    # Collect from all three source tiers and deduplicate by URL
    entries_dict: dict[str, dict] = {}
    for e in fetch_lawphil_irr(session, category):
        entries_dict[e["url"]] = e
    for e in fetch_gazette_irr(session, category):
        entries_dict.setdefault(e["url"], e)
    for e in fetch_agency_irr(session, category):
        entries_dict.setdefault(e["url"], e)

    entries = list(entries_dict.values())
    logger.info("Total combined IRR entries for %s: %d", category, len(entries))

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
        if not file_slug:
            continue
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
    parser = argparse.ArgumentParser(
        description="Scrape IRR (Implementing Rules and Regulations) Philippines"
    )
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_MAP.keys()) + ["all"],
        default="all",
        help="Which IRR category to scrape",
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

    logger.info("Done scraping IRR documents.")


if __name__ == "__main__":
    main()
