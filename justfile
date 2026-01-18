default:
    @just dev

# Development: Start both frontend and backend
dev:
    @just dev-frontend & just dev-backend & wait

# Development: Start frontend (Vite)
dev-frontend:
    @just -f ./frontend/justfile dev

# Development: Start backend (Flask)
dev-backend:
    @just -f ./backend/justfile dev

# Build: Build frontend for production
build:
    @cd frontend && bun run build

# Run: Start production Flask app with gunicorn
run:
    @just -f ./backend/justfile run-server

# Run: Start CLI application
run-cli:
    @just -f ./backend/justfile run-cli

run-custom:
    @just -f ./backend/justfile run-custom

run-json:
    @just -f ./backend/justfile run-json

demo-duckdb:
    @just -f ./backend/justfile demo-duckdb

demo-polars:
    @just -f ./backend/justfile demo-polars

demo-cattrs:
    @just -f ./backend/justfile demo-cattrs

uv-sync:
    @just -f ./backend/justfile uv-sync

# enter the core developer session
devenv-zell:
    devenv shell bash -- -c "zell"
