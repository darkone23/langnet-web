# Boilerplate CLI Template

A modern Python CLI application template demonstrating `uv` builds with `click`, `rich`, and `sh` library.
Built with `nix` & `devenv` for reproducible environments.
Terminal first for taking advantage of agent workflows like `opencode`

## Features

- Modern CLI interface built with `click` with command groups
- Beautiful terminal output with `rich`
- Subprocess management via `sh` library
- Data processing examples with `polars` and `duckdb`
- Dataclass serialization with `cattrs`
- Agent integration for `opencode`
- Clean JSON output for programmatic use
- Reproducible `nix` & `devenv` environment
- `uv` for fast Python dependency management
- Task automation with `just`

## Quick Start

### Prerequisites
- [Nix](https://nixos.org/download/)
- [devenv](https://devenv.sh/)
- [git](https://git-scm.com/)
- [just](https://just.systems/)

### Setup and Run

```bash
# Enter development environment (all setup is automatic)
devenv shell

# Run default command
just

# Run with custom message
just run-custom

# Run with JSON output
just run-json

# Run demo commands
just demo-duckdb   # DuckDB query examples
just demo-polars   # Polars DataFrame examples
just demo-cattrs   # Cattrs serialization examples

# Direct usage
uv run boilerplate-cli --help
uv run boilerplate-cli run --message "Custom message" --json
```

## CLI Commands and Options

The CLI uses a command group pattern with the following subcommands:

### `run` - Main application command
- `--message TEXT`: Message to display (default: "Hello, World!")
- `--json`: Output parsable JSON instead of formatted output

### `demo-duckdb` - DuckDB demonstration
Runs sample DuckDB queries showing in-memory database operations.

### `demo-polars` - Polars demonstration
Demonstrates Polars DataFrame operations including filtering, sorting, and aggregation.

### `demo-cattrs` - Cattrs demonstration
Shows cattrs dataclass serialization/deserialization examples.

## Examples

### Basic Usage

```bash
# Default hello world
uv run boilerplate-cli run

# Custom message
uv run boilerplate-cli run --message "Hello from boilerplate!"

# Run demos
uv run boilerplate-cli demo-duckdb
uv run boilerplate-cli demo-polars
uv run boilerplate-cli demo-cattrs
```

### JSON Output for Scripting

```bash
# Clean JSON output for piping to json tools
just run-json | ...

# Output to file
just run-json > output.json
```

## Project Structure

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
├── README.md               # This file
└── DEV.md                  # Developer guide
```

## Architecture

- **CLI Layer**: Click-based command group interface with subcommands
- **Output Layer**: Rich for formatted display, JSON for machine consumption
- **System Integration**: sh library for subprocess calls
- **Data Processing**: Polars for DataFrames, DuckDB for SQL queries
- **Serialization**: cattrs for dataclass serialization/deserialization
- **Environment**: Nix/devenv for reproducible development
- **Package Manager**: UV for Python dependency management

## Development

See [DEV.md](./DEV.md) for developer instructions and contribution guidelines.

## License

MIT
