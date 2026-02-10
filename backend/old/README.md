# Backend

Starlette-based backend with CLI tools, serving both API endpoints and the production frontend.

## Structure

```
backend/
├── boilerplate_app/
│   ├── web/
│   │   ├── __init__.py        # Starlette app factory
│   │   ├── routes.py          # API Route definitions
│   │   └── templates/         # Jinja2 templates
│   ├── __init__.py
│   ├── cli.py                 # CLI application (Click + Rich)
│   ├── asgi.py                # ASGI entry point
│   ├── cattrs_example.py      # Cattrs serialization demos
│   ├── duckdb_example.py      # DuckDB query demos
│   └── polars_example.py      # Polars DataFrame demos
├── pyproject.toml             # Python package configuration
├── uv.lock                    # UV dependency lockfile
└── justfile                   # Backend-specific commands
```

## Commands

```bash
# From backend/ directory
just dev          # Start Starlette dev server (port 43280)
just run-server   # Start Granian production server
just run-cli      # Run CLI application
just run-custom   # Run CLI with custom message
just run-json     # Run CLI with JSON output
just demo-duckdb  # Run DuckDB demonstration
just demo-polars  # Run Polars demonstration
just demo-cattrs  # Run cattrs demonstration
just uv-sync      # Sync Python dependencies
```

## API Endpoints

| Endpoint | Method | Response | Description |
|----------|--------|----------|-------------|
| `/api/hello` | GET | JSON | Returns `{"message": "Hello from Starlette API!"}` |
| `/api/hello` | POST | JSON | Returns personalized greeting with `name` from body |
| `/api/hello-htmx` | GET | HTML | Returns HTML partial for HTMX consumption |
| `/api/duckdb-example` | GET | JSON | Returns DuckDB query results |
| `/api/polars-example` | GET | JSON | Returns Polars DataFrame processing results |

## Adding New Endpoints

Edit `boilerplate_app/web/routes.py`:

```python
from starlette.responses import JSONResponse, Response
from starlette.routing import Route

async def my_endpoint(request):
    return JSONResponse({'key': 'value'})

async def my_htmx_endpoint(request):
    """Return HTML for HTMX targets"""
    return Response(content='<div class="alert">Content here</div>', media_type='text/html')

api_routes = [
    Route('/my-endpoint', my_endpoint, methods=['GET']),
    Route('/my-htmx-endpoint', my_htmx_endpoint, methods=['GET']),
]
```

## Dependencies

Managed via `pyproject.toml` with UV:

- **starlette**: ASGI web framework
- **granian**: Production ASGI server
- **uvicorn**: Development ASGI server
- **jinja2**: Templating engine
- **click**: CLI framework
- **rich**: Terminal formatting
- **sh**: Subprocess wrapper
- **polars**: DataFrame library
- **duckdb**: In-memory SQL database
- **cattrs**: Dataclass serialization

## Production

In production, Starlette serves the built frontend from `frontend/dist/`:

```bash
# Build frontend first (from root)
just build

# Start production server
just run-server
```
