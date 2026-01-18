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
        htmx.process(app) // Explicitly tell HTMX to look at this node
    }
})
