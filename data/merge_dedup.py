#!/usr/bin/env python3
"""
Post-scraping utility: merge and deduplicate records across sources.

Since we scrape from multiple sources (LawPhil, Corpus Juris, Gazette, E-Library),
the same law may appear more than once. This script:

  1. Walks every JSON file in each category folder
  2. Groups by normalized law number / GR number
  3. Picks the best record (longest full_text wins)
  4. Writes the deduplicated set back

Usage:
    python merge_dedup.py                    # dedup all categories
    python merge_dedup.py --category republic_acts
    python merge_dedup.py --dry-run          # just report duplicates
"""

import argparse
import json
import os
import re

from config import CATEGORIES
from utils import logger


def normalize_number(number: str) -> str:
    """Normalize a law/case number for dedup matching."""
    s = number.lower().strip()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"republic act|r\.?a\.?", "ra", s)
    s = re.sub(r"presidential decree|p\.?d\.?", "pd", s)
    s = re.sub(r"executive order|e\.?o\.?", "eo", s)
    s = re.sub(r"batas pambansa|b\.?p\.?", "bp", s)
    s = re.sub(r"commonwealth act|c\.?a\.?", "ca", s)
    s = re.sub(r"g\.?r\.?", "gr", s)
    s = re.sub(r"no\.?\s*", "", s)
    s = re.sub(r"[^a-z0-9]", "", s)
    return s


def dedup_category(category_dir: str, dry_run: bool = False) -> dict:
    if not os.path.isdir(category_dir):
        return {}

    files = [f for f in os.listdir(category_dir) if f.endswith(".json")]
    logger.info("  Found %d files in %s", len(files), category_dir)

    groups: dict[str, list[tuple[str, dict]]] = {}
    for fname in files:
        fpath = os.path.join(category_dir, fname)
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError) as e:
            logger.warning("  Could not read %s: %s", fpath, e)
            continue

        key = normalize_number(data.get("number", fname))
        groups.setdefault(key, []).append((fname, data))

    duplicates = {k: v for k, v in groups.items() if len(v) > 1}
    logger.info("  Unique laws: %d, Duplicate groups: %d", len(groups), len(duplicates))

    removed = 0
    for key, entries in duplicates.items():
        entries.sort(key=lambda x: len(x[1].get("full_text", "")), reverse=True)
        best_fname, best_data = entries[0]

        for fname, data in entries[1:]:
            if dry_run:
                logger.info("  [DRY RUN] Would remove %s (dup of %s)", fname, best_fname)
            else:
                fpath = os.path.join(category_dir, fname)
                os.remove(fpath)
                logger.info("  Removed duplicate: %s (kept %s)", fname, best_fname)
                removed += 1

    logger.info("  Removed %d duplicates", removed)
    return {"total": len(files), "unique": len(groups), "removed": removed}


def main():
    parser = argparse.ArgumentParser(description="Merge and deduplicate scraped data")
    parser.add_argument("--category", help="Specific category folder name")
    parser.add_argument("--dry-run", action="store_true", help="Report without deleting")
    args = parser.parse_args()

    if args.category:
        if args.category in CATEGORIES:
            cats = {args.category: CATEGORIES[args.category]}
        else:
            logger.error("Unknown category: %s", args.category)
            return
    else:
        cats = CATEGORIES

    for name, path in cats.items():
        logger.info("═" * 50)
        logger.info("Deduplicating: %s", name)
        dedup_category(path, dry_run=args.dry_run)

    logger.info("Deduplication complete.")


if __name__ == "__main__":
    main()
