# AGENTS.md

## Project Overview
Full-stack web application with Vite frontend and Starlette backend. Nix/devenv-based development environment with reproducible builds. Configuration is declarative via Nix expressions.

## Tech Stack
- **Frontend**: Vite + TypeScript + Tailwind CSS v4 + DaisyUI v5 + HTMX + Alpine.js
- **Backend**: Starlette (ASGI) + Route lists + Jinja2 + Granian
- **CLI**: Click + Rich + sh libraries
- **Data**: Polars + DuckDB + cattrs
- **Package Management**: UV (Python), Bun (JavaScript)
- **Environment**: Nix + devenv

## Code Structure
```
.
├── frontend/                   # Vite frontend application
│   ├── src/
│   │   ├── main.ts            # Application entry point
│   │   └── tailwind.css       # Tailwind + DaisyUI styles
│   ├── public/                # Static assets
│   ├── index.html             # HTML entry point
│   ├── vite.config.ts         # Vite configuration (proxy to Starlette)
│   ├── package.json           # Frontend dependencies
│   └── justfile               # Frontend commands
├── backend/                    # Starlette backend application
│   ├── boilerplate_app/
│   │   ├── web/
│   │   │   ├── __init__.py    # Starlette app factory
│   │   │   ├── routes.py      # API Route definitions
│   │   │   └── templates/     # Jinja2 templates
│   │   ├── cli.py             # CLI application
│   │   ├── asgi.py            # ASGI entry point
│   │   └── *_example.py       # Demo modules
│   ├── pyproject.toml         # Python package config
│   └── justfile               # Backend commands
├── devenv.nix                  # Development environment
├── devenv.yaml                 # Devenv inputs
├── justfile                    # Root task runner
├── AGENTS.md                   # AI assistant configuration
├── README.md                   # User documentation
└── DEV.md                      # Developer guide
```

## Available Commands

These commands may be run for project automation.


### Frontend
- `devenv shell just -- -f ./justfile build` - Build frontend for production
- `devenv shell just -- -f ./frontend/justfile install` - Install bun dependencies
- `devenv shell just -- -f ./frontend/justfile clean` - Remove dist/ directory
- `devenv shell just -- -f ./frontend/justfile preview` - Preview production build

### CLI Tools
- `devenv shell just -- -f ./backend/justfile run-cli` - Run CLI application
- `devenv shell just -- -f ./backend/justfile run-custom` - Run CLI with custom message
- `devenv shell just -- -f ./backend/justfile run-json` - Run CLI with JSON output

### Demos
- `devenv shell just -- -f ./backend/justfile demo-duckdb` - Run DuckDB demonstration
- `devenv shell just -- -f ./backend/justfile demo-polars` - Run Polars demonstration
- `devenv shell just -- -f ./backend/justfile demo-cattrs` - Run cattrs demonstration

### Utilities
- `devenv shell just -- -f ./backend/justfile uv-sync` - Sync Python dependencies
- `devenv shell bash -- -c "$somebash"` - Run bash script inside devenv

## Operator Commands

These commands are intended to only be run by the project operator.

### Development
- `devenv shell just -- -f ./justfile dev-frontend` - Start Vite dev server (port 43210)
- `devenv shell just -- -f ./justfile dev-backend` - Start Starlette dev server (port 43280)
- `devenv shell just -- -f ./backend/justfile run-server` - Start production server with Granian
- `devenv shell just -- devenv-zell` - Enter developer session with zellij

## Ports
- **43210**: Vite dev server (frontend)
- **43280**: Starlette server (backend API)

## API Endpoints
- `GET /api/hello` - Returns JSON greeting
- `POST /api/hello` - Returns personalized JSON greeting
- `GET /api/hello-htmx` - Returns HTML partial for HTMX
- `GET /api/duckdb-example` - Returns DuckDB query results as JSON
- `GET /api/polars-example` - Returns Polars DataFrame processing results as JSON

## Code Style

### Python
- Use Starlette Route lists for route organization
- Return `JSONResponse` for JSON endpoints, HTML strings for HTMX
- Use Click for CLI, `sh` library for subprocess calls, `rich` for pretty printing
- Type hints for function parameters and returns
- snake_case for variables/functions, PascalCase for classes
- Use `request.app.state.db` for database access (no flask.g or flask.current_app)
- Use `run_in_threadpool` for blocking operations like DuckDB queries

### TypeScript
- Strict mode enabled
- Import dependencies in main.ts
- Use Tailwind/DaisyUI classes for styling

### Nix
- 2-space indentation, kebab-case attributes, double quotes

## Build/Test
- `devenv shell just -- dev` - Run development servers
- `devenv shell just -- build` - Build frontend for production
- No formal test framework configured yet

## Important
- Never try to run dev servers without explicit permission
- Vite proxies /api/* to Starlette in development mode
- Production serves frontend from `frontend/dist/`
- Use justfiles to run command (they manage working directories)
