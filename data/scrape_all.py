#!/usr/bin/env python3
"""
Master scraper — runs all sources sequentially.

This is the main entry point. It calls each source scraper in order of
reliability and comprehensiveness:

  1.  cj  — thecorpusjuris.com      (cleanest data, structured tables)
  2.  lp  — lawphil.net             (most comprehensive, SC decisions)
  3.  gz  — officialgazette.gov.ph  (official source, may be slow)
  4.  el  — elibrary.judiciary.gov.ph (SC decisions supplement)
  5.  sec — sec.gov.ph              (MCs, Opinions, Notices + LawPhil supplement)
  6.  bir — bir.gov.ph              (RR, RMO, RMC, RB + LawPhil supplement)
  7.  doh — doh.gov.ph              (AO, DC, DM)
  8.  ph  — philhealth.gov.ph       (Circulars, Board Resolutions)
  9.  irr — lawphil + gazette + agencies (IRR for all branches and agencies)

All scrapers are **resumable**: they skip files that already exist in the
output folders, so you can Ctrl+C and restart without losing progress.

Usage:
    python scrape_all.py                              # run all scrapers
    python scrape_all.py --sources cj lp              # only Corpus Juris & LawPhil
    python scrape_all.py --sources sec bir doh ph     # only agency scrapers
    python scrape_all.py --sources irr                # only IRR documents
    python scrape_all.py --limit 10                   # 10 items per category (for testing)
    python scrape_all.py --sc-year 2024               # only SC decisions from 2024
    python scrape_all.py --sources bir --category rmc # BIR Memorandum Circulars only
"""

import argparse
import subprocess
import sys

from utils import logger


SOURCES = {
    # ── Original sources ──────────────────────────────────────────────────────
    "cj":  ("scrape_corpusjuris.py", "thecorpusjuris.com"),
    "lp":  ("scrape_lawphil.py",     "lawphil.net"),
    "gz":  ("scrape_gazette.py",     "officialgazette.gov.ph"),
    "el":  ("scrape_elibrary.py",    "elibrary.judiciary.gov.ph"),

    # ── New agency sources ────────────────────────────────────────────────────
    "sec": ("scrape_sec.py",         "sec.gov.ph (SEC issuances)"),
    "bir": ("scrape_bir.py",         "bir.gov.ph (BIR issuances)"),
    "doh": ("scrape_doh.py",         "doh.gov.ph (DOH issuances)"),
    "ph":  ("scrape_philhealth.py",  "philhealth.gov.ph (PhilHealth issuances)"),
    "irr": ("scrape_irr.py",         "IRR — all branches and agencies"),
}

# Source keys that accept a --year argument (SC decisions only)
YEAR_AWARE_SOURCES = {"lp", "el"}

# Source keys that accept a --category argument
CATEGORY_AWARE_SOURCES = {"cj", "lp", "sec", "bir", "doh", "ph", "irr"}


def run_scraper(script: str, extra_args: list[str]) -> int:
    cmd = [sys.executable, script] + extra_args
    logger.info("Running: %s", " ".join(cmd))
    result = subprocess.run(cmd, cwd=sys.path[0] or ".")
    if result.returncode != 0:
        logger.warning("%s exited with code %d", script, result.returncode)
    return result.returncode


def main():
    parser = argparse.ArgumentParser(description="Run all Philippine law scrapers")
    parser.add_argument(
        "--sources",
        nargs="+",
        choices=list(SOURCES.keys()),
        default=list(SOURCES.keys()),
        help=(
            "Which sources to scrape (default: all). "
            "E.g. --sources sec bir doh ph irr"
        ),
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Limit items per category (useful for testing, e.g. --limit 10)",
    )
    parser.add_argument(
        "--sc-year",
        type=int,
        help="SC decisions: scrape a specific year only (passed to lp and el scrapers)",
    )
    parser.add_argument(
        "--category",
        help=(
            "Pass a category filter to individual scrapers. "
            "Valid values depend on the scraper: "
            "cj/lp → ra/pd/eo/bp/ca/sc/ao | "
            "sec → mc/opinions/notices | "
            "bir → rr/rmo/rmc/rb | "
            "doh → ao/dc/dm | "
            "ph  → pc/br | "
            "irr → executive/judiciary/legislative/sec/bir/doh/philhealth"
        ),
    )
    parser.add_argument(
        "--include-pdf-meta",
        action="store_true",
        help="(PhilHealth scraper) Save metadata records for PDF-only issuances",
    )
    args = parser.parse_args()

    for source_key in args.sources:
        script, name = SOURCES[source_key]
        logger.info("=" * 70)
        logger.info("  SOURCE: %s  (%s)", name, script)
        logger.info("=" * 70)

        extra_args: list[str] = []

        if args.limit:
            extra_args += ["--limit", str(args.limit)]

        if args.category and source_key in CATEGORY_AWARE_SOURCES:
            extra_args += ["--category", args.category]

        if args.sc_year and source_key in YEAR_AWARE_SOURCES:
            extra_args += ["--year", str(args.sc_year)]

        if args.include_pdf_meta and source_key == "ph":
            extra_args += ["--include-pdf-meta"]

        run_scraper(script, extra_args)

    logger.info("=" * 70)
    logger.info("All scrapers completed.")
    logger.info("=" * 70)


if __name__ == "__main__":
    main()