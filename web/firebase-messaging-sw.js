// Service Worker para recibir mensajes FCM en background en Web (EN-06-02).
//
// Se sirve desde el root del build (`/firebase-messaging-sw.js`); el SDK
// `firebase/messaging` lo registra automáticamente cuando el cliente llama
// a `getToken(vapidKey: ...)` en una página HTTPS (o localhost en dev).
//
// La config Firebase Web es pública por diseño (Firebase usa Security
// Rules para proteger los datos, no la API key). Los mismos valores ya
// están commiteados en `lib/firebase_options.dart` desde EN-08-19, así
// que duplicarlos aquí no añade riesgo nuevo.
//
// La VAPID key NO va en este archivo: se pasa al cliente vía
// `--dart-define=FCM_VAPID_KEY=...` y el cliente la entrega al SDK al
// pedir token. Sin VAPID, `getToken` devuelve null y el feature entra
// automáticamente en modo `FcmServiceUnavailable`.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD3xgeB8UYht877jl9WOo-ffK0GkIIKNW4',
  authDomain: 'custodiam.firebaseapp.com',
  projectId: 'custodiam',
  messagingSenderId: '585400881584',
  appId: '1:585400881584:web:8ced3f31f2001f6ff08675',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const tipo = (payload.data && payload.data.tipo) || 'notificacion';
  const titulo = (payload.notification && payload.notification.title) || 'Custodiam';
  const cuerpo = (payload.notification && payload.notification.body) || '';

  // Las emergencias se diferencian visualmente (tag de reemplazo + sin
  // auto-dismiss) para que el voluntario las distinga de los avisos
  // ordinarios cuando la pestaña no está al frente.
  const opciones = {
    body: cuerpo,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    tag: tipo === 'emergencia' ? 'custodiam-emergencia' : undefined,
    requireInteraction: tipo === 'emergencia',
  };

  return self.registration.showNotification(titulo, opciones);
});

// Al hacer click en la notificación se abre / enfoca la pestaña de la
// app y se navega al servicio asociado si el payload trae `servicio_id`.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const servicioId = data.servicio_id;
  const ruta = servicioId ? `/servicios/${servicioId}` : '/home';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        // Si ya hay una pestaña Custodiam abierta, la enfocamos y la
        // navegamos al servicio. Evita abrir múltiples instancias al
        // tocar notificaciones repetidas.
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.postMessage({ tipo: 'navigate', ruta });
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(ruta);
      }
      return null;
    }),
  );
});
