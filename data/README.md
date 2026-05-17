# Philippine Legal Data Collection (for RAG)

This folder contains **scrapers and tools** that collect Philippine laws, executive issuances, and Supreme Court decisions as structured plain-text JSON — ready to be embedded and indexed for a RAG (Retrieval-Augmented Generation) pipeline.

---

## Folder Structure

```
data/
├── republic_acts/            ← RA 1 to present (~12,000+ laws)
├── presidential_decrees/     ← Marcos-era PDs (~2,050)
├── executive_orders/         ← EOs from all administrations
├── batas_pambansa/           ← Batas Pambansa Blg. 1–881
├── commonwealth_acts/        ← CA 1–733
├── supreme_court_decisions/  ← SC decisions (GR numbers, 1901–present)
├── administrative_orders/    ← SC administrative orders
│
├── scrape_all.py             ← MAIN ENTRY POINT — runs everything
├── scrape_lawphil.py         ← lawphil.net scraper
├── scrape_corpusjuris.py     ← thecorpusjuris.com scraper
├── scrape_gazette.py         ← officialgazette.gov.ph scraper
├── scrape_elibrary.py        ← elibrary.judiciary.gov.ph scraper
├── merge_dedup.py            ← post-scraping deduplication
├── stats.py                  ← check how many records you have
├── config.py                 ← central settings (delays, paths, etc.)
├── utils.py                  ← shared helpers (HTTP, cleaning, I/O)
├── requirements.txt          ← Python dependencies
└── README.md                 ← you are here
```

---

## Quick Start

### 1. Install Dependencies

```bash
cd data
pip install -r requirements.txt
```

### 2. Test Run (small sample)

```bash
# Scrape only 5 items per category to verify everything works
python scrape_all.py --limit 5
```

### 3. Full Scrape

```bash
# Scrape everything from all sources (will take HOURS — be patient)
python scrape_all.py
```

### 4. Check Progress

```bash
python stats.py
```

### 5. Deduplicate

After scraping from multiple sources, remove duplicates:

```bash
python merge_dedup.py           # actually remove duplicates
python merge_dedup.py --dry-run # just see what would be removed
```

---

## Per-Source Commands

You can run each source independently:

| Source | Command | What It Gets |
|--------|---------|-------------|
| **Corpus Juris** | `python scrape_corpusjuris.py` | RAs, PDs, EOs, BPs, CAs, SC decisions |
| **LawPhil** | `python scrape_lawphil.py` | RAs, PDs, EOs, BPs, CAs, SC decisions, AOs |
| **Official Gazette** | `python scrape_gazette.py` | RAs, EOs, PDs, AOs |
| **SC E-Library** | `python scrape_elibrary.py --year 2024` | SC decisions by year |

### Filter by Category

```bash
python scrape_lawphil.py --category ra          # Republic Acts only
python scrape_corpusjuris.py --category pd      # Presidential Decrees only
python scrape_lawphil.py --category sc --year 2024  # SC decisions for 2024
```

Category codes: `ra` `pd` `eo` `bp` `ca` `sc` `ao`

---

## JSON Record Format

Every law/decision is saved as a single `.json` file with this structure:

```json
{
  "number": "Republic Act No. 11032",
  "title": "Ease of Doing Business and Efficient Government Service Delivery Act of 2018",
  "date_enacted": "June 11, 2018",
  "full_text": "Section 1. Section 1 of Republic Act No. 9485, otherwise known as ...",
  "source_url": "https://lawphil.net/statutes/repacts/ra2018/ra_11032_2018.html",
  "category": "republic_acts",
  "status": "unknown"
}
```

| Field | Description |
|-------|-------------|
| `number` | Law number (RA No. 1234) or case number (G.R. No. 123456) |
| `title` | Full title or short title of the law/decision |
| `date_enacted` | Date enacted, approved, or promulgated |
| `full_text` | **Complete plain text** of the law (not PDF, not HTML) |
| `source_url` | URL where the law was scraped from |
| `category` | Which folder it belongs to |
| `status` | `in_force`, `repealed`, `amended`, or `unknown` (mostly `unknown` — the scrapers can't reliably determine this) |

---

## For the RAG Pipeline (Groupmates — READ THIS)

### How to Use This Data

1. **Run the scrapers** to populate the folders with JSON files
2. **Each JSON file = one law/decision** — use `full_text` as the document body
3. **Chunk the `full_text`** before embedding (recommended: 500–1000 tokens per chunk with overlap)
4. **Store metadata** (`number`, `title`, `date_enacted`, `category`, `source_url`) alongside each chunk
5. **Retrieval** (`backend/app/services/vector_service.py`) fetches the top vector matches, then **re-ranks** them with ~22% weight on `date_enacted` so newer laws win close ties. Fill in `date_enacted` when scraping — chunks without a date stay neutral, not excluded.

### Recommended Chunking Strategy

```python
# Example: split full_text into overlapping chunks
def chunk_text(text, chunk_size=800, overlap=200):
    words = text.split()
    chunks = []
    for i in range(0, len(words), chunk_size - overlap):
        chunk = " ".join(words[i:i + chunk_size])
        chunks.append(chunk)
    return chunks
```

### Embedding Tips

- Use a model that handles legal/formal English well (e.g., `text-embedding-3-large`, `bge-large`, or `e5-large`)
- Include the law number + title as a prefix to each chunk for better retrieval
- Example: `"[RA 11032 - Ease of Doing Business Act] Section 5. The following agencies shall..."` 

### Metadata Schema for Vector DB

```python
{
    "id": "ra_11032_chunk_3",
    "text": "...",           # the chunk text
    "number": "RA 11032",
    "title": "...",
    "category": "republic_acts",
    "date": "2018-06-11",
    "source_url": "...",
    "chunk_index": 3,
}
```

---

## Scraper Status (Tested May 2026)

| Scraper | Status | Entries Found |
|---------|--------|---------------|
| **Corpus Juris** (RAs) | Working | 11,161 Republic Acts |
| **Corpus Juris** (PDs) | Working | 2,020 Presidential Decrees |
| **LawPhil** (RAs) | Working | 1,408 Republic Acts |
| **LawPhil** (EOs) | Working | 1,281 Executive Orders |
| **LawPhil** (BPs) | Working | 890 Batas Pambansa |
| **LawPhil** (CAs) | Working | 733 Commonwealth Acts |
| **LawPhil** (AOs) | Working | 14 Administrative Orders |
| **LawPhil** (SC) | Working | ~300+/year SC decisions |
| **Official Gazette** | Blocked (403) | Manual download needed |
| **SC E-Library** | Blocked (JS/CSRF) | Manual download needed |

**Recommended:** Run only Corpus Juris + LawPhil — they cover everything:
```bash
python scrape_all.py --sources cj lp
```

---

## Notes and Caveats

- **Scraping takes a long time.** The full lawphil + corpus juris run may take 24–72 hours depending on connection. Use `--limit` to test first.
- **Be respectful.** The scrapers have a built-in 1.5s delay between requests (`config.py → REQUEST_DELAY_SECONDS`). Don't lower this — these are free public legal databases.
- **Resumable.** If the scraper crashes or you stop it, just run again. It skips files already downloaded.
- **Status field is mostly `unknown`.** Determining if a law is repealed/amended requires cross-referencing which isn't automated yet.
- **officialgazette.gov.ph** blocks automated requests (403 Forbidden). Manual download only — visit the site in a browser and save pages.
- **elibrary.judiciary.gov.ph** uses JavaScript rendering + CSRF tokens to block scrapers. Manual download only.
- **Data is NOT committed to git** (too large). Run the scrapers on whatever machine will host the RAG.

### Manual Download (Gazette & E-Library)

If you need content only available from these sites:

1. Visit the page in your browser
2. Copy the full text of the law/decision
3. Create a JSON file following the format above
4. Save it in the appropriate `data/` subfolder

---

## Sources

| Source | URL | Status | Best For |
|--------|-----|--------|----------|
| LawPhil | https://lawphil.net | **Working** | SC decisions, most comprehensive statute coverage |
| Corpus Juris | https://thecorpusjuris.com | **Working** | Clean structured statutes, good RA/PD coverage |
| Official Gazette | https://officialgazette.gov.ph | **Manual only** | Official executive issuances |
| SC E-Library | https://elibrary.judiciary.gov.ph | **Manual only** | Official SC decision texts |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `ModuleNotFoundError: No module named 'bs4'` | Run `pip install -r requirements.txt` |
| Scraper gets stuck / hangs | Check your internet; increase `REQUEST_TIMEOUT_SECONDS` in `config.py` |
| Too many 429 errors (rate limited) | Increase `REQUEST_DELAY_SECONDS` in `config.py` (try 3–5 seconds) |
| Gazette returns 403 | This is expected — download manually from the site |
| E-Library returns 0 results | This is expected — download manually from the site |
| Want to re-scrape a specific law | Delete its `.json` file from the folder, then re-run |
| Duplicate records across sources | Run `python merge_dedup.py` after scraping |
