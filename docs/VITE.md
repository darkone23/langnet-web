# Vite Guide

This guide covers Vite configuration and usage in the langnet-web project.

## Overview

Vite is used as the frontend build tool and development server. It provides fast hot module replacement (HMR), optimized production builds, and a great developer experience.

## Project Configuration

### File Structure

```
frontend/
├── src/
│   ├── main.ts            # Application entry point
│   └── tailwind.css       # Tailwind + DaisyUI imports
├── public/                # Static assets
├── dist/                  # Build output (served by Zig in production)
├── index.html             # HTML entry point
├── vite.config.ts         # Vite configuration
├── package.json           # Frontend dependencies
├── bun.lock               # Bun lockfile
└── justfile               # Frontend commands
```

### Vite Configuration (`vite.config.ts`)

```typescript
import { defineConfig } from 'vite'
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  server: {
    port: 5173,
    allowedHosts: [
      "truenas-qemu-nixos.snake-dojo.ts.net"  // Dev-specific, remove for production
    ],
    proxy: {
      '/api': {
        target: 'http://localhost:43210',  // Proxies to Zig backend
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
  },
  plugins: [
    tailwindcss()  // Tailwind CSS v4 integration
  ]
})
```

**Key Configuration Points:**
- `server.port: 5173` - Development server port
- `proxy` - Forwards `/api/*` to Zig backend during development
- `outDir: 'dist'` - Production build output directory
- `plugins` - Integrates Tailwind CSS v4

## Development

### Starting Development Server

```bash
cd frontend
bun run dev
# Or
just dev
```

This starts:
- Vite dev server at http://localhost:5173
- Hot module replacement enabled
- Proxy to Zig backend at http://localhost:43210

### Hot Module Replacement (HMR)

Vite's HMR updates the browser without a full page reload:

1. Edit `frontend/src/*.ts` files
2. Changes are detected automatically
3. Browser updates with new code
4. Reactivity is preserved (Alpine.js state, HTMX)

### Proxy Configuration

In development, Vite proxies `/api/*` requests to Zig backend:

```
Browser Request (http://localhost:5173/api/hello)
    ↓
Vite Proxy
    ↓
Zig Backend (http://localhost:43210/api/hello)
```

**Benefits:**
- No CORS issues during development
- Single origin development
- Simplifies API calls

## Building for Production

### Build Command

```bash
cd frontend
bun run build
# Or
just build
```

### Build Output

Files are output to `frontend/dist/`:

```
dist/
├── index.html           # Processed HTML entry point
├── vite.svg             # (If exists) Icon
└── assets/
    ├── index-[hash].js  # Bundled JavaScript
    ├── index-[hash].css  # Optimized CSS
    └── *               # Other assets
```

### Production Serving

Zig backend serves `frontend/dist/` in production mode:

- Serves `dist/index.html` as the entry point
- Serves `dist/assets/*` as static files
- No Vite server running in production

## TypeScript Configuration

### File: `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "types": ["vite/client"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "noEmit": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "erasableSyntaxOnly": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedSideEffectImports": true
  },
  "include": ["src"]
}
```

**Key Settings:**
- `strict: true` - Enables all strict type checking
- `moduleResolution: "bundler"` - Optimized for Vite
- `types: ["vite/client"]` - Includes Vite types
- `noEmit: true` - Vite handles compilation

## Dependencies

### Runtime Dependencies (`package.json`)

```json
{
  "dependencies": {
    "alpinejs": "^3.15.8",
    "htmx.org": "^2.0.8"
  }
}
```

- **alpine.js**: Reactive framework for client-side behavior
- **htmx.org**: Server-driven UI updates

### Development Dependencies

```json
{
  "devDependencies": {
    "@tailwindcss/vite": "^4.1.18",
    "@types/alpinejs": "^3.13.11",
    "daisyui": "^5.5.18",
    "tailwindcss": "^4.1.18",
    "typescript": "~5.9.3",
    "vite": "^7.3.1"
  }
}
```

- **@tailwindcss/vite**: Tailwind CSS v4 Vite plugin
- **@types/alpinejs**: Alpine.js type definitions
- **daisyui**: Component library
- **tailwindcss**: Utility-first CSS framework
- **typescript**: TypeScript compiler
- **vite**: Build tool

## Troubleshooting

### Vite Won't Start

```bash
cd frontend
bun install    # Reinstall dependencies
bun run dev    # Try again
```

### HMR Not Working

1. Check browser console for errors
2. Ensure `main.ts` is imported in `index.html`
3. Check Vite server is running
4. Try refreshing the page (Cmd+R or Ctrl+R)

### Proxy Issues

- Ensure Zig backend is running on port 43210
- Check Vite proxy configuration in `vite.config.ts`
- Look for CORS errors in browser console

### Build Errors

```bash
# Check TypeScript errors
cd frontend
bun run build    # TypeScript will report errors
```

## Best Practices

### 1. Keep Configuration Simple

Avoid unnecessary plugins or complex configurations:
```typescript
// Good
export default defineConfig({
  server: { port: 5173 },
  proxy: { '/api': { target: 'http://localhost:43210' } },
  build: { outDir: 'dist' },
  plugins: [tailwindcss()]
})
```

### 2. Use Relative Paths

Use relative paths for better portability:
```typescript
// Good
import './tailwind.css'
import htmx from 'htmx.org'

// Avoid absolute paths in most cases
```

### 3. Leverage HMR

Don't manually refresh the browser - let HMR do its job:
1. Edit code
2. Save file
3. Browser updates automatically

### 4. Use Type-Safe Patterns

Take advantage of TypeScript's strict mode:
```typescript
// Good
const message: string = "Hello";
const count: number = 0;

function increment(): void {
  count += 1;  // TypeScript catches logic errors
}
```

### 5. Optimize for Production

Vite already optimizes by default, but you can add:
- Code splitting for large bundles
- Asset compression (via build tools)
- Bundle analysis

## Advanced Configuration

### Custom Build Options

```typescript
export default defineConfig({
  build: {
    outDir: 'dist',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['htmx.org', 'alpinejs'],
        },
      },
    },
    assetsInlineLimit: 4096,
  },
})
```

### Environment-Specific Configuration

```typescript
import { defineConfig, loadEnv } from 'vite'

export default defineConfig({
  define: {
    __API_URL__: JSON.stringify(loadEnv().API_URL ?? 'http://localhost:43210'),
  },
})
```

## Performance Tips

### 1. Lazy Loading

For large applications, use dynamic imports:
```typescript
const loadModule = () => import('./heavy-module.ts');
```

### 2. Asset Optimization

- Use `vite-plugin-static` for pre-compressed assets
- Consider CDN for production

### 3. Reduce Bundle Size

- Use tree-shaking (automatic with Vite)
- Analyze bundle with `rollup-plugin-visualizer`
- Remove unused dependencies

## References

- [Vite Documentation](https://vitejs.dev/)
- [Vite Configuration Reference](https://vitejs.dev/config/)
- [Tailwind CSS v4](https://tailwindcss.com/docs/installation)
