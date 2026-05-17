"""
Check whether a law (by RA/PD number) exists in the pgvector law_chunks table.

Usage (from repo root or data/):
    python data/check_law_in_db.py 10627
    python data/check_law_in_db.py --query "bullying"

Requires SUPABASE_DB_URL in backend/.env (same as ingest.py).
"""

from __future__ import annotations

import argparse
import asyncio
import os
from pathlib import Path

import asyncpg
from dotenv import load_dotenv

_REPO_ROOT = Path(__file__).parent.parent
load_dotenv(_REPO_ROOT / "backend" / ".env")


async def main() -> None:
    parser = argparse.ArgumentParser(description="Look up law chunks in pgvector DB")
    parser.add_argument(
        "number",
        nargs="?",
        help="Law number digits, e.g. 10627 for RA 10627",
    )
    parser.add_argument(
        "--query",
        "-q",
        help="Free-text search on number/title (e.g. bullying)",
    )
    args = parser.parse_args()

    if not args.number and not args.query:
        parser.error("Provide a law number (e.g. 10627) or --query")

    url = os.environ.get("SUPABASE_DB_URL")
    if not url:
        print("ERROR: SUPABASE_DB_URL not set in backend/.env")
        raise SystemExit(1)

    pattern = f"%{args.number}%" if args.number else f"%{args.query}%"

    conn = await asyncpg.connect(url, ssl=False)
    try:
        total = await conn.fetchval("SELECT COUNT(*)::bigint FROM law_chunks")
        rows = await conn.fetch(
            """
            SELECT id, number, title, chunk_index, date_enacted, source_url
            FROM law_chunks
            WHERE number ILIKE $1 OR title ILIKE $1
            ORDER BY number, chunk_index
            LIMIT 30
            """,
            pattern,
        )
        print(f"law_chunks total in DB: {total}")
        print(f"Matches for pattern {pattern!r}: {len(rows)} row(s)\n")
        if not rows:
            print("Not found in law_chunks.")
            if args.number:
                local = _REPO_ROOT / "data" / "republic_acts" / f"ra_no_{args.number}.json"
                if local.is_file():
                    print(f"Local JSON exists: {local}")
                    print("Ingest it with:  cd data && python ingest.py --category ra")
                else:
                    print(f"No local file at {local}")
            raise SystemExit(2)

        for r in rows:
            url_short = (r["source_url"] or "")[:60]
            print(
                f"- id={r['id']}\n"
                f"  number={r['number']}\n"
                f"  title={(r['title'] or '')[:100]}\n"
                f"  chunk_index={r['chunk_index']}  date_enacted={r['date_enacted']}\n"
                f"  source_url={url_short}...\n"
            )
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
