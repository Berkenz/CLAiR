<div align="center">

<img src="frontend/assets/images/CLAiR-icon.png" alt="CLAiR Logo" width="120" />

# CLAiR

### AI-Powered Philippine Legal Assistance

*Making legal help accessible to every Filipino*

[![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/Web-React_19-61DAFB?logo=react&logoColor=black)](https://react.dev)
[![FastAPI](https://img.shields.io/badge/API-FastAPI-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL_16-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Firebase](https://img.shields.io/badge/Auth-Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)

</div>

---

## What is CLAiR?

**CLAiR** is a legal assistance platform designed specifically for the Philippines. It bridges the gap between everyday Filipinos and the legal system by providing instant, AI-powered legal guidance — no law degree required.

Whether you need to understand your rights, find a lawyer near you, or get a quick answer to a legal question, CLAiR has you covered. And for lawyers, CLAiR offers a dedicated web portal to manage clients, appointments, and AI-assisted case assessments.

> **Why CLAiR?** Legal help in the Philippines has traditionally been expensive and inaccessible. CLAiR aims to change that — by putting a knowledgeable legal assistant in everyone's pocket, for free.

---

## Who is this for?

| | Clients (Regular Users) | Lawyers |
|---|---|---|
| **Platform** | Mobile App (Android) | Web Portal |
| **Main Use** | Get legal guidance, find lawyers, book appointments | Manage cases, assess clients, handle appointments |
| **AI Features** | Chat with AI about legal concerns | AI-powered assessment of client conversations |
| **Account** | Google Sign-In, Email, or Guest | Email with professional onboarding |

---

## Key Features

### For Clients (Mobile App)

- **AI Legal Chat** — Ask any legal question in plain language and get answers grounded in actual Philippine laws and Supreme Court decisions. Supports both text and voice input.
- **Guest Mode** — Try the AI assistant without creating an account.
- **Find a Lawyer** — Discover licensed lawyers near you on an interactive map, filtered by your legal concern.
- **Book Appointments** — Schedule consultations directly through the app.
- **Direct Messaging** — Communicate with your lawyer securely within the app.
- **Legal Library** — Browse a curated collection of Philippine legal resources.
- **Notifications** — Stay updated on appointments and messages in real time.

### For Lawyers (Web Portal)

- **Professional Onboarding** — Guided profile setup with credentials and specialization.
- **Case Management** — View and manage all client cases in one place.
- **AI Assessment** — Automatically analyze client chat conversations to extract key legal issues and insights.
- **Appointment Management** — Accept, reschedule, or decline client bookings.
- **Notifications** — Get alerted on new client requests and messages.

---

## How the AI Works

CLAiR's AI is not just a generic chatbot — it is specifically trained to understand Philippine law:

1. **Legal Knowledge Base** — We scraped and indexed thousands of Philippine statutes and Supreme Court decisions. When you ask a question, the AI searches this database first.
2. **Web Search** — For recent developments, the AI can also search the web to supplement its answers.
3. **Suggested Lawyers** — Based on your question and location, the AI suggests relevant lawyers you can contact.
4. **Multiple AI Models** — The backend can use Groq, Google Gemini, or OpenRouter models, giving us flexibility and reliability.

---

## Platform Overview

```
CLAiR
├── 📱 Mobile App          Flutter — for clients (Android)
├── 🌐 Lawyer Web Portal   React + Vite — for legal professionals
├── ⚙️  Backend API         FastAPI (Python) — the brain of the system
├── 🧠 Embedding Service   Sentence Transformers — powers semantic search
└── 📚 Data Pipeline       Python scrapers — Philippine law ingestion
```

---

## Tech Stack

> This section is for developers. Non-technical readers can skip ahead!

### Mobile App (`/frontend`)
| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile framework |
| Riverpod | State management |
| go_router | Navigation and routing |
| Dio | HTTP client |
| Firebase Auth | Google Sign-In, Email, Anonymous auth |
| flutter_map + geolocator | Maps and location services |
| speech_to_text | Voice input for chat |
| freezed + json_serializable | Code generation for models |

### Lawyer Web Portal (`/lawyer-web`)
| Technology | Purpose |
|---|---|
| React 19 | UI framework |
| Vite 8 | Build tool and dev server |
| TypeScript | Type safety |
| Tailwind CSS 4 | Styling |
| TanStack Query | Data fetching and caching |
| React Router 7 | Client-side routing |
| Firebase Auth | Authentication |
| react-leaflet | Interactive maps |
| react-markdown | Markdown rendering for AI output |

### Backend API (`/backend`)
| Technology | Purpose |
|---|---|
| FastAPI | REST API framework |
| SQLAlchemy (async) + asyncpg | Database ORM |
| PostgreSQL 16 + pgvector | Database with vector similarity search |
| Alembic | Database migrations |
| Pydantic v2 | Request/response validation |
| Groq / Gemini / OpenRouter | LLM providers for AI chat |
| Tavily | Web search integration |
| firebase-admin | Firebase token verification |
| Supabase | File storage |
| slowapi | Rate limiting |
| fpdf2 + python-docx | PDF/DOCX report generation |

### Infrastructure
| Technology | Purpose |
|---|---|
| Docker Compose | Local development environment |
| Render | Cloud deployment |
| GitHub Actions | CI/CD pipelines |

---

## Project Structure

```
CLAiR/
├── frontend/                  # Flutter mobile app
│   └── lib/
│       ├── app/               # App config and router
│       ├── core/              # Theme, network, constants
│       ├── features/          # Feature modules (auth, chat, lawyers, appointments...)
│       └── shared/            # Shared widgets and providers
│
├── lawyer-web/                # React lawyer web portal
│   └── src/
│       ├── features/          # Feature modules (auth, dashboard, cases, AI assessment...)
│       └── layouts/           # Page layouts
│
├── backend/                   # FastAPI REST API
│   └── app/
│       ├── api/v1/endpoints/  # Route handlers
│       ├── models/            # Database models
│       ├── schemas/           # Request/response schemas
│       └── services/          # Business logic (chat, RAG, embeddings...)
│
├── embed-service/             # Embedding microservice (sentence-transformers)
├── data/                      # Legal data scrapers and pipeline
├── docker-compose.yml
├── Makefile                   # Developer shortcuts
└── DEVELOPMENT.md             # Full developer setup guide
```

---

## Getting Started (Developers)

For a complete setup guide, see [**DEVELOPMENT.md**](DEVELOPMENT.md).

### Quick Overview

**Prerequisites:** Flutter SDK, Android Studio, Docker Desktop, Git

```bash
# 1. Clone the repo
git clone <repository-url>
cd CLAiR

# 2. Set up environment
cp .env.example .env
# Fill in the .env with values from the team

# 3. Start the backend
docker-compose up -d
docker-compose exec backend alembic upgrade head

# 4. Run the Flutter app
cd frontend
flutter pub get
flutter run
```

The backend API docs will be available at [http://localhost:8000/docs](http://localhost:8000/docs).

### Useful Makefile Commands

| Command | What it does |
|---|---|
| `make up` | Start all Docker services |
| `make down` | Stop all Docker services |
| `make migrate` | Run database migrations |
| `make test-backend` | Run backend tests |
| `make flutter-run` | Run the Flutter app |
| `make flutter-build-apk` | Build an Android APK |
| `make logs` | Follow all service logs |

---

## Design

CLAiR uses a warm, professional color palette designed to feel trustworthy and approachable:

| Color | Hex | Usage |
|---|---|---|
| Dark Brown | `#270708` | Primary text and backgrounds |
| Crimson | `#660810` | Accent, CTAs, highlights |
| Tan | `#D6C0B1` | Secondary elements |
| Off White | `#F1EBEB` | Main background |

**Typography:** [Satoshi Variable](https://www.fontshare.com/fonts/satoshi) — a modern, clean typeface used throughout the app.

---

## Contributing

We follow a **trunk-based branching strategy**:

- `main` — production-ready code
- `develop` — active development branch
- `feature/*` — new features
- `bugfix/*` — bug fixes

```bash
# Start a new feature
git checkout develop && git pull
git checkout -b feature/your-feature-name

# When done, open a PR to develop
```

Please fill out the [pull request template](.github/pull_request_template.md) when submitting changes.

---

## Team

Built  as a project for **CMSC 129** at the **University of the Philippines Cebu**.

| Name | Role |
|---|---|
| **Berk Stephen Cutamora** | Lead Developer & Scrum Master |
| **Joanalyn Cadampog** | Backend Developer & Project Manager |
| **Jimmy Eleazar Mijares** | Frontend Developer (Mobile App) |
| **Rhanzel Eroja** | Frontend Developer (Web Portal) |

---

<div align="center">

*CLAiR — Legal assistance for every Filipino.*

</div>
