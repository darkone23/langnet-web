# Documentation Index

This document provides an organized index of all documentation for the langnet-web project.

## Quick Links

### Getting Started
- **[Main README](../README.md)** - Project overview, quick start guide, architecture
- **[Developer Guide](../DEV.md)** - Comprehensive development instructions
- **[Project Review](../REVIEW.md)** - Architecture assessment and recommendations

### Technology Guides

| Technology | Guide | Description |
|------------|-------|-------------|
| **Vite** | [VITE.md](./VITE.md) | Frontend build tool configuration |
| **HTMX + Alpine.js** | [HTMX_ALPINE.md](./HTMX_ALPINE.md) | Server-driven UI and client-side reactivity |
| **DaisyUI + Tailwind** | [DAISYUI_TAILWIND.md](./DAISYUI_TAILWIND.md) | Styling with utility-first CSS |
| **Zig Backend** | [ZIG_BACKEND.md](./ZIG_BACKEND.md) | Backend development patterns and best practices |
| **Zig 0.15.x Migration** | [ZIG_0.15_NOTES.md](./ZIG_0.15_NOTES.md) | Post-writergate migration guide |

### Reference Documentation

| Document | Purpose | Description |
|----------|---------|-------------|
| **AGENTS.md** | [../AGENTS.md](../AGENTS.md) | AI assistant configuration |
| **TODO.md** | [../TODO.md](../TODO.md) | Improvement roadmap |

### Component Documentation

| Component | Guide | Description |
|-----------|-------|-------------|
| **Backend Philosophy** | [../backend/README.md](../backend/README.md) | Zig backend architecture and philosophy |

## Learning Paths

### For New Contributors

**Recommended Order:**

1. **Start Here**: [Main README](../README.md) - Get project overview
2. **Setup Environment**: [Developer Guide](../DEV.md) - Install and configure
3. **Learn Frontend**: 
   - [VITE.md](./VITE.md) - Build tool configuration
   - [HTMX_ALPINE.md](./HTMX_ALPINE.md) - UI interactions
   - [DAISYUI_TAILWIND.md](./DAISYUI_TAILWIND.md) - Styling
4. **Learn Backend**:
   - [ZIG_BACKEND.md](./ZIG_BACKEND.md) - Backend development
   - [ZIG_0.15_NOTES.md](./ZIG_0.15_NOTES.md) - Zig 0.15.x specific patterns
5. **Deployment**: [DEPLOYMENT.md](./DEPLOYMENT.md) - Deploy to production

### For Experienced Developers

**Recommended Order:**

1. **Review Architecture**: [Project Review](../REVIEW.md) - Understand patterns and trade-offs
2. **Deep Dive**: Specialized guides for your area of focus
3. **Reference**: Official documentation for each technology
4. **Best Practices**: Security, deployment, and operational guides

## Technology-Specific Guides

### Frontend Stack

| Technology | Guide | Key Topics |
|------------|-------|-------------|
| **Vite** | [VITE.md](./VITE.md) | Configuration, HMR, building, proxying |
| **TypeScript** | [Developer Guide](../DEV.md) | Types, strict mode, configuration |
| **Tailwind CSS v4** | [DAISYUI_TAILWIND.md](./DAISYUI_TAILWIND.md) | Utility classes, v4 features, scanning |
| **DaisyUI v5** | [DAISYUI_TAILWIND.md](./DAISYUI_TAILWIND.md) | Components, theming, usage patterns |
| **HTMX** | [HTMX_ALPINE.md](./HTMX_ALPINE.md) | Attributes, patterns, troubleshooting |
| **Alpine.js** | [HTMX_ALPINE.md](./HTMX_ALPINE.md) | Reactivity, data binding, components |

### Backend Stack

| Technology | Guide | Key Topics |
|------------|-------|-------------|
| **Zig** | [ZIG_BACKEND.md](./ZIG_BACKEND.md) | Language patterns, error handling, I/O |
| **Zig 0.15.x** | [ZIG_0.15_NOTES.md](./ZIG_0.15_NOTES.md) | Writergate migration, I/O interfaces |
| **zzz HTTP** | [ZIG_BACKEND.md](./ZIG_BACKEND.md) | HTTP framework, routing, async |
| **Mustache** | [ZIG_BACKEND.md](./ZIG_BACKEND.md) | Templates, caching, rendering |
| **DuckDB** | [ZIG_BACKEND.md](./ZIG_BACKEND.md) | Queries, connections, optimization |

### Development Tools

| Tool | Documentation | Key Topics |
|------|---------------|-------------|
| **Nix** | [Developer Guide](../DEV.md) | Reproducible environments, devenv |
| **devenv** | [Developer Guide](../DEV.md) | Environment management, shell configuration |
| **Just** | [Project Review](../REVIEW.md) | Task runner, justfiles |
| **Zellij** | [Developer Guide](../DEV.md) | Terminal multiplexer, sessions |
| **Bun** | [Developer Guide](../DEV.md) | Package manager, runtime |

## Common Tasks

### Setup and Installation
1. [ ] Install Nix and devenv
2. [ ] Clone repository
3. [ ] Enter devenv shell
4. [ ] Install frontend dependencies
5. [ ] Configure environment variables
6. [ ] Verify Zig version (0.15.x)

### Development Workflow
1. [ ] Start development servers (Vite + Zig)
2. [ ] Make code changes with hot reload
3. [ ] Run tests
4. [ ] Format code (zig fmt, eslint)
5. [ ] Check API endpoints

### Building
1. [ ] Build frontend for production
2. [ ] Build backend for production
3. [ ] Optimize assets
4. [ ] Test production builds locally

### Deployment
1. [ ] Choose deployment strategy (manual, Docker, systemd)
2. [ ] Configure environment variables
3. [ ] Build and deploy artifacts
4. [ ] Configure reverse proxy (Caddy)
5. [ ] Set up HTTPS/TLS
6. [ ] Configure security headers
7. [ ] Test production deployment

### Maintenance
1. [ ] Monitor application health
2. [ ] Review logs
3. [ ] Update dependencies
4. [ ] Backup database
5. [ ] Rotate logs
6. [ ] Security audits

## Troubleshooting

### Common Issues

| Issue | Documentation | Quick Fix |
|-------|---------------|------------|
| **Vite not starting** | [VITE.md](./VITE.md) | Check dependencies, reinstall |
| **Styles not applying** | [DAISYUI_TAILWIND.md](./DAISYUI_TAILWIND.md) | Check Tailwind configuration |
| **HTMX not working** | [HTMX_ALPINE.md](./HTMX_ALPINE.md) | Check imports, verify endpoints |
| **Alpine.js not working** | [HTMX_ALPINE.md](./HTMX_ALPINE.md) | Check initialization, verify DOM ready |
| **Zig build errors** | [ZIG_0.15_NOTES.md](./ZIG_0.15_NOTES.md) | Check writergate patterns |
| **Zig server won't start** | [ZIG_BACKEND.md](./ZIG_BACKEND.md) | Check ports, permissions |
| **Deployment issues** | [DEPLOYMENT.md](./DEPLOYMENT.md) | Check configuration, logs, permissions |

## Project Improvement Tasks

See [TODO.md](../TODO.md) for the current improvement roadmap.

### Current Priorities

1. **High Priority**
   - Testing infrastructure (Zig tests, vitest)
   - JSON serialization improvements
   - Error handling enhancements

2. **Medium Priority**
   - Code examples and documentation
   - Deployment documentation
   - Security enhancements

3. **Low Priority**
   - CI/CD setup
   - Performance monitoring
   - Development tooling

## Contributing

When contributing to langnet-web:

1. Read this documentation thoroughly
2. Follow project conventions (see [Developer Guide](../DEV.md))
3. Write tests for new features
4. Update documentation for changes

## Glossary

| Term | Definition |
|-------|------------|
| **HMR** | Hot Module Replacement - automatic code updates in development |
| **SSR** | Server-Side Rendering - HTML generated on server |
| **HTMX** | Library for server-driven UI updates via HTML |
| **Alpine.js** | Lightweight reactive framework for client-side state |
| **Tailwind** | Utility-first CSS framework |
| **DaisyUI** | Component library built on Tailwind CSS |
| **Mustache** | Logicless template engine for server-side rendering |
| **DuckDB** | Embedded analytical database |
| **zzz** | HTTP framework for Zig |
| **Tardy** | Async runtime used by zzz |
| **Writergate** | Major Zig 0.15.x I/O interface changes |
| **Nix** | Package manager and reproducible build system |
| **devenv** | Development environment management for Nix |
| **Just** | Command runner for task automation |

## File Organization

```
langnet-web/
├── docs/                     # Organized documentation
│   ├── INDEX.md             # This file - documentation index
│   ├── VITE.md             # Vite configuration guide
│   ├── HTMX_ALPINE.md      # HTMX + Alpine.js guide
│   ├── DAISYUI_TAILWIND.md  # Tailwind + DaisyUI guide
│   ├── ZIG_BACKEND.md       # Zig backend development guide
│   ├── ZIG_0.15_NOTES.md   # Zig 0.15.x migration guide
│   ├── DEPLOYMENT.md        # Deployment strategies
├── frontend/                   # Frontend application
│   ├── src/                # Source files
│   ├── public/             # Static assets
│   ├── dist/               # Build output
│   ├── index.html           # HTML entry
│   ├── vite.config.ts       # Vite config
│   ├── package.json         # Dependencies
│   └── justfile           # Commands
├── backend/                    # Backend application
│   ├── src/                # Zig source files
│   ├── templates/           # Mustache templates
│   ├── public/              # Static assets
│   ├── build.zig            # Build configuration
│   ├── justfile             # Backend commands
│   └── README.md           # Backend philosophy
├── devenv.nix                  # Nix environment
├── devenv.yaml                 # Devenv inputs
├── justfile                    # Root commands
├── README.md                   # Project overview
├── DEV.md                      # Developer guide
├── AGENTS.md                   # AI configuration
├── TODO.md                     # Improvement roadmap
└── REVIEW.md                    # Project review
```

## Quick Reference

### Commands

```bash
# Development
devenv shell just -- dev-frontend
devenv shell just -- dev-backend

# Building
devenv shell just -- build

# Deployment
devenv shell bash -- -c "cd backend && zig build -Drelease-fast"
```

### Configuration

```bash
# Development ports
VITE_PORT=5173          # Frontend dev server
ZIG_PORT=43210           # Backend dev/production server

# Production ports
ZIG_PORT=43210           # Backend server (production)
```

### Troubleshooting Quick Links

| Problem | Documentation |
|---------|---------------|
| Can't start | [Setup](../DEV.md#development-environment-setup) |
| Build errors | [VITE.md](./VITE.md#troubleshooting) |
| Runtime errors | [ZIG_0.15_NOTES.md](./ZIG_0.15_NOTES.md#troubleshooting) |

## Staying Up to Date

### Recent Updates (2026-02-12)

- ✅ Fixed documentation inconsistencies (Python → Zig)
- ✅ Updated port configuration (5173/43210)
- ✅ Added Zig 0.15.x migration guide
- ✅ Organized documentation in `docs/` directory
- ✅ Added comprehensive technology guides
- ✅ Added deployment and security documentation

### What's Next

- [ ] Add testing infrastructure
- [ ] Improve JSON serialization
- [ ] Add more code examples
- [ ] Set up CI/CD
- [ ] Add performance monitoring

---

**Last Updated:** 2026-02-12  
**Maintained By:** langnet-web Team  
**Documentation Version:** 2.0
