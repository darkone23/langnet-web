# Zig SSR Tool Runner

A small, boring, server-side rendered web app written in **Zig 0.15.x** (post-writergate).

This project exists to:

* render HTML pages (SSR)
* serve static frontend assets (JS/CSS built elsewhere)
* run local Linux tools on demand
* cache their JSON output locally
* render cached results into HTML
* run behind a reverse proxy (Caddy)

No users.
No auth.
No SPA framework.
No "web magic".

Just a Zig program that happens to speak HTTP.

---

## Philosophy

This project follows a few simple rules:

* **Explicit over clever**
* **Typed data at the edges**
* **Boring infrastructure**
* **Minimal dependencies**
* **Easy to debug locally**

Upstream tools may output messy or evolving JSON — that mess is contained in one place.
Templates only ever see small, concrete structs.

---

## High-Level Architecture

```
Browser
   │
   ▼
Caddy (TLS / proxy / rate limiting)
   │
   ▼
Zig server (zzz)
   │
   ├─ dynamic HTML routes (mustache)
   ├─ static assets (/assets/*)
   ├─ subprocess runner
   └─ DuckDB cache
```

* **Caddy**: TLS, proxying, coarse rate limiting
* **Zig server**: all application logic
* **DuckDB**: embedded read/write cache
* **mustache**: server-side HTML templates + partials

Static assets are served by Zig (even in prod) to keep local development friction low.

---

## Core Components

### HTTP Server

* Routing and lifecycle handled by zzz
* Simple GET + POST endpoints
* PRG (Post → Redirect → Get) pattern for form submissions

### Static Assets

* Served from a local directory (e.g. `public/`)
* Frontend build outputs JS/CSS here
* No rebuild required for asset changes

### Subprocess Runner

* Executes local Linux tools
* Captures stdout (expected to be JSON)
* Enforces:

  * timeouts
  * exit-code checks
  * output size limits

This layer knows **nothing** about HTTP or templates.

### Cache (DuckDB)

* Embedded, in-process database
* Stores:

  * cache key
  * timestamps / TTL
  * raw JSON output (`TEXT`)
* Optional materialized columns for filtering or sorting

DuckDB is used as a **local structured cache**, not a primary datastore.

### JSON Handling

* Upstream JSON is stored raw
* Parsed in Zig only when needed
* Two modes:

  * `std.json.Value` for flexible / evolving schemas
  * typed structs once stable

### Mapper Layer (Important)

All messy JSON handling lives here.

```
raw JSON → small, concrete view models
```

Responsibilities:

* tolerate missing / extra fields
* apply defaults
* normalize weird shapes
* shield templates from schema churn

### Templates (mustache)

* Layouts + partials
* Mostly plain HTML
* Minimal logic
* Receive only tiny, concrete structs

Templates never:

* parse JSON
* query DuckDB
* run subprocesses

---

## Request Flows

### GET (Render Page)

```
request
 → read cache (DuckDB)
 → parse JSON
 → map to view models
 → render templates
 → response
```

### POST (Run Tool)

```
request
 → validate input
 → optional Origin/Referer check
 → run subprocess
 → store JSON in cache
 → redirect to GET
```

---

## Security Posture (Right-Sized)

This app intentionally keeps security **proportional to risk**.

Included:

* Caddy IP-based rate limiting
* `SameSite=Lax` cookies (if any)
* Origin / Referer checks on POST

Deferred (by design):

* CSRF tokens
* sessions
* auth
* JWTs

CSRF can be added later if/when:

* users exist
* actions become destructive
* per-user state matters

---

## Configuration

Configuration follows **12-factor app principles**:

* values come from environment variables
* defaults live in code
* no magic globals

Example env vars:

```
APP_ENV=dev
PORT=3000
DB_PATH=data/app.db
STATIC_DIR=public
```

`.env` files are supported as a **development convenience**, typically loaded by the shell or task runner — not by production code.

Configuration is centralized in a single `Config` struct and passed explicitly.

---

## Project Layout

```
public/
  app.js
  styles.css

src/
  main.zig
  server.zig        // HTTP + routes
  subprocess.zig    // tool execution
  cache.zig         // DuckDB access
  models.zig        // view models
  mapper.zig        // JSON → models

templates/
  layout.mustache.html
  pages/
  partials/
```

Each file has one responsibility.

---

## Development

* Single origin (`localhost`)
* No CORS issues
* Static assets reload instantly
* Templates are server-rendered
* Debugging is straightforward (view source shows real HTML)

Caddy can be run locally for HTTPS parity, but the Zig server works standalone as well.

---

## Non-Goals

This project intentionally does **not** aim to be:

* a SPA framework
* a general-purpose web framework
* a multi-tenant app
* an auth provider
* a microservices platform

If it ever needs to become those things, the architecture leaves room — but it doesn’t assume them.

---

## Summary

This is a deliberately simple Zig web app:

* **Zig does the logic**
* **DuckDB caches results**
* **Templates render HTML**
* **Caddy handles the edge**
* **Everything else is explicit**

If someone asks *“what framework is this?”*, the honest answer is:

> “It’s just a Zig program that serves HTML.”

That’s the point.

