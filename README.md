# langnet-web

A modern full-stack web application template with Vite + zig, demonstrating a clean separation between frontend and backend.
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
- Zig 0.15.x (post-writergate standard library)
- Zig web server with zzz HTTP framework
- Mustache templates for server-side rendering
- DuckDB via zuckdb for embedded database
- Template caching for performance

### Infrastructure
- Reproducible Nix/devenv environment
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
- Vite dev server at http://localhost:5173
- Zig API server at http://localhost:43210

The Vite dev server proxies `/api/*` requests to Zig automatically.

### Available Commands

```bash
# Development
just dev-frontend     # Start only Vite dev server (port 5173)
just dev-backend      # Start only Zig dev server (port 43210)

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
├── backend/                    # zig backend
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
│  Browser ──► Vite (5173) ──► Zig API (43210)           │
│              │                    │                          │
│              ├─ Serves index.html  ├─ /api/main-content     │
│              ├─ Injects script    │   (renders Mustache)    │
│              ├─ Hot reload        ├─ /api/hello-htmx        │
│              ├─ Tailwind/DaisyUI  │   (returns HTML)        │
│              └─ HTMX/Alpine.js    └─ /api/hello (JSON)      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Production Mode                          │
├─────────────────────────────────────────────────────────────┤
│  Browser ──► Zig Server (43210)                             │
│                  │                                           │
│                  ├─ Serves built frontend/dist/index.html    │
│                  ├─ Serves built frontend/dist/assets/*      │
│                  └─ /api/* routes (renders Mustache partials) │
└─────────────────────────────────────────────────────────────┘

Tailwind v4 scans:
  - frontend/src/* (TypeScript/CSS)
  - frontend/index.html (Vite entry point)
  - backend/templates/* (Mustache/HTMX partials)
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend Build | Vite | Fast dev server, optimized builds |
| Styling | Tailwind CSS + DaisyUI | Utility-first CSS with components |
| Server UI Updates | HTMX | Server-driven UI updates |
| Client Behavior | Alpine.js | Client-side behavior |
| Backend | Zig + zzz HTTP framework | Web server and API |
| Templates | Mustache | Server-side HTML rendering |
| Database | DuckDB | Embedded analytics database |
| Environment | Nix + devenv | Reproducible development |

## API Endpoints

| Endpoint | Method | Response | Description |
|----------|--------|----------|-------------|
| `/api/hello` | GET | JSON | Returns greeting message |
| `/api/hello` | POST | JSON | Returns personalized greeting |
| `/api/hello-htmx` | GET | HTML | Returns HTML partial for HTMX |
| `/api/duckdb-example` | GET | JSON | Returns DuckDB query results |
| `/api/health` | GET | JSON | Health check endpoint |
| `/api/main-content` | GET | HTML | Returns main content partial |

## Zig 0.15.x Post-Writergate

This project uses Zig 0.15.x with the post-writergate standard library. The writergate was a major change that improved Zig's async I/O model and standard library architecture.

**Key Features:**
- Updated async/await patterns with new runtime model
- Improved `std.http` and networking modules
- New allocator API conventions
- Updated error handling patterns
- Better resource management with `defer`

**References:**
- [Zig 0.15.x Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)
- [Zig Standard Library Documentation](https://ziglang.org/documentation/master/std/)
- [zzz HTTP Framework Docs](https://github.com/tardy-org/zzz)

## Development

See [DEV.md](./DEV.md) for detailed developer instructions.

### Organized Documentation

Comprehensive documentation is now organized in the [`docs/`](./docs/) directory:

- **[docs/INDEX.md](./docs/INDEX.md)** - Documentation index and quick links
- **[docs/VITE.md](./docs/VITE.md)** - Vite configuration guide
- **[docs/HTMX_ALPINE.md](./docs/HTMX_ALPINE.md)** - HTMX + Alpine.js patterns
- **[docs/DAISYUI_TAILWIND.md](./docs/DAISYUI_TAILWIND.md)** - Tailwind CSS v4 + DaisyUI v5 guide
- **[docs/ZIG_BACKEND.md](./docs/ZIG_BACKEND.md)** - Zig backend development patterns
- **[docs/ZIG_0.15_NOTES.md](./docs/ZIG_0.15_NOTES.md)** - Zig 0.15.x post-writergate migration guide

These guides provide in-depth coverage of each technology and operational aspect.

### Quick Development Workflow

1. Enter devenv: `devenv shell`
2. Install deps: `cd frontend && bun install && cd ..`
3. Start servers: `just dev-frontend` and `just dev-backend`
4. Access frontend at http://localhost:5173
5. Edit code - changes hot reload automatically
6. Build for production: `just build`

## License

MIT
