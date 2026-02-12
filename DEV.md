# Developer Guide

This document provides instructions for developers working on this full-stack web application template.

## Current Project Status

This is a fully functional full-stack web application template with the following characteristics:

- **Frontend**: Vite + TypeScript + Tailwind CSS + DaisyUI + HTMX + Alpine.js
- **Backend**: Zig 0.15.x (post-writergate) + zzz HTTP framework + Mustache templates + DuckDB
- **Environment**: Nix/devenv + Bun (JavaScript)
- **Task Automation**: Just (justfiles in root, backend, and frontend)

## Development Environment Setup

### Prerequisites

- [Nix](https://nixos.org/download/)
- [devenv](https://devenv.sh/)
- [Git](https://git-scm.com/)
- Zig 0.15.x (automatically managed by devenv)

**Important Note:** This project uses Zig 0.15.x with the "post-writergate" standard library. The writergate was a major change to Zig's standard library that improved async I/O and error handling patterns. If you're coming from older Zig versions, be aware of:
- Updated async/await patterns (using `zig 0.15.x` async model)
- Changes to std.http and related networking modules
- Updated error union conventions
- New allocator APIs

### Environment Activation

```bash
# Clone the repository
git clone <repository-url>
cd <repository-name>

# Enter development environment
devenv shell

# Install frontend dependencies
cd frontend && bun install && cd ..

# Enter developer zellij session (optional but recommended)
just devenv-zell
```

**Important Note:** Devenv manages both Python (via UV) and JavaScript (via Bun) environments automatically. There's no need to manually activate virtual environments or install global packages.

### Verifying the Environment

```bash
# Check all tools are available
which python    # Should show devenv's python
which uv        # Should show devenv's uv
which bun       # Should show devenv's bun
which node      # Should show devenv's node

# Test Python dependencies
uv run python -c "import starlette, click, rich, duckdb, polars, cattrs; print('Python deps OK')"

# Test frontend dependencies
cd frontend && bun run build && cd ..
```

## Project Structure

```
.
├── frontend/                   # Frontend application
│   ├── src/
│   │   ├── main.ts            # Application entry point
│   │   └── tailwind.css       # Tailwind + DaisyUI imports
│   ├── public/                # Static assets
│   ├── dist/                  # Build output (served by Zig in production)
│   ├── index.html             # HTML entry point
│   ├── vite.config.ts         # Vite configuration
│   ├── tsconfig.json          # TypeScript configuration
│   ├── package.json           # Frontend dependencies
│   ├── bun.lock               # Bun lockfile
│   └── justfile               # Frontend commands
├── backend/                    # Backend application
│   ├── src/
│   │   ├── main.zig           # Application entry point
│   │   ├── routes.zig         # API Route definitions
│   │   ├── config.zig         # Configuration management
│   │   ├── template.zig       # Template cache and rendering
│   │   └── root.zig           # Module exports
│   ├── templates/             # Mustache templates (HTMX partials)
│   │   ├── main_content.html  # Main page content
│   │   └── hello_htmx.html    # HTMX partial template
│   ├── build.zig              # Zig build configuration
│   ├── build.zig.zon          # Zig dependencies
│   └── justfile               # Backend commands
├── devenv.nix                  # Nix development environment
├── devenv.yaml                 # Devenv inputs
├── devenv.lock                 # Devenv lockfile
├── justfile                    # Root task runner
├── .envrc                      # Direnv configuration
├── .gitignore                  # Git ignore rules
├── AGENTS.md                   # AI assistant configuration
├── README.md                   # User documentation
└── DEV.md                      # This developer guide
```

## Development Workflow

### Starting Development Servers

```bash
# Start both frontend and backend (recommended)
just dev-frontend
just dev-backend

# Or start them separately in different terminals:
just dev-frontend    # Vite at http://localhost:5173
just dev-backend     # Zig at http://localhost:43210
```

The Vite dev server proxies all `/api/*` requests to Zig, so you can develop the full stack from `http://localhost:5173`.

### Making Frontend Changes

1. Edit files in `frontend/src/`
2. Changes hot reload automatically
3. Tailwind classes are processed on-the-fly
4. TypeScript errors show in the browser console

```bash
# Frontend-specific commands
cd frontend
bun run dev      # Start dev server
bun run build    # Build for production
bun run preview  # Preview production build
```

### Making Backend Changes

1. Edit files in `backend/src/`
2. Zig dev server auto-reloads on file changes (restart required)
3. Test API endpoints at `http://localhost:43210/api/*`

```bash
# Backend-specific commands (from backend/ directory)
just dev         # Start Zig dev server
just run-server  # Start Zig production server
just test        # Run Zig tests
```

### Adding API Endpoints

Edit `backend/src/routes.zig`:

```zig
const std = @import("std");

fn myEndpoint(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = "{\"data\":\"value\"}",
    });
}

fn myHtmxEndpoint(ctx: *const Context, _: void) !Respond {
    // Return HTML partial for HTMX
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = "<div class=\"alert alert-info\">Hello from HTMX!</div>",
    });
}

// Add to createRouter function:
Route.init("/my-endpoint").get({}, myEndpoint).layer(),
Route.init("/my-htmx-endpoint").get({}, myHtmxEndpoint).layer(),
```

### Adding Frontend Interactivity

Use HTMX for server-driven updates:

```html
<button hx-get="/api/my-htmx-endpoint" hx-target="#result">
  Load Content
</button>
<div id="result"></div>
```

Use Alpine.js for client-side interactivity:

```html
<div x-data="{ count: 0 }">
  <button x-on:click="count++">Increment</button>
  <span>Count: <span x-text="count"></span></span>
</div>
```

## Building for Production

```bash
# Build frontend
just build

# The built files are output to frontend/dist/
# Zig serves these automatically in production mode

# Start production server
cd backend
just run-server
```

## Code Architecture

### Frontend vs Backend HTML Relationship

The project has two different HTML files serving distinct purposes:

| File | Purpose | When Used |
|------|---------|-----------|
| `frontend/index.html` | Vite dev server entry point | Development only |
| `backend/templates/main_content.html` | Main content template | HTMX partial rendering |

**Development Flow:**
1. Vite dev server serves `frontend/index.html` at port 5173
2. Vite injects the script tag (`<script type="module" src="/src/main.ts"></script>`) for hot module replacement
3. Tailwind CSS v4 scans both frontend source (`@source ".."`) and backend templates (`@source "../../backend/templates"`)
4. Backend templates (`main_content.html`, `hello_htmx.html`) are served as HTMX partials via `/api/main-content` and `/api/hello-htmx`

**Production Flow:**
1. `bun run build` generates optimized files to `frontend/dist/`
2. Zig serves the built `index.html` from `frontend/dist/` at port 43210
3. Zig routes `/assets/*` and `/vite.svg` to static files
4. HTMX endpoints render Mustache templates as HTML partials

**Important Notes:**
- Backend templates are rendered dynamically by route handlers (e.g., `/api/main-content`)
- Only the built `frontend/dist/index.html` is served to users in production
- Tailwind scans backend templates to generate CSS for classes used in Mustache/HTMX responses
- HTMX partials return HTML snippets that replace/update page sections

### Frontend Components

| File | Purpose |
|------|---------|
| `index.html` | HTML entry point with app mount |
| `src/main.ts` | Application initialization, HTMX setup |
| `src/tailwind.css` | Tailwind CSS + DaisyUI imports |
| `vite.config.ts` | Dev server, proxy, build configuration |

### Backend Components

| File | Purpose |
|------|---------|
| `main.zig` | Application entry point, server initialization |
| `routes.zig` | API Route definitions with handlers |
| `config.zig` | Configuration management (env vars) |
| `template.zig` | Template cache and Mustache rendering |
| `root.zig` | Module exports |

### Request Flow

```
Development:
  Browser → Vite (5173) → [serves frontend/index.html]
                      → [injected script tag → main.ts]
                      → /api/* → Zig (43210) → [renders Mustache templates]

Production:
  Browser → Zig (43210) → [serves frontend/dist/index.html]
                       → [serves frontend/dist/assets/*]
                       → /api/* → [renders Mustache templates as HTML partials]

Tailwind v4:
  Scans: frontend/src/*, frontend/index.html, backend/templates/*
  Output: optimized CSS bundle
```

## Code Style

### Zig (0.15.x Post-Writergate)
- Use zzz Route lists for route organization
- Return JSON strings for JSON endpoints (TODO: use proper JSON library)
- Return HTML content for HTMX endpoints
- Use async/await via Tardy runtime
- Use `!` for error returns
- Use `defer` for resource cleanup
- Use type hints for function parameters and returns
- camelCase for functions, PascalCase for types, snake_case for variables

**Zig 0.15.x Notes:**
- Standard library uses post-writergate I/O model
- Use `std.http` for HTTP clients (if needed)
- Allocator APIs follow new conventions
- Error union syntax: `!T` for error unions
- Async/await uses updated syntax

### TypeScript
- Use strict mode (configured in tsconfig.json)
- Import HTMX and initialize in main.ts
- Use Tailwind/DaisyUI classes for styling

### Nix
- 2-space indentation
- kebab-case for attribute names
- Double quotes for strings

## Testing

### Manual Testing

```bash
# Test API directly
curl http://localhost:43210/api/hello
curl http://localhost:43210/api/hello-htmx
curl http://localhost:43210/api/health
curl http://localhost:43210/api/duckdb-example
```

### Demo Commands

```bash
cd backend
just test-server    # Run server integration tests
just test-db        # Run DuckDB endpoint tests
just test           # Run Zig tests
```

## Troubleshooting

### Frontend Issues

**Vite won't start:**
```bash
cd frontend
bun install    # Reinstall dependencies
bun run dev    # Try again
```

**Tailwind styles not applying:**
- Ensure `@import "tailwindcss"` is in `tailwind.css`
- Ensure `@plugin "daisyui"` is in `tailwind.css`
- Check that `tailwind.css` is imported in `main.ts`

**HTMX not working:**
- Check browser console for errors
- Ensure `htmx.org` is imported in `main.ts`
- Verify API endpoint returns HTML (not JSON) for HTMX targets

### Backend Issues

**Import errors:**
```bash
# Ensure you're in devenv shell
devenv shell

# Verify Zig is available
zig version
```

**Zig won't start:**
```bash
cd backend
just dev    # Check error output
```

**API proxy not working:**
- Ensure Zig is running on port 43210
- Check Vite proxy config in `vite.config.ts`
- Look for CORS errors in browser console
- Verify frontend is at http://localhost:5173

### Environment Issues

**devenv fails to build:**
```bash
rm -rf .devenv
devenv shell
```

**Dependencies out of sync:**
```bash
# JavaScript
cd frontend && bun install && cd ..

# Zig (fetch dependencies)
cd backend && zig fetch && cd ..
```

## Ports Reference

| Service | Port | Purpose |
|---------|------|---------|
| Vite | 5173 | Frontend dev server |
| Zig | 43210 | Backend API server |

## Adding Dependencies

### Zig Dependencies

Add dependencies to `backend/build.zig.zon`:

```zig
.{
    .name = "backend",
    .version = "0.0.0",
    .dependencies = .{
        .mustache = .{
            .url = "git+https://github.com/batiati/mustache-zig#<version>",
            .hash = "<hash>",
        },
        .zzz = .{
            .url = "git+https://github.com/tardy-org/zzz#<version>",
            .hash = "<hash>",
        },
        // Add new dependencies here
    },
}
```

Then fetch the dependency:
```bash
cd backend
zig fetch
```

### JavaScript Dependencies

```bash
cd frontend
bun add <package-name>        # Runtime dependency
bun add -d <package-name>     # Dev dependency
```

## Next Steps

### Potential Enhancements

1. **Testing**: Add zig test (backend) and vitest (frontend)
2. **Authentication**: Add authentication if/when users are needed
3. **Database**: Consider DuckDB for production or add PostgreSQL
4. **Deployment**: Add Docker configuration
5. **CI/CD**: Add GitHub Actions workflow
6. **JSON Library**: Add proper JSON serialization library for backend
