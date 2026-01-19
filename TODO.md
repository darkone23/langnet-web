# TODO - Project Improvements

This document lists recommended improvements for the boilerplate web project.

### Testing
- [ ] Add python test setup
- [ ] Add vitest for frontend unit tests

### CI/CD
- [ ] Add devenv pre-commit hooks configuration
  - Linting (ruff for Python, eslint for TypeScript)
  - Type checking (mypy for Python, tsc for TypeScript)
  - Running tests
  - Building the frontend

### Type Safety
- [ ] Add ty configuration for Python type checking
- [ ] Add strict type annotations to all backend modules
- [ ] Add eslint configuration for TypeScript

### Code Quality
- [ ] Add ruff for Python linting and formatting
- [ ] Add prettier for frontend code formatting
- [ ] Create `.editorconfig` for consistent formatting across editors

### Documentation
- [ ] Add docstrings to Python functions
- [ ] Create CONTRIBUTING.md with contribution guidelines

### Database
- [ ] Add connection pooling configuration
- [ ] Document DuckDB usage

## Low Priority

### Performance
- [ ] Add bundle analysis for frontend
- [ ] Use python313FreeThreading
  - [ ] make sure LSP still work

### Monitoring
- [ ] Add structured logging (structlog or similar)
- [ ] Add health check endpoint
