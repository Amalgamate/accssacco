import { defineConfig } from 'vite'
import fs from 'fs'
import path from 'path'

export default defineConfig({
  root: '.',
  server: {
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        const url = req.url.split('?')[0];
        if (url === '/api/status') {
          res.end(JSON.stringify({ status: 'ok' }));
          return;
        }
        if (url === '/api/delete-image' && req.method === 'POST') {
          console.log('[API] Processing delete request for:', req.url);
          let body = '';
          req.on('data', chunk => { body += chunk.toString(); });
          req.on('end', async () => {
            try {
              const data = JSON.parse(body);
              const { src } = data; // e.g. /images/gellery/2024/IMG_9472.webp
              
              const publicPath = path.join(process.cwd(), 'public', src);
              const originalPath = publicPath.replace('.webp', '.jpg'); // Also try to delete original
              
              if (fs.existsSync(publicPath)) fs.unlinkSync(publicPath);
              if (fs.existsSync(originalPath)) fs.unlinkSync(originalPath);

              // Also try with .jpeg, .png just in case
              ['.jpeg', '.png', '.JPG'].forEach(ext => {
                const altPath = publicPath.replace('.webp', ext);
                if (fs.existsSync(altPath)) fs.unlinkSync(altPath);
              });

              // UPDATE gallery-data.json
              const jsonPath = path.join(process.cwd(), 'public/images/gellery/gallery-data.json');
              if (fs.existsSync(jsonPath)) {
                 const gallery = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
                 const filtered = gallery.filter(item => item.src !== src);
                 fs.writeFileSync(jsonPath, JSON.stringify(filtered, null, 2));
              }

              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ success: true }));
            } catch (err) {
              res.statusCode = 500;
              res.end(JSON.stringify({ success: false, error: err.message }));
            }
          });
        } else {
          next();
        }
      });
    }
  },
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
