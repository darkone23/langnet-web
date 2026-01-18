# Boilerplate Web Template

A modern full-stack web application template with Vite + Flask, demonstrating a clean separation between frontend and backend.
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
- Flask with Blueprint-based API routes
- WSGI factory compatible with gunicorn
- Jinja2 templating support
- CLI tools with Click + Rich + sh libraries
- Data processing with Polars and DuckDB
- Dataclass serialization with cattrs

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
cd frontend && bun install && cd ..

# Start development servers (frontend + backend)
just dev
```

This starts:
- Vite dev server at http://localhost:43210
- Flask API server at http://localhost:43280

The Vite dev server proxies `/api/*` requests to Flask automatically.

### Available Commands

```bash
# Development
just dev              # Start both frontend and backend dev servers
just dev-frontend     # Start only Vite dev server (port 43210)
just dev-backend      # Start only Flask dev server (port 43280)

# Production
just build            # Build frontend for production
just run              # Start production server with gunicorn

# CLI Tools
just run-cli          # Run CLI application
just run-custom       # Run CLI with custom message
just run-json         # Run CLI with JSON output

# Demos
just demo-duckdb      # DuckDB query examples
just demo-polars      # Polars DataFrame examples
just demo-cattrs      # Cattrs serialization examples
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
├── backend/                    # Flask + Python backend
│   ├── boilerplate_app/
│   │   ├── web/
│   │   │   ├── __init__.py    # Flask app factory
│   │   │   ├── routes.py      # API Blueprint routes
│   │   │   └── templates/     # Jinja2 templates
│   │   ├── cli.py             # CLI application
│   │   ├── wsgi.py            # WSGI entry point
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
│  Browser ──► Vite (43210) ──► Flask API (43280)             │
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
│  Browser ──► Gunicorn (43280)                                │
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
| Backend | Flask | Python web framework |
| WSGI | Gunicorn | Production server |
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
