Resumen de `firestore.rules` y cómo probar/desplegar

Qué hacen estas reglas
- Requieren que solo usuarios autenticados y con correo verificado (`email_verified == true`) puedan crear documentos en `resultados`.
- Validan campos: `score` (int), `totalQuestions` (int), `timeTaken` (number), `answers` (map), `failedQuestions` (list o null), `topic` (string).
- Permiten que el propietario (userId) lea sus propios `resultados` y que solo el propietario o un `admin` con claim `admin==true` pueda actualizar o borrar.
- Mantienen `topics/questions` como lectura pública, escritura solo para admin.

Probar antes de desplegar
- Usa Rules Playground en Firebase Console → Firestore → Rules → Run a request: simula una operación con `auth` y el `request.resource` (payload) que imprime la app.
- Recomiendo también usar el emulador para pruebas locales exhaustivas:
  1. Instala y configura Firebase CLI si no lo hiciste.
  2. Ejecuta: `firebase emulators:start --only firestore,auth`
  3. Usa la app apuntando al emulador (ver doc oficial) o herramientas de prueba para enviar requests.

Desplegar a producción
- Cuando lo hayas probado, despliega con:
  `firebase deploy --only firestore:rules`

Notas adicionales
- Si necesitas crear un panel administrativo que pueda escribir en `topics` o `resultados` de otros usuarios, asigna un custom claim `admin: true` a las cuentas administrativas mediante Firebase Admin SDK y deja `request.auth.token.admin == true` para permisos.
- Asegúrate de que la app envíe exactamente los campos validados (por ejemplo `timeTaken` en lugar de `time`), o adapta las reglas para aceptar ambos nombres si fuese necesario.