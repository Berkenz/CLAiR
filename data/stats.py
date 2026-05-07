#!/usr/bin/env python3
"""
Quick stats on scraped data: counts, sizes, sample records per category.

Usage:
    python stats.py
    python stats.py --verbose    # show sample records
"""

import argparse
import json
import os

from config import CATEGORIES
from utils import logger


def count_category(cat_dir: str, verbose: bool = False) -> dict:
    if not os.path.isdir(cat_dir):
        return {"count": 0, "total_size_mb": 0}

    files = [f for f in os.listdir(cat_dir) if f.endswith(".json")]
    total_bytes = sum(
        os.path.getsize(os.path.join(cat_dir, f)) for f in files
    )

    sample = None
    if verbose and files:
        sample_path = os.path.join(cat_dir, files[0])
        try:
            with open(sample_path, "r", encoding="utf-8") as fp:
                sample = json.load(fp)
                sample["full_text"] = sample.get("full_text", "")[:200] + "..."
        except Exception:
            pass

    return {
        "count": len(files),
        "total_size_mb": round(total_bytes / (1024 * 1024), 2),
        "sample": sample,
    }


def main():
    parser = argparse.ArgumentParser(description="Show stats on scraped data")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    print("\n" + "=" * 65)
    print(f"  {'CATEGORY':<30} {'COUNT':>8} {'SIZE (MB)':>12}")
    print("=" * 65)

    grand_total = 0
    grand_size = 0.0

    for name, path in CATEGORIES.items():
        info = count_category(path, verbose=args.verbose)
        count = info["count"]
        size = info["total_size_mb"]
        grand_total += count
        grand_size += size
        print(f"  {name:<30} {count:>8} {size:>12.2f}")

        if args.verbose and info.get("sample"):
            s = info["sample"]
            print(f"    Sample → {s.get('number', 'N/A')}: {s.get('title', 'N/A')[:60]}...")

    print("-" * 65)
    print(f"  {'TOTAL':<30} {grand_total:>8} {grand_size:>12.2f}")
    print("=" * 65 + "\n")


if __name__ == "__main__":
    main()
