import { defineConfig } from 'vite'
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  server: {
    port: 43210,
    allowedHosts: [
      "truenas-qemu-nixos.snake-dojo.ts.net"
    ],
    proxy: {
      '/api': {
        target: 'http://localhost:43280',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
  },
  plugins: [
    tailwindcss()
  ]
})
