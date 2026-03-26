import { defineConfig } from 'vite'

export default defineConfig({
  root: '.',
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: 'index.html',
        about: 'about.html',
        loans: 'loans.html',
        savings: 'savings.html',
        downloads: 'downloads.html',
        contact: 'contact.html',
        blog: 'blog.html',
        gallery: 'gallery.html',
        governance: 'governance.html',
        board: 'board.html',
        management: 'management.html',
        supervisory: 'supervisory.html',
      }
    }
  }
})
