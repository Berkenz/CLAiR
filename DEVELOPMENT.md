# Development Guide

## Tech Stack

| Layer      | Technology                    |
| ---------- | ----------------------------- |
| Frontend   | Flutter (Riverpod, go_router) |
| Backend    | FastAPI (Python)              |
| Database   | PostgreSQL 16                 |
| Auth       | Firebase Auth (Google, Email, Anonymous) |
| Local Dev  | Docker Compose                |
| Deployment | Render                        |

## Prerequisites

Install these before starting:

1. **Flutter SDK** (stable channel) — https://flutter.dev/docs/get-started/install
2. **Android Studio** — with Android SDK, emulator, and command-line tools
3. **Docker Desktop** — https://www.docker.com/products/docker-desktop/
4. **Git**

After installing, verify:

```bash
flutter doctor     # should show all green checkmarks
docker --version   # should print version
```

## Quick Start (New Developer)

### Step 1: Clone and checkout

```bash
git clone <repository-url>
cd CLAiR
git checkout develop
```

### Step 2: Create your `.env` file

```bash
cp .env.example .env
```

Open `.env` and paste these exact values:

```
DATABASE_URL=postgresql+asyncpg://clair_user:clair_password@db:5432/clair_db
FIREBASE_PROJECT_ID=clair-67
FIREBASE_WEB_API_KEY=AIzaSyB8-co1E18f0J87zNHFHVbhkLSuq6ULmuM
FIREBASE_SERVICE_ACCOUNT_KEY=service-account.json
CORS_ORIGINS=["http://localhost:3000"]
ENVIRONMENT=development
DEBUG=true
```

### Step 3: Get the Firebase service account key

Ask Berk for the `service-account.json` file and place it at:

```
backend/service-account.json
```

> **Important**: This file contains secrets. Never commit it to Git.

### Step 4: Set up the shared debug keystore (for Google Sign-In)

Copy the shared debug keystore so Google Sign-In works on your machine:

**Windows (PowerShell):**
```powershell
copy "frontend\android\debug.keystore" "$env:USERPROFILE\.android\debug.keystore"
```

**macOS/Linux:**
```bash
cp frontend/android/debug.keystore ~/.android/debug.keystore
```

### Step 5: Stop local PostgreSQL (if you have one)

If you have PostgreSQL installed locally, it will conflict with Docker on port 5432:

**Windows:**
```powershell
Get-Service *postgres*
Stop-Service <service-name>
```

**macOS:**
```bash
brew services stop postgresql
```

### Step 6: Start the backend

```bash
docker-compose up -d
docker-compose exec backend alembic upgrade head
```

Verify at http://localhost:8000/docs — you should see the Swagger UI.

### Step 7: Run the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

Pick your emulator/device when prompted. You should see the landing screen with Login, Sign Up, and Continue as Guest.

**That's it! You're ready to develop.**

---

## Architecture

This is a monorepo containing:

- **`/frontend`** — Flutter mobile application
- **`/backend`** — FastAPI REST API

```
CLAiR/
├── frontend/                 # Flutter mobile app
│   └── lib/
│       ├── app/              # App config, router
│       ├── core/             # Theme, network, constants
│       ├── features/         # Feature modules (auth, home)
│       └── shared/           # Shared providers & widgets
├── backend/                  # FastAPI backend
│   └── app/
│       ├── api/v1/endpoints/ # Route handlers
│       ├── core/             # Firebase, security
│       ├── models/           # SQLAlchemy models
│       ├── schemas/          # Pydantic schemas
│       └── services/         # Business logic
├── docker-compose.yml
├── .env.example
├── Makefile
└── README.md
```

## API Documentation

When the backend is running, interactive API docs are available at:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Makefile Commands

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
| `make flutter-build-apk` | Build APK               |
| `make clean`      | Stop services and remove volumes |

## Development Workflow

### Branching Strategy

- `main` — production-ready code
- `develop` — integration branch
- `feature/*` — new features
- `bugfix/*` — bug fixes

### Creating a Feature

```bash
git checkout develop
git pull
git checkout -b feature/my-feature
# ... make changes ...
git add -A
git commit -m "Add my feature"
git push -u origin feature/my-feature
# Open a PR to develop on GitHub
```

## Troubleshooting

### App shows old/stale screens after code changes

```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### Google Sign-In error code 10

Your debug keystore doesn't match Firebase. Re-copy the shared one:

```powershell
copy "frontend\android\debug.keystore" "$env:USERPROFILE\.android\debug.keystore"
```

Then rebuild: `flutter clean && flutter pub get && flutter run`

### pgAdmin can't connect to PostgreSQL

You likely have a local PostgreSQL conflicting on port 5432. Stop it first:

```powershell
Get-Service *postgres*
Stop-Service <service-name>
```

### Backend returns 401 on all requests

Check that:
1. `backend/service-account.json` exists
2. `.env` has `FIREBASE_SERVICE_ACCOUNT_KEY=service-account.json`
3. You restarted with `docker-compose down && docker-compose up -d` (not just restart)

### Database has no tables

Run the migration:

```bash
docker-compose exec backend alembic upgrade head
```

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
