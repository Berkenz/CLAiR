"""
Central configuration for all scrapers.
Adjust delays, retries, and paths here.
"""

import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

CATEGORIES = {
    "republic_acts": os.path.join(BASE_DIR, "republic_acts"),
    "presidential_decrees": os.path.join(BASE_DIR, "presidential_decrees"),
    "executive_orders": os.path.join(BASE_DIR, "executive_orders"),
    "batas_pambansa": os.path.join(BASE_DIR, "batas_pambansa"),
    "commonwealth_acts": os.path.join(BASE_DIR, "commonwealth_acts"),
    "supreme_court_decisions": os.path.join(BASE_DIR, "supreme_court_decisions"),
    "administrative_orders": os.path.join(BASE_DIR, "administrative_orders"),
}

REQUEST_DELAY_SECONDS = 1.5
REQUEST_TIMEOUT_SECONDS = 30
MAX_RETRIES = 3
RETRY_BACKOFF_FACTOR = 2

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

LAWPHIL_BASE = "https://lawphil.net"
CORPUS_JURIS_BASE = "https://thecorpusjuris.com"
GAZETTE_BASE = "https://www.officialgazette.gov.ph"
ELIBRARY_BASE = "https://elibrary.judiciary.gov.ph"
