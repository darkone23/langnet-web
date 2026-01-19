# Frontend

Vite-powered frontend with TypeScript, Tailwind CSS, DaisyUI, HTMX, and Alpine.js.

## Structure

```
frontend/
├── src/
│   ├── main.ts            # Application entry point
│   └── tailwind.css       # Tailwind + DaisyUI imports
├── public/
│   └── vite.svg           # Static assets
├── index.html             # HTML entry point
├── vite.config.ts         # Vite configuration
├── tsconfig.json          # TypeScript configuration
├── postcss.config.js      # PostCSS configuration
├── package.json           # Dependencies
├── bun.lock               # Bun lockfile
└── justfile               # Frontend-specific commands
```

## Commands

```bash
# From frontend/ directory
just install   # Install dependencies (bun install)
just dev       # Start Vite dev server (port 43210)
just build     # Build for production
just preview   # Preview production build
just clean     # Remove dist/ directory
```

## Development

The Vite dev server runs on port 43210 and proxies `/api/*` requests to Starlette on port 43280.

```bash
# Start frontend dev server
just dev

# Or use bun directly
bun run dev
```

## Tech Stack

 | Technology | Purpose |
 |------------|---------|
 | Vite | Build tool and dev server |
 | TypeScript | Type-safe JavaScript |
 | Tailwind CSS v4 | Utility-first CSS |
 | DaisyUI v5 | Component library for Tailwind |
 | HTMX | Server-driven interactivity |
  | Alpine.js | Reactive framework |

## Styling

Tailwind CSS and DaisyUI are configured in `src/tailwind.css`:

```css
@import "tailwindcss";
@plugin "daisyui";
```

Use DaisyUI components in your HTML:

```html
<button class="btn btn-primary">Click me</button>
<div class="alert alert-success">Success message</div>
<div class="card bg-base-100 shadow-xl">Card content</div>
```

## HTMX Usage

HTMX is imported in `main.ts`. Use `hx-*` attributes for server interactions:

```html
<button hx-get="/api/hello-htmx" hx-target="#result">
  Load Content
</button>
<div id="result"></div>
```

## Building for Production

```bash
just build
```

Output is placed in `dist/` which Starlette serves in production mode.

## Dependencies

**Runtime:**
- `htmx.org`: Server-driven UI
- `alpinejs`: Reactive framework

**Development:**
- `vite`: Build tool
- `typescript`: Type checking
- `tailwindcss`: CSS framework
- `@tailwindcss/postcss`: PostCSS integration
- `daisyui`: Component library
- `autoprefixer`: CSS vendor prefixes
- `postcss`: CSS processing
