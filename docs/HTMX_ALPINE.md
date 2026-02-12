# HTMX + Alpine.js Guide

This guide covers using HTMX for server-driven UI and Alpine.js for client-side reactivity in the langnet-web project.

## Overview

- **HTMX**: Library that allows you to access AJAX, CSS transitions, WebSockets, and Server-Sent Events directly in HTML
- **Alpine.js**: Rugged, minimal JavaScript framework for adding reactivity to your UI

**Philosophy:** Use HTMX for server-driven updates and Alpine.js for local client-side state management.

## Project Setup

### Initialisation (`frontend/src/main.ts`)

```typescript
import './tailwind.css'
import htmx from 'htmx.org'
import Alpine from 'alpinejs';

// Setup Alpine
declare global {
  interface Window {
      htmx: typeof htmx;
      Alpine: typeof Alpine;
  }
}

window.htmx = htmx
window.Alpine = Alpine;

Alpine.start();

document.addEventListener('DOMContentLoaded', () => {
    const app = document.querySelector<HTMLDivElement>('#app')
    if (app) {
      app.setAttribute('hx-get', '/api/main-content')
      app.setAttribute('hx-trigger', 'load')
      htmx.process(app)  // Explicitly tell HTMX to look at this node
    }
})
```

**Key Points:**
- HTMX is available globally as `window.htmx`
- Alpine.js is available globally as `window.Alpine`
- `htmx.process(node)` - Initializes HTMX on a specific DOM element

## HTMX Basics

### Core Attributes

HTMX uses attributes on HTML elements:

```html
<!-- Make a GET request -->
<button hx-get="/api/hello-htmx">
  Load Content
</button>

<!-- Make a POST request -->
<form hx-post="/api/submit">
  <input name="name" type="text">
  <button type="submit">Submit</button>
</form>

<!-- Target an element -->
<button hx-get="/api/data" hx-target="#result">
  Load Data
</button>
<div id="result"></div>

<!-- Trigger on load -->
<div hx-get="/api/initial" hx-trigger="load">
  <!-- Content loaded on page load -->
</div>
```

### Common HTMX Attributes

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `hx-get` | Make GET request | `hx-get="/api/hello"` |
| `hx-post` | Make POST request | `hx-post="/api/submit"` |
| `hx-target` | Target element to update | `hx-target="#result"` |
| `hx-swap` | How to swap content | `hx-swap="innerHTML"` |
| `hx-trigger` | When to trigger request | `hx-trigger="click"` |
| `hx-indicator` | Show loading indicator | `hx-indicator="#loading"` |
| `hx-vals` | Include values | `hx-vals="#input"` |

## Alpine.js Basics

### Data Binding

```html
<div x-data="{ count: 0 }">
  <button x-on:click="count++">
    Increment
  </button>
  <span>Count: <span x-text="count"></span></span>
</div>
```

### Conditional Rendering

```html
<div x-data="{ show: true }">
  <button x-on:click="show = !show">
    Toggle
  </button>
  <p x-show="show">
    This text is conditionally shown
  </p>
</div>
```

### List Rendering

```html
<div x-data="{ items: ['Apple', 'Banana', 'Cherry'] }">
  <ul>
    <template x-for="item in items">
      <li x-text="item"></li>
    </template>
  </ul>
</div>
```

## Combining HTMX + Alpine.js

### Pattern: Server-Driven Content with Local State

Use HTMX for fetching content and Alpine.js for managing local interactions:

```html
<!-- Alpine manages loading state -->
<div x-data="{ loading: false }">
  <!-- HTMX updates content -->
  <button 
    hx-get="/api/content" 
    hx-target="#content-area"
    hx-indicator="#loading"
    @htmx:before-request="loading = true"
    @htmx:after-request="loading = false"
  >
    Load Content
  </button>

  <!-- Show loading indicator -->
  <div 
    id="loading" 
    x-show="loading" 
    class="alert alert-info"
    style="display: none;"
  >
    Loading...
  </div>

  <!-- Content area -->
  <div id="content-area"></div>
</div>
```

### Pattern: Form Validation

```html
<form x-data="{ 
  email: '', 
  valid: false,
  submit() {
    this.valid = this.email.includes('@');
  }
}">
  <input 
    type="email" 
    x-model="email"
    placeholder="Enter email"
  >
  
  <button 
    hx-post="/api/subscribe" 
    :class="{ 'btn btn-primary': valid, 'btn btn-disabled': !valid }"
    x-on:click.prevent="submit()"
    :disabled="!valid"
  >
    Subscribe
  </button>
</form>
```

### Pattern: Dynamic Content Updates

```html
<div x-data="{ items: [] }">
  <button 
    hx-get="/api/items" 
    hx-target="#item-list"
    @htmx:after-swap="items = $el.querySelectorAll('li').toArray()"
  >
    Refresh Items
  </button>
  
  <ul id="item-list">
    <!-- HTMX will populate this -->
  </ul>
</div>
```

## HTMX Advanced

### Content Swapping

Control how HTMX replaces content:

```html
<!-- Replace entire element -->
<div hx-get="/api/content" hx-swap="outerHTML">
  Content
</div>

<!-- Replace inner content -->
<div hx-get="/api/content" hx-swap="innerHTML">
  Content
</div>

<!-- Prepend content -->
<div hx-get="/api/content" hx-swap="beforebegin">
  Content
</div>

<!-- Append content -->
<div hx-get="/api/content" hx-swap="beforeend">
  Content
</div>
```

### Loading Indicators

```html
<div x-data="{ loading: false }">
  <button 
    hx-get="/api/data" 
    hx-indicator="#spinner"
    @htmx:before-request="loading = true"
    @htmx:after-request="loading = false"
  >
    Load Data
  </button>

  <span id="spinner" x-show="loading">
    ⏳ Loading...
  </span>
</div>
```

### Request Triggers

```html
<!-- Trigger on click (default) -->
<button hx-get="/api/data">
  Load Data
</button>

<!-- Trigger on load -->
<div hx-get="/api/initial" hx-trigger="load">
  Initial Content
</div>

<!-- Trigger on event -->
<button hx-get="/api/data" hx-trigger="reveal">
  Reveal Data
</button>

<!-- Poll every 2 seconds -->
<div hx-get="/api/status" hx-trigger="load, every 2s">
  Status
</div>
```

## Alpine.js Advanced

### Computed Properties

```html
<div x-data="{ 
  firstName: 'John',
  lastName: 'Doe',
  get fullName() {
    return `${this.firstName} ${this.lastName}`;
  }
}">
  <p>Hello, <span x-text="fullName"></span>!</p>
</div>
```

### Watchers

```html
<div x-data="{ search: '' }">
  <input 
    type="text" 
    x-model="search" 
    @input="$watch('search', value => console.log('Searching:', value))"
  >
  <p>Searching for: <span x-text="search"></span></p>
</div>
```

### Event Modifiers

```html
<!-- Prevent default -->
<form @submit.prevent="handleSubmit()">
  <button type="submit">Submit</button>
</form>

<!-- Only once -->
<button @click.once="doSomething()">
  Do Once
</button>

<!-- Debounce (500ms) -->
<input @input.debounce.500="handleInput()">
```

## Backend Implementation

### HTMX Endpoints in Zig

**File:** `backend/src/routes.zig`

```zig
fn apiHtmxEndpoint(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();
    const template_path = try std.fs.path.join(ctx.allocator, &.{ 
        globals.cfg.templates_path, 
        "example_htmx.html" 
    });
    defer ctx.allocator.free(template_path);

    const rendered = try globals.cache.renderTemplate(template_path, .{
        .message = "Hello from HTMX!",
        .timestamp = std.time.timestamp(),
    });
    defer globals.cache.allocator.free(rendered);

    const body = try ctx.allocator.dupe(u8, rendered);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    });
}

// Add to router
Route.init("/api/example-htmx").get({}, apiHtmxEndpoint).layer(),
```

### Mustache Templates

**File:** `backend/templates/example_htmx.html`

```html
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title text-2xl font-bold">
      HTMX Example
    </h2>
    <p class="text-base">{{message}}</p>
    <p class="text-sm text-base-content/60">
      Generated: {{timestamp}}
    </p>
  </div>
</div>
```

## Best Practices

### HTMX

1. **Use Semantic HTML**
   ```html
   <!-- Good -->
   <button hx-get="/api/data">Load</button>
   
   <!-- Avoid -->
   <div onclick="htmx.ajax('GET', '/api/data')">Load</div>
   ```

2. **Provide Fallbacks**
   ```html
   <noscript>
     JavaScript is required for this application.
   </noscript>
   ```

3. **Handle Loading States**
   ```html
   <button hx-get="/api/data" hx-indicator="#loading">
     Load
   </button>
   <span id="loading" class="hidden">Loading...</span>
   ```

4. **Use hx-target Appropriately**
   - Target specific elements when possible
   - Use `hx-target="closest .container"` for dynamic targets

### Alpine.js

1. **Keep Components Small**
   ```html
   <!-- Good -->
   <div x-data="{ count: 0 }">
     <button @click="count++">Increment</button>
     <span x-text="count"></span>
   </div>
   ```

2. **Avoid Inline JavaScript**
   ```html
   <!-- Avoid -->
   <div x-data="{ count: 0 }">
     <button onclick="count++">Bad</button>
   </div>
   
   <!-- Good -->
   <div x-data="{ count: 0 }">
     <button @click="count++">Good</button>
   </div>
   ```

3. **Use x-show Instead of x-if When Possible**
   ```html
   <!-- Good (CSS display) -->
   <div x-show="isVisible">
     Content
   </div>
   
   <!-- Use x-if only when element should be removed -->
   <template x-if="isVisible">
     <div>Content</div>
   </template>
   ```

### Combined Patterns

1. **HTMX for Data, Alpine for UI State**
   - Use HTMX to fetch/update content
   - Use Alpine.js for managing loading states, form validation, etc.

2. **Separate Concerns**
   - Don't use Alpine.js to manage server data
   - Don't use HTMX for simple UI interactions

3. **Progressive Enhancement**
   - Start with static HTML
   - Add HTMX for dynamic content
   - Add Alpine.js for interactivity

## Troubleshooting

### HTMX Not Working

1. Check HTMX is loaded in `main.ts`
2. Check browser console for errors
3. Ensure backend returns HTML (not JSON) for HTMX endpoints
4. Verify `hx-get`/`hx-post` URLs are correct

### Alpine.js Not Working

1. Check Alpine.js is loaded in `main.ts`
2. Check browser console for errors
3. Ensure `x-data` is set on parent elements
4. Verify `x-on` events are correctly bound

### Conflicts Between HTMX and Alpine.js

**Common Issue:** Alpine.js re-initializing HTMX elements

**Solution:** Use `@htmx:after-swap` to re-initialize Alpine components:

```html
<div x-data="{ items: [] }">
  <div 
    id="item-list"
    hx-get="/api/items" 
    @htmx:after-swap="items = $el.querySelectorAll('.item').toArray()"
  >
    <!-- HTMX updates this div -->
  </div>
</div>
```

## Performance Tips

1. **Minimize DOM Manipulation**
   - Use `hx-swap="outerHTML"` sparingly
   - Prefer `hx-swap="innerHTML"` when possible

2. **Use Alpine.js Computed Properties**
   - Cache expensive calculations
   - Avoid recomputing on every render

3. **Lazy Load Alpine Components**
   ```html
   <div x-data="{ showComponent: false }">
     <button @click="showComponent = true">Show</button>
     <template x-if="showComponent">
       <div x-data="myComponent()">...</div>
     </template>
   </div>
   ```

## References

- [HTMX Documentation](https://htmx.org/docs/)
- [Alpine.js Documentation](https://alpinejs.dev/)
- [Alpine.js Examples](https://htmx.org/examples/)
- [Alpine.js Essentials](https://alpinejs.dev/essentials.html)
- [Alpine.js Reference](https://alpinejs.dev/)