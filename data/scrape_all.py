#!/usr/bin/env python3
"""
Master scraper — runs all sources sequentially.

This is the main entry point. It calls each source scraper in order of
reliability and comprehensiveness:

  1. thecorpusjuris.com  — cleanest data, structured tables
  2. lawphil.net         — most comprehensive, covers SC decisions
  3. officialgazette.gov.ph — official source, may be slow
  4. elibrary.judiciary.gov.ph — SC decisions supplement

All scrapers are **resumable**: they skip files that already exist in the
output folders, so you can Ctrl+C and restart without losing progress.

Usage:
    python scrape_all.py                    # run all scrapers
    python scrape_all.py --sources cj lp    # only Corpus Juris & LawPhil
    python scrape_all.py --limit 10         # 10 items per category (for testing)
    python scrape_all.py --sc-year 2024     # only SC decisions from 2024
"""

import argparse
import subprocess
import sys

from utils import logger


SOURCES = {
    "cj": ("scrape_corpusjuris.py", "thecorpusjuris.com"),
    "lp": ("scrape_lawphil.py", "lawphil.net"),
    "gz": ("scrape_gazette.py", "officialgazette.gov.ph"),
    "el": ("scrape_elibrary.py", "elibrary.judiciary.gov.ph"),
}


def run_scraper(script: str, extra_args: list[str]):
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
        help="Which sources to scrape (default: all)",
    )
    parser.add_argument("--limit", type=int, help="Limit items per category (for testing)")
    parser.add_argument("--sc-year", type=int, help="SC decisions: specific year only")
    parser.add_argument(
        "--category",
        help="Pass through --category to individual scrapers (ra/pd/eo/bp/ca/sc/ao)",
    )
    args = parser.parse_args()

    for source_key in args.sources:
        script, name = SOURCES[source_key]
        logger.info("=" * 70)
        logger.info("  SOURCE: %s (%s)", name, script)
        logger.info("=" * 70)

        extra_args = []
        if args.limit:
            extra_args += ["--limit", str(args.limit)]
        if args.category:
            extra_args += ["--category", args.category]
        if args.sc_year and source_key in ("lp", "el"):
            extra_args += ["--year", str(args.sc_year)]

        run_scraper(script, extra_args)

    logger.info("All scrapers completed.")


if __name__ == "__main__":
    main()
