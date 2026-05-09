"""add pgvector extension and law_chunks table for RAG

Revision ID: b0c1d2e3f4a5
Revises: a8b9c0d1e2f3
Create Date: 2026-05-09 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op

revision: str = "b0c1d2e3f4a5"
down_revision: Union[str, None] = "a8b9c0d1e2f3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    op.execute("""
        CREATE TABLE IF NOT EXISTS law_chunks (
            id          TEXT PRIMARY KEY,
            text        TEXT        NOT NULL,
            embedding   vector(768),
            number      TEXT,
            title       TEXT,
            category    TEXT,
            date_enacted TEXT,
            source_url  TEXT,
            chunk_index INTEGER     NOT NULL DEFAULT 0
        )
    """)

    # HNSW index for fast approximate cosine similarity search.
    # Unlike IVFFlat, HNSW works on an empty table and requires no training.
    op.execute("""
        CREATE INDEX IF NOT EXISTS law_chunks_embedding_hnsw_idx
        ON law_chunks
        USING hnsw (embedding vector_cosine_ops)
    """)

    # Metadata indexes for optional category/number filtering
    op.execute("CREATE INDEX IF NOT EXISTS ix_law_chunks_category ON law_chunks (category)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_law_chunks_number   ON law_chunks (number)")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS law_chunks")
    # Leave the vector extension in place — other tables might use it.
