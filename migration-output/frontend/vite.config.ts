import { defineConfig } from 'vite';

export default defineConfig({
  // aws-amplify (auth) aporta ~400 kB al bundle y la UI original ~200 kB: se eleva el umbral del aviso.
  build: { sourcemap: false, chunkSizeWarningLimit: 900 },
});
