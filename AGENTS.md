# AGENTS.md

## Project Overview
Full-stack web application with Vite frontend and Flask backend. Nix/devenv-based development environment with reproducible builds. Configuration is declarative via Nix expressions.

## Tech Stack
- **Frontend**: Vite + TypeScript + Tailwind CSS v4 + DaisyUI v5 + HTMX + Alpine.js
- **Backend**: Flask + Blueprint routes + Jinja2 + Gunicorn
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
│   ├── vite.config.ts         # Vite configuration (proxy to Flask)
│   ├── package.json           # Frontend dependencies
│   └── justfile               # Frontend commands
├── backend/                    # Flask backend application
│   ├── boilerplate_app/
│   │   ├── web/
│   │   │   ├── __init__.py    # Flask app factory
│   │   │   ├── routes.py      # API Blueprint routes
│   │   │   └── templates/     # Jinja2 templates
│   │   ├── cli.py             # CLI application
│   │   ├── wsgi.py            # WSGI entry point
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

### Development
- `devenv shell just -- dev` - Start both frontend and backend dev servers
- `devenv shell just -- dev-frontend` - Start Vite dev server (port 43210)
- `devenv shell just -- dev-backend` - Start Flask dev server (port 43280)

### Production
- `devenv shell just -- build` - Build frontend for production
- `devenv shell just -- run` - Start production server with gunicorn

### CLI Tools
- `devenv shell just -- run-cli` - Run CLI application
- `devenv shell just -- run-custom` - Run CLI with custom message
- `devenv shell just -- run-json` - Run CLI with JSON output

### Demos
- `devenv shell just -- demo-duckdb` - Run DuckDB demonstration
- `devenv shell just -- demo-polars` - Run Polars demonstration
- `devenv shell just -- demo-cattrs` - Run cattrs demonstration

### Utilities
- `devenv shell just -- uv-sync` - Sync Python dependencies
- `devenv shell bash -- -c "$somebash"` - Run bash script inside devenv

## Operator Commands

These commands are intended to only be run by the project operator.

- `devenv shell just -- devenv-zell` - Enter developer session with zellij

## Ports
- **43210**: Vite dev server (frontend)
- **43280**: Flask server (backend API)

## API Endpoints
- `GET /api/hello` - Returns JSON greeting
- `POST /api/hello` - Returns personalized JSON greeting
- `GET /api/hello-htmx` - Returns HTML partial for HTMX

## Code Style

### Python
- Use Flask Blueprints for route organization
- Return `jsonify()` for JSON endpoints, HTML strings for HTMX
- Use Click for CLI, `sh` library for subprocess calls, `rich` for pretty printing
- Type hints for function parameters and returns
- snake_case for variables/functions, PascalCase for classes

### TypeScript
- Strict mode enabled
- Import dependencies in main.ts
- Use Tailwind/DaisyUI classes for styling

### Nix
- 2-space indentation, kebab-case attributes, double quotes

## Build/Test
- `devenv shell just -- dev` - Run development servers
- `devenv shell just -- build` - Build frontend for production
- `devenv shell uv -- build` - Build Python package
- No formal test framework configured yet

## Important
- Never try to run dev servers without explicit permission
- Vite proxies /api/* to Flask in development mode
- Production serves frontend from `frontend/dist/`
