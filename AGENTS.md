# AGENTS.md

## Project Overview
Full-stack web application with Vite frontend and Zig backend. Nix/devenv-based development environment with reproducible builds. Configuration is declarative via Nix expressions.

## Tech Stack
- **Frontend**: Vite + TypeScript + Tailwind CSS v4 + DaisyUI v5 + HTMX + Alpine.js
- **Backend**: Zig 0.15.x (post-writergate) + zzz HTTP framework + Mustache templates + DuckDB
- **Data**: DuckDB (embedded analytics database)
- **Environment**: Nix + devenv + Bun

## Code Structure
```
.
├── frontend/                   # Vite frontend application
│   ├── src/
│   │   ├── main.ts            # Application entry point
│   │   └── tailwind.css       # Tailwind + DaisyUI styles
│   ├── public/                # Static assets
│   ├── index.html             # HTML entry point
│   ├── vite.config.ts         # Vite configuration (proxy to Zig backend)
│   ├── package.json           # Frontend dependencies
│   └── justfile               # Frontend commands
├── backend/                    # zig backend application
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

### Utilities
- `devenv shell bash -- -c "$somebash"` - Run bash script inside devenv

## Operator Commands

These commands are intended to only be run by the project operator.

### Development
- `devenv shell just -- -f ./justfile dev-frontend` - Start Vite dev server (port 5173)
- `devenv shell just -- -f ./justfile dev-backend` - Start Zig dev server (port 43210)
- `devenv shell just -- -f ./backend/justfile run-server` - Start Zig production server
- `devenv shell just -- devenv-zell` - Enter developer session with zellij

## Ports
- **5173**: Vite dev server (frontend)
- **43210**: Zig server (backend API)

## API Endpoints
- `GET /api/hello` - Returns JSON greeting
- `POST /api/hello` - Returns personalized JSON greeting
- `GET /api/hello-htmx` - Returns HTML partial for HTMX
- `GET /api/health` - Health check endpoint
- `GET /api/duckdb-example` - Returns DuckDB query results as JSON
- `GET /api/main-content` - Returns main content HTML partial

## Code Style

### TypeScript
- Strict mode enabled
- Import dependencies in main.ts
- Use Tailwind/DaisyUI classes for styling

### Zig
- 2-space indentation
- camelCase for functions, PascalCase for types, snake_case for variables
- Use `!` for error returns
- Use `defer` for resource cleanup

### Nix
- 2-space indentation, kebab-case attributes, double quotes

## Build/Test
- `devenv shell just -- dev` - Run development servers
- `devenv shell just -- build` - Build frontend for production
- No formal test framework configured yet

## Important
- Never try to run dev servers without explicit permission
- Vite proxies /api/* to Zig backend in development mode
- Production serves frontend from `frontend/dist/`
- Use justfiles to run command (they manage working directories)
