# TODO - Project Improvements

This document lists recommended improvements for the boilerplate web project.

### Testing
- [ ] Add Zig test setup (zig test)
- [ ] Add vitest for frontend unit tests
- [ ] Add integration tests for API endpoints
- [ ] Add test coverage reporting

### CI/CD
- [ ] Add devenv pre-commit hooks configuration
  - Linting (zig fmt for Zig, eslint for TypeScript)
  - Type checking (tsc for TypeScript)
  - Running tests (zig test, vitest)
  - Building the frontend
- [ ] Add GitHub Actions workflow for CI/CD
  - Run tests on push
  - Run linters on push
  - Build artifacts

### Code Quality
- [ ] Add zig fmt configuration for Zig formatting
- [ ] Add eslint configuration for TypeScript
- [ ] Add prettier for frontend code formatting
- [ ] Create `.editorconfig` for consistent formatting across editors
- [ ] Add VS Code settings for formatting

### Documentation
- [ ] Add docstrings to Zig functions
- [ ] Create CONTRIBUTING.md with contribution guidelines
- [ ] Add deployment guide
- [ ] Add security documentation

### Backend Improvements
- [ ] Add proper JSON serialization library
  - Replace manual JSON string concatenation
  - Create JSON helper functions
- [ ] Add template invalidation for development
  - Clear template cache on file changes
  - Add file watcher
- [ ] Add error response helpers
  - Standardized error responses
  - Better error messages
- [ ] Add request validation
  - Input validation helpers
  - Type-safe request parsing
- [ ] Add logging
  - Structured logging
  - Request ID tracking

### Frontend Improvements
- [ ] Add advanced HTMX examples
  - hx-swap options
  - hx-indicator patterns
  - hx-trigger events
- [ ] Add Alpine.js component examples
  - Reactive components
  - State management patterns
- [ ] Add build optimization
  - Code splitting
  - Bundle analysis
  - Asset compression

### Database
- [ ] Document DuckDB usage patterns
  - Query examples
  - Schema design patterns
  - Performance considerations
- [ ] Add connection pooling (if needed for production)
- [ ] Add migrations management (if needed)

## Low Priority

### Performance
- [ ] Add bundle analysis for frontend
- [ ] Add performance monitoring
  - Response time tracking
  - Error rate tracking
  - Resource usage metrics
- [ ] Add caching headers
  - Static asset caching
  - API response caching
  - ETag support

### Monitoring
- [ ] Add structured logging (zig logging)
- [ ] Add health check endpoint with diagnostics
- [ ] Add metrics collection endpoint

### Security
- [ ] Add input validation to all routes
- [ ] Add rate limiting (if needed)
- [ ] Add security headers
  - Content-Security-Policy
  - X-Frame-Options
  - X-Content-Type-Options
- [ ] Add HTTPS/TLS configuration guide (Caddy)
- [ ] Document security posture and best practices

### Developer Experience
- [ ] Add hot reload for backend templates
  - Watch template files
  - Clear cache on changes
- [ ] Add debug mode configuration
  - Detailed error messages
  - Debug logging
  - Request tracing
- [ ] Add shell completion for just commands
  - Bash completion
  - Zsh completion
