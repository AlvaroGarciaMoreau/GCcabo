Despliegue de la versión web

Pasos rápidos:

1) Construir la web con base-href (importante si la vas a servir desde una subruta):

   flutter build web --release --base-href /gccabo/

   Esto genera la carpeta `build/web` lista para subir al servidor.

2) Subir el contenido de `build/web` a tu servidor en la ruta `/gccabo/`.

3) Asegúrate de que el servidor devuelve `index.html` para rutas de la SPA (ejemplo nginx):

   location /gccabo/ {
       root /var/www/moreausoft; # ruta donde colocaste los archivos
       try_files $uri $uri/ /gccabo/index.html;
   }

4) Si usas Apache, habilita `FallbackResource` o `mod_rewrite` para reenviar a `index.html`.

5) Firebase / Auth:
   - Si usas Firebase Authentication, añade `moreausoft.com` como dominio autorizado en la consola Firebase (Auth -> Sign-in method -> Authorized domains).

6) Manifest y PWA:
   - `web/manifest.json` ya ha sido actualizado con `start_url: "/gccabo/"`.

7) Probar localmente (servidor estático):

   cd build/web
   python -m http.server 8000
   # abrir http://localhost:8000/gccabo/ o configurar el documento raíz según subruta

Notas:
- Usa `--base-href /gccabo/` cuando construyas para asegurar que las rutas y assets apunten correctamente.
- Si tu hosting soporta redirecciones o rewrites (Cloudflare, Netlify, Vercel, etc.), configura una regla que devuelva `index.html` para rutas que no existan para que la SPA maneje el enrutado.
