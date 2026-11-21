# Driver Trip · Shuttle Vacation

Portal web independiente para conductores. Consulta servicios asignados, actualiza estados y comparte GPS con la API central.

## Despliegue
1. Publica este repositorio como sitio estático.
2. Asigna `drivertrip.shuttlevacation.com`.
3. En `assets/config.js`, configura `API_BASE_URL` con `https://api.shuttlevacation.com`.
4. Añade `https://drivertrip.shuttlevacation.com` a `CORS_ORIGINS` de la API.
5. Sirve por HTTPS. El GPS del navegador requiere contexto seguro.
6. Crea las cuentas desde Admin Trip. No compartas cuentas entre conductores.

## Aplicación instalable
Incluye manifiesto PWA y service worker para instalar el panel desde un navegador compatible y conservar la interfaz básica en caché. Las operaciones y el GPS siguen requiriendo conexión con la API; no se guardan datos sensibles de servicios para uso offline.

## Funciones
- Inicio y cierre de sesión individual.
- Consulta únicamente los servicios asignados al conductor autenticado.
- Actualización de estado y ETA.
- Compartir ubicación automáticamente para todos los servicios asignados al conductor cuando entren en la ventana de siete horas previa o estén en curso; no requiere seleccionar un servicio.
- La ubicación web depende de que Driver Trip permanezca abierto y el navegador permita geolocalización. Los navegadores pueden suspender el GPS cuando la pestaña queda en segundo plano, el dispositivo se bloquea o el sistema ahorra batería; la web/PWA no garantiza rastreo continuo con la pantalla apagada.
- Actualización automática de servicios cada 15 segundos mediante HTTPS; no requiere WebSockets.

Las credenciales de sesión se mantienen en `sessionStorage` y se revocan al cerrar sesión.

## Controles operativos
El selector de estado muestra únicamente el estado actual y las transiciones permitidas por la API. La API vuelve a validar cada cambio; la interfaz no sustituye la autorización del servidor. El GPS se solicita tras iniciar sesión cuando exista al menos un servicio dentro de la ventana de seguimiento.


## Hostinger PHP/HTML deployment
This is a static browser application (HTML, CSS and JavaScript); it does not require Node.js or a PHP runtime process.
1. Create the subdomain in Hostinger hPanel and assign its document root.
2. Deploy this repository's contents to that document root using **Sitio web PHP/HTML**.
3. Keep `assets/config.js` pointed at `https://api.shuttlevacation.com`.
4. Enable SSL/HTTPS for the subdomain. Driver Trip requires HTTPS for browser GPS.
5. Verify the home page, static assets and API connectivity after the API is configured.
6. Do not place admin API tokens or driver credentials in repository files. Admin token is entered at login; driver accounts are created from Admin Trip.

The application polls the central API every 15 seconds; no Node.js process or WebSocket service is required.
