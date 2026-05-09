"""
Shared utilities for all scrapers: HTTP fetching, text cleaning, JSON I/O.
"""

import json
import os
import re
import time
import logging

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from config import (
    REQUEST_DELAY_SECONDS,
    REQUEST_TIMEOUT_SECONDS,
    MAX_RETRIES,
    RETRY_BACKOFF_FACTOR,
    USER_AGENT,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("scraper")


def get_session(verify_ssl: bool = True) -> requests.Session:
    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})
    session.verify = verify_ssl
    retry = Retry(
        total=MAX_RETRIES,
        backoff_factor=RETRY_BACKOFF_FACTOR,
        status_forcelist=[429, 500, 502, 503, 504],
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session


def fetch_page(session: requests.Session, url: str) -> str | None:
    """Fetch a URL and return its HTML text, or None on failure."""
    try:
        resp = session.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
        resp.raise_for_status()
        resp.encoding = resp.apparent_encoding or "utf-8"
        return resp.text
    except requests.RequestException as e:
        logger.warning("Failed to fetch %s: %s", url, e)
        return None


def polite_sleep():
    time.sleep(REQUEST_DELAY_SECONDS)


def clean_text(raw: str) -> str:
    """Normalize whitespace, strip stray HTML artifacts, keep paragraph breaks."""
    text = re.sub(r"<[^>]+>", " ", raw)
    text = re.sub(r"&nbsp;", " ", text)
    text = re.sub(r"&amp;", "&", text)
    text = re.sub(r"&lt;", "<", text)
    text = re.sub(r"&gt;", ">", text)
    text = re.sub(r"&#\d+;", "", text)
    text = re.sub(r"\xa0", " ", text)
    lines = text.splitlines()
    cleaned_lines = [re.sub(r"[ \t]+", " ", line).strip() for line in lines]
    text = "\n".join(line for line in cleaned_lines if line)
    return text.strip()


def slugify(text: str) -> str:
    """Turn a title/number into a safe filename slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_]+", "_", text)
    text = text.strip("_")
    return text[:120]


def save_law_json(output_dir: str, filename: str, data: dict):
    """Persist a single law/decision as a JSON file."""
    os.makedirs(output_dir, exist_ok=True)
    filepath = os.path.join(output_dir, f"{filename}.json")
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    logger.debug("Saved %s", filepath)


def load_existing_ids(output_dir: str) -> set[str]:
    """Return the set of filenames (sans .json) already scraped, for resumability."""
    if not os.path.isdir(output_dir):
        return set()
    return {
        os.path.splitext(f)[0]
        for f in os.listdir(output_dir)
        if f.endswith(".json")
    }


def build_law_record(
    number: str,
    title: str,
    date: str,
    full_text: str,
    source_url: str,
    category: str,
    status: str = "unknown",
) -> dict:
    return {
        "number": number,
        "title": title,
        "date_enacted": date,
        "full_text": full_text,
        "source_url": source_url,
        "category": category,
        "status": status,
    }
