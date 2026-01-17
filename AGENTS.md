# AGENTS.md

## Project Overview
Nix/devenv-based development environment with Click-based Python CLI application demonstrating modern Python tooling. Configuration is declarative via Nix expressions.

## Code Structure
```
.
├── boilerplate_app/        # Python application directory
│   ├── __init__.py
│   ├── cli.py              # Main CLI application with command group
│   ├── cattrs_example.py   # Cattrs serialization examples
│   ├── duckdb_example.py   # DuckDB query examples
│   └── polars_example.py   # Polars DataFrame examples
├── justfile                # Just task runner recipes
├── devenv.nix              # Development environment configuration
├── devenv.yaml             # Devenv inputs configuration
├── pyproject.toml          # Python package configuration
├── uv.lock                 # UV dependency lockfile
├── devenv.lock             # Devenv environment lockfile
├── .envrc                  # Direnv configuration
├── .gitignore              # Git ignore rules
├── AGENTS.md               # AI assistant configuration
├── README.md               # User documentation
└── DEV.md                  # Developer guide
```

## Available Commands

These commands may be run for project automation.

- `devenv shell just` - Run default task (boilerplate CLI with default message)
- `devenv shell just -- run` - Run boilerplate CLI with default settings
- `devenv shell just -- run-custom` - Run boilerplate CLI with custom message
- `devenv shell just -- run-json` - Run boilerplate CLI and output parsable JSON
- `devenv shell just -- demo-duckdb` - Run DuckDB demonstration queries
- `devenv shell just -- demo-polars` - Run Polars DataFrame demonstration
- `devenv shell just -- demo-cattrs` - Run cattrs serialization demonstration
- `devenv shell bash -- -c "$somebash"` - Run bash script inside of devenv

## Operator Commands

These commands are intended to only be run by the project operator.

- `devenv shell just -- devenv-zell` - Enter developer session with zellij

## Code Style
- **Python**: Use Click for CLI, `sh` library for subprocess calls, `rich` for pretty printing
- **Nix**: 2-space indentation, kebab-case attributes, double quotes
- **Imports**: Standard library first, then third-party, then local
- **Error handling**: Use try/except blocks with specific exceptions
- **Naming**: snake_case for variables/functions, PascalCase for classes
- **Type hints**: Use proper type annotations for function parameters and returns

## Build/Test
- `devenv shell just -- $justcmd` - Run $justcmd inside devenv shell.
- `devenv shell uv -- build` - Build package (run within devenv shell)
- No formal test framework configured yet

## CLI Options
- `--message TEXT`: Message to display (default: "Hello, World!")
- `--json`: Output parsable JSON instead of formatted output
