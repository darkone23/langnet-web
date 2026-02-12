# DaisyUI + Tailwind CSS Guide

This guide covers styling with Tailwind CSS v4 and DaisyUI v5 in the langnet-web project.

## Overview

- **Tailwind CSS v4**: Utility-first CSS framework with the new v4 engine
- **DaisyUI v5**: Component library built on Tailwind CSS

**Philosophy:** Use Tailwind utility classes for layout and DaisyUI components for pre-built UI elements.

## Project Setup

### Tailwind Configuration (`frontend/src/tailwind.css`)

```css
@import "tailwindcss";

@plugin "daisyui";

@source "../../backend/templates";  // Scans backend templates for classes
@source "../index.html";
@source ".";
```

**Key Points:**
- `@import "tailwindcss"` - Imports Tailwind v4 engine
- `@plugin "daisyui"` - Enables DaisyUI components
- `@source` - Directories to scan for classes (v4 feature)

### Vite Integration

Vite plugin configured in `vite.config.ts`:

```typescript
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss()]
})
```

## Tailwind CSS v4 Basics

### Utility Classes

Tailwind provides utility classes for common CSS properties:

```html
<!-- Spacing -->
<div class="p-4 m-2">
  Padding 4, Margin 2
</div>

<!-- Flexbox -->
<div class="flex items-center justify-between">
  Flex container with centered items
</div>

<!-- Typography -->
<h1 class="text-2xl font-bold text-primary">
  Large, bold, primary text
</h1>

<!-- Colors -->
<div class="bg-blue-500 text-white">
  Blue background, white text
</div>
```

### Responsive Design

```html
<!-- Mobile: 1 column, Desktop: 3 columns -->
<div class="grid grid-cols-1 md:grid-cols-3">
  <!-- Items -->
</div>

<!-- Different padding on breakpoints -->
<div class="p-4 md:p-8 lg:p-12">
  Responsive padding
</div>
```

## DaisyUI Components

### Buttons

```html
<!-- Primary button -->
<button class="btn btn-primary">
  Primary Button
</button>

<!-- Secondary button -->
<button class="btn btn-secondary">
  Secondary Button
</button>

<!-- Accent button -->
<button class="btn btn-accent">
  Accent Button
</button>

<!-- Disabled button -->
<button class="btn btn-disabled" disabled>
  Disabled
</button>
```

### Cards

```html
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Card Title</h2>
    <p class="text-base">Card content goes here.</p>
  </div>
</div>
```

### Alerts

```html
<!-- Info alert -->
<div class="alert alert-info">
  <svg>...</svg>
  <span>Information message</span>
</div>

<!-- Success alert -->
<div class="alert alert-success">
  <svg>...</svg>
  <span>Success message</span>
</div>

<!-- Warning alert -->
<div class="alert alert-warning">
  <svg>...</svg>
  <span>Warning message</span>
</div>

<!-- Error alert -->
<div class="alert alert-error">
  <svg>...</svg>
  <span>Error message</span>
</div>
```

### Forms

```html
<!-- Input -->
<div class="form-control">
  <label class="label">
    <span class="label-text">Email</span>
  </label>
  <input type="email" placeholder="Enter email" class="input input-bordered" />
</div>

<!-- Textarea -->
<div class="form-control">
  <label class="label">
    <span class="label-text">Message</span>
  </label>
  <textarea class="textarea textarea-bordered" placeholder="Your message"></textarea>
</div>

<!-- Select -->
<div class="form-control">
  <label class="label">
    <span class="label-text">Select option</span>
  </label>
  <select class="select select-bordered">
    <option>Option 1</option>
    <option>Option 2</option>
  </select>
</div>
```

### Navigation

```html
<!-- Navbar -->
<div class="navbar bg-base-100 shadow-lg">
  <div class="flex-1">
    <a class="btn btn-ghost text-xl">My App</a>
  </div>
  <div class="flex-none dropdown dropdown-end">
    <div tabindex="0" role="button" class="btn btn-square btn-ghost">
      <svg>...</svg>
    </div>
    <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
      <li><a>Home</a></li>
      <li><a>About</a></li>
      <li><a>Contact</a></li>
    </ul>
  </div>
</div>
```

### Modals

```html
<!-- Modal -->
<button class="btn" onclick="my_modal_3.showModal()">
  Open Modal
</button>

<dialog id="my_modal_3" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Hello!</h3>
    <p class="py-4">Press ESC key or click the button below to close</p>
    <div class="modal-action">
      <form method="dialog">
        <button class="btn">Close</button>
      </form>
    </div>
  </div>
</dialog>
```

## Theme Configuration

### Default Themes

DaisyUI supports multiple themes:

```html
<!-- Light theme (default) -->
<html data-theme="light">

<!-- Dark theme -->
<html data-theme="dark">

<!-- Custom theme -->
<html data-theme="cupcake">
```

### Theme Switching

```html
<div class="dropdown dropdown-end">
  <div tabindex="0" role="button" class="btn">
    Theme
  </div>
  <ul class="dropdown-content z-[1] menu bg-base-100 rounded-box w-52 p-2 shadow">
    <li><button onclick="document.documentElement.setAttribute('data-theme', 'light')">Light</button></li>
    <li><button onclick="document.documentElement.setAttribute('data-theme', 'dark')">Dark</button></li>
    <li><button onclick="document.documentElement.setAttribute('data-theme', 'cupcake')">Cupcake</button></li>
  </ul>
</div>
```

## Using with HTMX + Alpine.js

### DaisyUI with HTMX

```html
<!-- DaisyUI styled HTMX button -->
<button 
  class="btn btn-primary" 
  hx-get="/api/content" 
  hx-target="#content"
>
  Load Content
</button>
<div id="content"></div>

<!-- DaisyUI styled HTMX form -->
<form class="form-control" hx-post="/api/submit">
  <label class="label">
    <span class="label-text">Name</span>
  </label>
  <input 
    type="text" 
    class="input input-bordered" 
    name="name"
  >
  <button type="submit" class="btn btn-primary mt-2">Submit</button>
</form>
```

### DaisyUI with Alpine.js

```html
<!-- DaisyUI styled Alpine component -->
<div class="card bg-base-100 shadow-xl" x-data="{ expanded: false }">
  <div class="card-body">
    <h2 class="card-title">Collapsible Card</h2>
    <button 
      class="btn" 
      @click="expanded = !expanded"
    >
      Toggle
    </button>
    <div x-show="expanded" class="mt-4">
      <p>This content is conditionally shown.</p>
    </div>
  </div>
</div>
```

### All Three Combined

```html
<div class="card bg-base-100 shadow-xl" x-data="{ 
  loading: false,
  message: ''
}">
  <div class="card-body">
    <h2 class="card-title">Fetch Data</h2>
    
    <!-- DaisyUI button with HTMX and Alpine -->
    <button 
      class="btn btn-primary" 
      hx-get="/api/data" 
      hx-target="#result"
      hx-indicator="#spinner"
      @htmx:before-request="loading = true"
      @htmx:after-request="loading = false"
      :disabled="loading"
    >
      Fetch Data
    </button>
    
    <!-- DaisyUI alert with Alpine -->
    <div 
      id="spinner" 
      class="alert alert-info mt-4" 
      x-show="loading"
    >
      <span>Loading...</span>
    </div>
    
    <!-- Result area -->
    <div id="result" class="mt-4"></div>
  </div>
</div>
```

## Best Practices

### Tailwind CSS

1. **Use Utility Classes Over Custom CSS**
   ```html
   <!-- Good -->
   <div class="p-4 m-2 bg-white rounded-lg">
     Content
   </div>
   
   <!-- Avoid -->
   <div class="custom-container">
     Content
   </div>
   ```

2. **Responsive-First Design**
   ```html
   <!-- Good -->
   <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
     Items
   </div>
   ```

3. **Use Semantic Colors**
   ```html
   <!-- Good -->
   <button class="btn btn-primary">Primary Action</button>
   <button class="btn btn-secondary">Secondary Action</button>
   ```

### DaisyUI

1. **Use Component Variations**
   ```html
   <!-- Outline button -->
   <button class="btn btn-outline">Outline</button>
   
   <!-- Ghost button -->
   <button class="btn btn-ghost">Ghost</button>
   ```

2. **Use Size Variants**
   ```html
   <!-- Small button -->
   <button class="btn btn-sm btn-primary">Small</button>
   
   <!-- Large button -->
   <button class="btn btn-lg btn-primary">Large</button>
   ```

3. **Combine Components**
   ```html
   <!-- Card with alert and button -->
   <div class="card bg-base-100 shadow-xl">
     <div class="card-body">
       <div class="alert alert-warning">
         Warning: Read carefully
       </div>
       <button class="btn btn-primary mt-4">I Understand</button>
     </div>
   </div>
   ```

### Template Scanning

Tailwind v4 scans specified directories for class usage:

```css
@source "../../backend/templates";  // Scan backend templates
@source "../index.html";         // Scan HTML entry
@source ".";                    // Scan frontend source
```

**Why This Matters:**
- Backend templates use DaisyUI classes
- Tailwind needs to see them to include them in build
- Ensures production CSS includes all used classes

## Customization

### Extending DaisyUI

```html
<!-- DaisyUI component with custom classes -->
<button class="btn btn-primary custom-shadow">
  Custom Button
</button>
```

### Custom Theme

```css
/* Custom colors in tailwind.css */
@import "tailwindcss";
@plugin "daisyui";

@theme {
  --color-primary: #ff6b6b;
  --color-secondary: #1d232e;
}
```

### Component Customization

```html
<!-- Override DaisyUI styles -->
<div class="card bg-base-100 shadow-xl" style="border-radius: 8px;">
  <div class="card-body">
    Custom rounded corners
  </div>
</div>
```

## Performance

### Production Build

Tailwind v4 with Vite automatically:
1. Purges unused CSS
2. Optimizes class names
3. Generates minimal CSS bundle

### Minimizing Bundle Size

1. **Use Only Needed Components**
   - Import only DaisyUI components you use
   - Consider building custom components instead

2. **Avoid Arbitrary Values**
   ```html
   <!-- Good -->
   <div class="p-4">Fixed padding</div>
   
   <!-- Avoid when possible -->
   <div class="p-[17px]">Arbitrary padding</div>
   ```

3. **Use JIT Mode**
   - Tailwind v4 uses JIT by default
   - Classes are generated on-the-fly
   - More efficient than CSS file scanning

## Troubleshooting

### Styles Not Applying

1. Check `tailwind.css` is imported in `main.ts`
2. Check `@source` directives include all relevant directories
3. Check class names are correct
4. Clear browser cache

### DaisyUI Components Not Working

1. Check DaisyUI is imported in `tailwind.css`
2. Check DaisyUI version in `package.json`
3. Verify HTML structure matches component requirements
4. Check for conflicting CSS

### Theme Not Switching

1. Verify `data-theme` attribute on `<html>` element
2. Check theme name is valid
3. Look for JavaScript errors in console

## References

- [Tailwind CSS v4 Documentation](https://tailwindcss.com/docs)
- [DaisyUI Documentation](https://daisyui.com/docs/)
- [DaisyUI Components](https://daisyui.com/components/)
- [DaisyUI Themes](https://daisyui.com/docs/themes/)
