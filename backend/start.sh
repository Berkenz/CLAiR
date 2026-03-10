#!/bin/bash

echo "Running database migrations..."
alembic upgrade head || echo "WARNING: Migrations failed, continuing anyway..."

echo "Starting server..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
