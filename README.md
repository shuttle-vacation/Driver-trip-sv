# Driver Trip · Shuttle Vacation

Portal web independiente para conductores. Consulta servicios asignados, actualiza estados y comparte GPS con la API central.

## Despliegue
1. Publica este repositorio como sitio estático.
2. Asigna `drivertrip.shuttlevacation.com`.
3. En `assets/config.js`, configura `API_BASE_URL` con `https://api.shuttlevacation.com`.
4. Añade `https://drivertrip.shuttlevacation.com` a `CORS_ORIGINS` y `WS_ALLOWED_ORIGINS` de la API.
5. Sirve por HTTPS. El GPS del navegador requiere contexto seguro.
6. Crea las cuentas desde Admin Trip. No compartas cuentas entre conductores.

## Aplicación instalable\nIncluye manifiesto PWA y service worker para instalar el panel desde un navegador compatible y conservar la interfaz básica en caché. Las operaciones y el GPS siguen requiriendo conexión con la API; no se guardan datos sensibles de servicios para uso offline.\n\n## Funciones
- Inicio y cierre de sesión individual.
- Consulta únicamente los servicios asignados al conductor autenticado.
- Actualización de estado y ETA.
- Compartir ubicación mientras el servicio está en una fase operativa.
- Actualización de lista mediante WebSocket sin transmitir información del viaje.

Las credenciales de sesión se mantienen en `sessionStorage` y se revocan al cerrar sesión.