# CLAiR

A mobile application built with Flutter and FastAPI.

## Tech Stack

| Layer      | Technology                    |
| ---------- | ----------------------------- |
| Frontend   | Flutter                       |
| Backend    | FastAPI (Python)              |
| Database   | PostgreSQL 16                 |
| Auth       | Firebase Auth (Google Sign-In)|
| Local Dev  | Docker Compose                |
| Deployment | Render                        |

## Architecture

This is a monorepo containing:

- **`/frontend`** — Flutter mobile application
- **`/backend`** — FastAPI REST API

```
CLAiR/
├── frontend/          # Flutter app
├── backend/           # FastAPI service
├── docker-compose.yml
└── .env.example
```

## Prerequisites

- **Flutter SDK** (stable channel)
- **Python 3.11+**
- **Docker & Docker Compose**
- **Firebase project** with Google Sign-In enabled

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd CLAiR
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env with your Firebase credentials and other values
```

### 3. Start services with Docker

```bash
make up
# or: docker-compose up -d
```

This starts PostgreSQL and the FastAPI backend.

### 4. Run database migrations

```bash
make migrate
```

### 5. Set up Flutter frontend

```bash
cd frontend
flutter pub get
flutter run
```

## Project Structure

```
CLAiR/
├── frontend/                 # Flutter mobile app
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
├── backend/                  # FastAPI backend
│   ├── app/
│   ├── alembic/
│   ├── requirements.txt
│   └── Dockerfile
├── .github/
│   ├── workflows/            # CI pipelines
│   └── pull_request_template.md
├── docker-compose.yml
├── .env.example
├── Makefile
└── README.md
```

## API Documentation

When the backend is running, interactive API docs are available at:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Development Workflow

### Branching Strategy

- `main` — production-ready code
- `develop` — integration branch
- `feature/*` — new features
- `bugfix/*` — bug fixes

### Makefile Commands

| Command           | Description                    |
| ----------------- | ------------------------------ |
| `make up`         | Start Docker services          |
| `make down`       | Stop Docker services           |
| `make build`      | Build Docker images            |
| `make logs`       | Follow all logs                |
| `make backend-logs` | Follow backend logs         |
| `make db-shell`   | Open PostgreSQL shell          |
| `make migrate`    | Run database migrations        |
| `make migration msg="..."` | Create new migration   |
| `make test-backend` | Run backend tests            |
| `make flutter-run` | Run Flutter app              |
| `make flutter-test` | Run Flutter tests           |
| `make flutter-build-apk` | Build APK                 |
| `make clean`      | Stop services and remove volumes |

## Deployment

### Backend (Render)

1. Connect your repository to Render
2. Create a new Web Service
3. Set build command: `pip install -r backend/requirements.txt`
4. Set start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables from `.env.example`
6. Add a PostgreSQL database (or use Render PostgreSQL add-on)

## Contributing

1. Create a feature branch from `develop`
2. Make your changes and add tests
3. Ensure CI passes
4. Open a pull request with the PR template filled out
5. Request review from a team member

## Team

<!-- Add team members here -->
