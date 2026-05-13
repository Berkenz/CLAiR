"""
Lightweight embedding microservice.
Runs on the Google Cloud VM alongside PostgreSQL.
Loads all-mpnet-base-v2 once and serves 768-dim embeddings.
"""
from __future__ import annotations

import logging
import os

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(message)s")
log = logging.getLogger(__name__)

app = FastAPI(title="CLAiR Embed Service")

_model: SentenceTransformer | None = None


def get_model() -> SentenceTransformer:
    global _model
    if _model is None:
        log.info("Loading all-mpnet-base-v2 …")
        _model = SentenceTransformer("all-mpnet-base-v2")
        log.info("Model ready.")
    return _model


@app.on_event("startup")
async def startup() -> None:
    get_model()


class EmbedRequest(BaseModel):
    text: str


class EmbedResponse(BaseModel):
    embedding: list[float]


@app.post("/embed", response_model=EmbedResponse)
def embed(req: EmbedRequest) -> EmbedResponse:
    if not req.text or not req.text.strip():
        raise HTTPException(status_code=400, detail="text must not be empty")
    model = get_model()
    vector = model.encode(req.text, normalize_embeddings=True).tolist()
    return EmbedResponse(embedding=vector)


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "model": "all-mpnet-base-v2"}
