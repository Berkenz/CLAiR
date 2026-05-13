"""
Central configuration for all scrapers.
Adjust delays, retries, and paths here.
"""

import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ── Output folders ────────────────────────────────────────────────────────────
# Each key is the canonical category name used throughout the pipeline.
# ingest.py reads these same keys, so any addition here must also be
# added to the CATEGORIES dict in ingest.py.

CATEGORIES = {
    # ── Existing ──────────────────────────────────────────────────────────────
    "republic_acts":          os.path.join(BASE_DIR, "republic_acts"),
    "presidential_decrees":   os.path.join(BASE_DIR, "presidential_decrees"),
    "executive_orders":       os.path.join(BASE_DIR, "executive_orders"),
    "batas_pambansa":         os.path.join(BASE_DIR, "batas_pambansa"),
    "commonwealth_acts":      os.path.join(BASE_DIR, "commonwealth_acts"),
    "supreme_court_decisions":os.path.join(BASE_DIR, "supreme_court_decisions"),
    "administrative_orders":  os.path.join(BASE_DIR, "administrative_orders"),

    # ── SEC — Securities and Exchange Commission ──────────────────────────────
    "sec_memorandum_circulars":       os.path.join(BASE_DIR, "sec_memorandum_circulars"),
    "sec_opinions":                   os.path.join(BASE_DIR, "sec_opinions"),
    "sec_notices":                    os.path.join(BASE_DIR, "sec_notices"),

    # ── BIR — Bureau of Internal Revenue ─────────────────────────────────────
    "bir_revenue_regulations":        os.path.join(BASE_DIR, "bir_revenue_regulations"),
    "bir_revenue_memorandum_orders":  os.path.join(BASE_DIR, "bir_revenue_memorandum_orders"),
    "bir_revenue_memorandum_circulars": os.path.join(BASE_DIR, "bir_revenue_memorandum_circulars"),
    "bir_revenue_bulletins":          os.path.join(BASE_DIR, "bir_revenue_bulletins"),

    # ── DOH — Department of Health ───────────────────────────────────────────
    "doh_administrative_orders":      os.path.join(BASE_DIR, "doh_administrative_orders"),
    "doh_department_circulars":       os.path.join(BASE_DIR, "doh_department_circulars"),
    "doh_department_memoranda":       os.path.join(BASE_DIR, "doh_department_memoranda"),

    # ── PhilHealth ───────────────────────────────────────────────────────────
    "philhealth_circulars":           os.path.join(BASE_DIR, "philhealth_circulars"),
    "philhealth_board_resolutions":   os.path.join(BASE_DIR, "philhealth_board_resolutions"),

    # ── IRR — Implementing Rules and Regulations ──────────────────────────────
    # Organised by the branch/body that issued or administers the IRR.
    "irr_executive":                  os.path.join(BASE_DIR, "irr_executive"),
    "irr_judiciary":                  os.path.join(BASE_DIR, "irr_judiciary"),
    "irr_legislative":                os.path.join(BASE_DIR, "irr_legislative"),
    "irr_sec":                        os.path.join(BASE_DIR, "irr_sec"),
    "irr_bir":                        os.path.join(BASE_DIR, "irr_bir"),
    "irr_doh":                        os.path.join(BASE_DIR, "irr_doh"),
    "irr_philhealth":                 os.path.join(BASE_DIR, "irr_philhealth"),
}

# ── HTTP behaviour ────────────────────────────────────────────────────────────
REQUEST_DELAY_SECONDS   = 1.5
REQUEST_TIMEOUT_SECONDS = 30
MAX_RETRIES             = 3
RETRY_BACKOFF_FACTOR    = 2

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

# ── Source base URLs ──────────────────────────────────────────────────────────
LAWPHIL_BASE    = "https://lawphil.net"
CORPUS_JURIS_BASE = "https://thecorpusjuris.com"
GAZETTE_BASE    = "https://www.officialgazette.gov.ph"
ELIBRARY_BASE   = "https://elibrary.judiciary.gov.ph"

# New agency portals
SEC_BASE        = "https://www.sec.gov.ph"
BIR_BASE        = "https://www.bir.gov.ph"
DOH_BASE        = "https://doh.gov.ph"
PHILHEALTH_BASE = "https://www.philhealth.gov.ph"

# LAWPHIL also hosts many IRR documents and agency issuances
LAWPHIL_IRR_BASE = "https://lawphil.net"