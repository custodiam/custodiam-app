# Custodiam App

App cliente multiplataforma de **Custodiam**, sistema de gestión para agrupaciones de Protección Civil. **Android + iOS + Web** desde un único código base Flutter.

📚 **Documentación completa:** <https://docs.custodiam.es>

🌐 **PWA en producción:** <https://app.custodiam.es>

## Stack

- [Flutter SDK 3.x](https://flutter.dev) + Dart 3.6+ (sealed classes para `Result<T>`)
- [Riverpod 2.6+](https://riverpod.dev) — state management (ADR-012)
- [go_router 17+](https://pub.dev/packages/go_router) — navegación
- [`http` 1.2+](https://pub.dev/packages/http) — cliente HTTP oficial (ADR-004)
- [`oauth2` 2.0+](https://pub.dev/packages/oauth2) + Keycloak — OAuth2 + PKCE (ADR-010)
- [`flutter_secure_storage` 10+](https://pub.dev/packages/flutter_secure_storage) — refresh tokens
- [Firebase FCM](https://firebase.google.com/docs/cloud-messaging) — push principal
- [ntfy](https://ntfy.sh) — push backup (ADR-005)
- Versión actual: `0.1.0+1`

## Plataformas soportadas

| Plataforma | Versión mínima | Decisión |
|---|---|---|
| Android | API 21 (Android 5.0) | Soporte amplio para parque actual |
| iOS | 15.0+ | ADR-022 (forzado por Firebase iOS SDK 12) |
| Web | Chrome / Edge / Safari / Firefox modernos | PWA con OAuth + PKCE (ADR-023) |

## Desarrollo local

```bash
# Instalar dependencias
flutter pub get

# Generar código (json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar
flutter run                           # dispositivo por defecto
flutter run -d chrome --web-port=3000 # Web (puerto 3000 obligatorio para OAuth)
flutter run -d <device-id>            # Android/iOS específico
```

> **Web + OAuth — puerto 3000 obligatorio en dev:** el cliente OIDC tiene registrado `http://localhost:3000/callback` en Keycloak. Si arrancas Flutter Web con un puerto distinto, el callback fallará.

## Comandos esenciales

```bash
# Análisis estático
flutter analyze

# Tests unit + widget
flutter test
flutter test --coverage

# Tests E2E móvil (Patrol) — en desarrollo (WIP), aún sin comando estable

# Code generation continuo durante desarrollo
dart run build_runner watch
```

## Builds de release

Parametrizados con `--dart-define` para apuntar a producción:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.custodiam.es/api/v1 \
  --dart-define=KEYCLOAK_BASE_URL=https://auth.custodiam.es

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.custodiam.es/api/v1 \
  --dart-define=KEYCLOAK_BASE_URL=https://auth.custodiam.es

flutter build ios --release --dart-define=...           # requiere macOS

flutter build web --release \
  --dart-define=API_BASE_URL=https://api.custodiam.es/api/v1 \
  --dart-define=KEYCLOAK_BASE_URL=https://auth.custodiam.es
```

## Arquitectura

**Clean Architecture estricta + Feature-first** (ADR-013):

```text
lib/
├── main.dart              # ProviderScope → CustodiamApp
├── app/                   # MaterialApp + router
├── core/                  # ui/ (Design System App*), helpers/, services/, config/
├── features/              # auth/, splash/, settings/, voluntarios/, ...
│   └── <feature>/
│       ├── domain/        # Entities (Dart puro, sin Flutter)
│       ├── data/          # Repos que devuelven Result<T>
│       └── presentation/  # ViewModels Riverpod + Pages ConsumerWidget
├── infrastructure/        # auth/, network/, di/, theme/
└── l10n/                  # es-ES (MVP solo castellano)
```

Patrones obligatorios:

- **`Result<T>` sealed** para errores (ADR-014). Repos nunca lanzan excepciones cross-layer.
- **Design System propio `App*`** (ADR-018) — `AppPrimaryButton`, `AppTextField`, `AppSnackbar`, etc. Material directo prohibido en `features/`.
- **EnvConfig vía `String.fromEnvironment`** (ADR-015) — sin JSON files.
- **`dev.log(name:)` estructurado** (ADR-016) — sin `print`.

## Más información

- **[docs.custodiam.es/empezar/app](https://docs.custodiam.es/empezar/app/)** — recorrido detallado de instalación.
- **[docs.custodiam.es/arquitectura](https://docs.custodiam.es/arquitectura/)** — diagramas del flujo OAuth (móvil vs web), Clean Architecture, asimetría de plataforma.
- **[docs.custodiam.es/adrs](https://docs.custodiam.es/adrs/)** — registro de decisiones (Riverpod, OAuth + PKCE, asimetría web/móvil, Design System).
- **[docs.custodiam.es/contribuir](https://docs.custodiam.es/contribuir/)** — proceso de PR, código de conducta.

## Repos relacionados

- [custodiam-api](https://github.com/custodiam/custodiam-api) — Backend FastAPI + SQLModel
- [custodiam-infra](https://github.com/custodiam/custodiam-infra) — Docker Compose + Keycloak + scripts
- [custodiam-book](https://github.com/custodiam/custodiam-book) — Source del book de documentación pública

## Licencia

[AGPL-3.0](./LICENSE) — Ver el archivo LICENSE para el texto completo.
