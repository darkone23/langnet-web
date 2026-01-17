# Developer Guide

This document provides instructions for developers working on this boilerplate CLI template.

## Current Project Status

This is a fully functional Python CLI application template with the following characteristics:

✅ **Complete Implementation**: CLI tool with modern Python tooling  
✅ **Modern Stack**: Click + Rich + sh libraries  
✅ **Reproducible Environment**: Nix/devenv + UV for dependency management  
✅ **Multiple Output Formats**: Rich formatting and JSON output  
✅ **Error Handling**: Robust exception management  
✅ **Task Automation**: Justfile for common commands  
✅ **Package Configuration**: Proper pyproject.toml setup  
✅ **AI Integration**: Opencode agent configuration  

## Development Environment Setup

### Prerequisites

- [Nix](https://nixos.org/download/)
- [devenv](https://devenv.sh/)
- [Git](https://git-scm.com/)
- [just](https://just.systems)

### Environment Activation

```bash
# Clone the repository
git clone <repository-url>
cd <repository-name>

# Enter development zellij session
#   (activates uv automatically)
just devenv-zell

# zellij is particularly useful because of its persistent shell sessions
# see https://zellij.dev/ for more
```

**Important Note:** Devenv uses `uv` for Python environment management, not traditional virtualenvs. There's no need to manually activate virtual environments or set `PYTHONPATH`. The `devenv shell` command handles everything automatically.

### Verifying the Environment

Once inside the developer session:

```bash
# Check Python environment
echo "Python location: $(which python)"
echo "UV location: $(which uv)"

# Test dependencies (should work)
uv run python -c "import click, sh, rich, duckdb, polars, cattrs; print('✅ All dependencies available')"

# Test the application
uv run boilerplate-cli --help
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
├── README.md               # User documentation
└── DEV.md                  # This developer guide
```

## Code Architecture

### Main Components

1. **CLI Interface** (`boilerplate_app/cli.py`)
     - Click command group with subcommands (`run`, `demo-duckdb`, `demo-polars`, `demo-cattrs`)
     - Main entry point and argument parsing
     - Output formatting logic
     - Error handling with custom AppError exception

2. **System Integration** (`get_system_info()`)
     - Subprocess calls using `sh` library
     - System information gathering
     - Error handling for subprocess failures

3. **Output Handlers**
     - `format_output()`: Rich-formatted human-readable output
     - JSON output: Machine-parseable JSON strings
     - Debug output to stderr

4. **Data Processing Examples**
     - `duckdb_example.py`: In-memory SQL queries with DuckDB
     - `polars_example.py`: DataFrame operations with Polars
     - `cattrs_example.py`: Dataclass serialization/deserialization

5. **Environment Management**
     - Nix/devenv for reproducible development
     - UV for Python dependency management
     - Justfile for task automation

### Key Functions

- `get_system_info()`: Gathers system information using sh library
- `format_output(message, system_info)`: Formats output with Rich panels
- `app()`: Click command group handler
- `run()`: Main CLI run command
- `demo_duckdb()`: DuckDB demonstration command
- `demo_polars()`: Polars demonstration command
- `demo_cattrs()`: Cattrs demonstration command
- `AppError`: Custom exception for application errors

### Technical Implementation

- **CLI Framework**: Click with comprehensive help and options
- **Subprocess Management**: sh library with proper error handling
- **Terminal Formatting**: Rich library for beautiful output
- **Type Hints**: Full type annotations for better code quality
- **Error Handling**: Specific exceptions with detailed error messages

## Development Workflow

### Making Changes

1. **Enter development environment** (if not already):
    ```bash
    just devenv-zell
    ```

2. **Make your changes** to the source code in `boilerplate_app/cli.py`

3. **Test your changes**:
    ```bash
    # Test basic functionality
    just run

    # Test JSON output
    just run-json

    # Test with custom message
    uv run boilerplate-cli --message "Test message"
    ```

### Testing and Verification

The project provides multiple testing approaches:

```bash
# Test all main commands
just run                    # Default command
just run-custom             # Custom message
just run-json               # JSON output

# Test demo commands
just demo-duckdb            # DuckDB demonstration
just demo-polars            # Polars demonstration
just demo-cattrs            # Cattrs demonstration

# Test error handling
uv run boilerplate-cli run --message "test"

# Verify environment
uv run python -c "import click, sh, rich, duckdb, polars, cattrs; print('✅ All dependencies available')"

# Build package
uv build
```

### Code Style

- **Python**: Follow PEP 8
- **Imports**: Standard library first, then third-party, then local
- **Error handling**: Use specific exceptions with try/except blocks
- **Type hints**: Use proper type annotations
- **Naming**: snake_case for variables/functions, PascalCase for classes
- **Documentation**: Docstrings for all functions and classes

### Dependencies

All dependencies are managed by `devenv` and defined in `devenv.nix` and `pyproject.toml`:

- **Python**: 3.13 (or latest)
- **Click**: CLI framework
- **Rich**: Terminal formatting and colorization
- **sh**: subprocess wrapper
- **DuckDB**: In-memory SQL database
- **Polars**: Fast DataFrame library
- **cattrs**: Dataclass serialization/deserialization
- **uv**: Python package manager
- **hatchling**: Build backend

### Environment Management

**Important:** Devenv uses `uv` for Python package management, not traditional virtualenvs. This means:

- No `.venv/` directories or `activate` scripts
- Dependencies are managed through Nix store paths
- Use `uv run` instead of direct Python execution
- The environment is automatically activated via `devenv shell`

Example workflow:
```bash
# Correct ✅
just devenv-zell
uv run boilerplate-cli --json
uv build

# Incorrect ❌ (no traditional venv to activate)
source .venv/activate  # This doesn't exist
python boilerplate_app/cli.py  # Dependencies not found
```

### Build and Package Management

```bash
# Build package within devenv shell (no zellij session)
devenv shell
uv build

# Install locally
pip install .

# Check package info
pip show boilerplate-cli
```

## Debugging

### Common Issues

1. **Import Errors**: Ensure you're inside `devenv shell`
    ```bash
    # Check if you're in the right environment
    which python  # Should show devenv's python
    which uv     # Should show devenv's uv
    
    # Test dependencies
    uv run python -c "import click, sh, rich, duckdb, polars, cattrs; print('Dependencies OK')"
    ```

2. **Missing Dependencies**: devenv should handle all dependencies automatically
    - If you see import errors, use `uv run` instead of direct `python`
    - Never manually set PYTHONPATH or activate virtualenvs

3. **Build Issues**: Use UV for package building
    ```bash
    devenv shell
    uv build
    ```

### Debug Output

Debug information is sent to stderr, while program output goes to stdout:

```bash
# See debug output (stderr)
just run-json

# See only clean JSON (stdout)
just run-json 2>/dev/null

# Capture both separately
just run-json 1>output.json 2>debug.log
```

## Customizing This Template

This boilerplate is designed to be easily customized for your specific needs:

### Changing the Project Name

1. Update `name` in `pyproject.toml`
2. Update `scripts` in `pyproject.toml`
3. Update `SESSION_NAME` in `devenv.nix`
4. Update directory names if desired

### Adding New Features

1. Add new Click options in `boilerplate_app/cli.py`
2. Add corresponding logic in your functions
3. Update justfile recipes if needed
4. Update documentation

### Integrating External Services

1. Add required dependencies to `pyproject.toml`
2. Add external packages to `devenv.nix` if needed
3. Implement service integration in your CLI functions
4. Add error handling for service failures

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes and test thoroughly
4. Commit your changes: `git commit -am 'Add some feature'`
5. Push to the branch: `git push origin feature/my-feature`
6. Submit a pull request

## Deployment

The project uses Nix/devenv for reproducible deployments. The entire development environment, including dependencies, is managed declaratively.

### Production Considerations

- The application is self-contained with no external service dependencies
- JSON output is stable and machine-parseable
- Error handling is robust with proper exception management
- No external configuration files required
- Package can be built with `uv build` for distribution

## Troubleshooting

### devenv Issues

If devenv fails to build:

```bash
# Clean the devenv cache
rm -rf .devenv
devenv shell
```

### Python Environment Issues

```bash
# Rebuild the environment
devenv shell --force
```

**Never try to manually fix Python path issues:**
- The devenv + uv combination handles everything automatically
- Manual PYTHONPATH setting is complex and error-prone
- Use `uv run` for all Python execution

## Performance Considerations

- The application makes subprocess calls synchronously
- Terminal output is optimized for readability with Rich formatting
- Memory usage is minimal for typical operations

## Next Steps

### Potential Enhancements

1. **Testing Framework**
    - Add pytest unit tests
    - Integration tests for CLI commands
    - CLI argument testing

2. **Configuration Management**
    - Support for configuration files
    - Environment variable configuration
    - Custom settings management

3. **Enhanced CLI Features**
    - Subcommands for different operations
    - Output format customization
    - Progress indicators for long operations

4. **Documentation**
    - API documentation
    - More usage examples
    - Tutorial for customization

5. **Packaging Distribution**
    - Publish to PyPI
    - Docker containerization
    - GitHub Actions CI/CD pipeline
