default:
    echo "Hello from just!"

# Development: Start frontend (Vite)
dev-frontend:
    @just -f ./frontend/justfile dev

# Development: Start backend (Starlette)
dev-backend:
    @just -f ./backend/justfile dev

# Build frontend for production
build:
    @just -f ./frontend/justfile build

# enter the core developer session
devenv-zell:
    devenv shell bash -- -c "zell"
