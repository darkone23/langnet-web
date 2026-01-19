# Boilerplate Web Template

A modern full-stack web application template with Vite + Starlette, demonstrating a clean separation between frontend and backend.
Built with `nix` & `devenv` for reproducible environments.
Terminal first for taking advantage of agent workflows like `opencode`.

## Features

### Frontend
- Modern build tooling with Vite
- Styling with Tailwind CSS v4 + DaisyUI v5
- HTMX for server-driven interactivity
- Alpine.js for client-side interactivity
- TypeScript support
- Hot module replacement in development

### Backend
- Starlette (ASGI) with Route lists
- ASGI factory compatible with Granian
- Jinja2 templating support
- CLI tools with Click + Rich + sh libraries
- Data processing with Polars and DuckDB
- Dataclass serialization with cattrs
- Async view pattern with run_in_threadpool

### Infrastructure
- Reproducible Nix/devenv environment
- UV for fast Python dependency management
- Bun for fast frontend package management
- Task automation with Just
- Vite proxy for seamless API development

## Quick Start

### Prerequisites
- [Nix](https://nixos.org/download/)
- [devenv](https://devenv.sh/)
- [Git](https://git-scm.com/)

### Setup and Run

```bash
# Enter development environment (all setup is automatic)
devenv shell

# Install frontend dependencies
just build

# Start development servers (frontend + backend)
just dev-frontend
just dev-backend
```

This starts:
- Vite dev server at http://localhost:43210
- Starlette API server at http://localhost:43280

The Vite dev server proxies `/api/*` requests to Starlette automatically.

### Available Commands

```bash
# Development
just dev-frontend     # Start only Vite dev server (port 43210)
just dev-backend      # Start only Starlette dev server (port 43280)

# Build
just build            # Build frontend for production
```

## Project Structure

```
.
├── frontend/                   # Vite + TypeScript frontend
│   ├── src/
│   │   ├── main.ts            # Application entry point
│   │   └── tailwind.css       # Tailwind + DaisyUI styles
│   ├── index.html             # HTML entry point
│   ├── vite.config.ts         # Vite configuration
│   ├── package.json           # Frontend dependencies
│   └── justfile               # Frontend-specific commands
├── backend/                    # Starlette + Python backend
│   ├── boilerplate_app/
│   │   ├── web/
│   │   │   ├── __init__.py    # Starlette app factory
│   │   │   ├── routes.py      # API Route definitions
│   │   │   └── templates/     # Jinja2 templates
│   │   ├── cli.py             # CLI application
│   │   ├── asgi.py            # ASGI entry point
│   │   └── *_example.py       # Demo modules
│   ├── pyproject.toml         # Python package config
│   └── justfile               # Backend-specific commands
├── devenv.nix                  # Development environment
├── devenv.yaml                 # Devenv inputs
├── justfile                    # Root task runner
├── AGENTS.md                   # AI assistant configuration
├── README.md                   # This file
└── DEV.md                      # Developer guide
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Development Mode                         │
├─────────────────────────────────────────────────────────────┤
│  Browser ──► Vite (43210) ──► Starlette API (43280)         │
│              │                    │                          │
│              ├─ Serves index.html  ├─ /api/main-content     │
│              ├─ Injects script    │   (renders Jinja2)      │
│              ├─ Hot reload        ├─ /api/hello-htmx        │
│              ├─ Tailwind/DaisyUI  │   (returns HTML)        │
│              └─ HTMX/Alpine.js    └─ /api/hello (JSON)      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Production Mode                          │
├─────────────────────────────────────────────────────────────┤
│  Browser ──► Granian (43280)                                │
│                  │                                           │
│                  ├─ Serves built frontend/dist/index.html    │
│                  ├─ Serves built frontend/dist/assets/*      │
│                  └─ /api/* routes (renders Jinja2 partials)  │
└─────────────────────────────────────────────────────────────┘

Tailwind v4 scans:
  - frontend/src/* (TypeScript/CSS)
  - frontend/index.html (Vite entry point)
  - backend/boilerplate_app/web/templates/* (Jinja2/HTMX partials)
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend Build | Vite | Fast dev server, optimized builds |
| Styling | Tailwind CSS + DaisyUI | Utility-first CSS with components |
| Server UI Updates | HTMX | Server-driven UI updates |
| Client Behavior | Alpine.js | Client-side behavior |
| Backend | Starlette | Python ASGI web framework |
| ASGI | Granian | Production server |
| CLI | Click + Rich | Command-line interface |
| Data | Polars + DuckDB | Data processing |
| Package Mgmt | UV (Python), Bun (JS) | Fast dependency management |
| Environment | Nix + devenv | Reproducible development |

## API Endpoints

| Endpoint | Method | Response | Description |
|----------|--------|----------|-------------|
| `/api/hello` | GET | JSON | Returns greeting message |
| `/api/hello` | POST | JSON | Returns personalized greeting |
| `/api/hello-htmx` | GET | HTML | Returns HTML partial for HTMX |
| `/api/duckdb-example` | GET | JSON | Returns DuckDB query results |
| `/api/polars-example` | GET | JSON | Returns Polars DataFrame processing results |

## Development

See [DEV.md](./DEV.md) for detailed developer instructions.

### Quick Development Workflow

1. Enter devenv: `devenv shell`
2. Install deps: `cd frontend && bun install && cd ..`
3. Start servers: `just dev`
4. Edit code - changes hot reload automatically
5. Build for production: `just build`

## License

MIT
