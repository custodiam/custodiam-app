# justfile — atajos para custodiam-app (Flutter).
#
# Requiere: just 1.40+. Ver `custodiam-infra/justfile` para la nota de
# instalación con winget/brew/cargo.
#
# Las recetas envuelven invocaciones de `flutter` y `dart`. Si no usas
# just, los comandos equivalentes están en el README del repo y en la
# guía 20 (Setup Flutter) — los scripts no son obligatorios para nadie.
#
# Configuración por entorno: `config/dev.json` y `config/prod.json`
# pasados a Flutter vía `--dart-define-from-file`. El default sigue
# siendo dev (sin pasar nada), consistente con la convención de la
# industria y con la sección "Configuración por entorno — EnvConfig"
# del CLAUDE.md del repo.
#
# Listar recetas:    just -l
# Inspeccionar:      just --show prod-android
# Ejecutar:          just prod-android

# Receta por defecto: lista todo.
default:
    @just --list

# `flutter pub get` — sincronizar dependencias
pub-get:
    flutter pub get

# `flutter analyze` — análisis estático (aplica analysis_options.yaml)
analyze:
    flutter analyze

# `flutter test` — tests unit + widget
test:
    flutter test

# `flutter test --coverage` — tests con cobertura (lcov.info en coverage/)
test-coverage:
    flutter test --coverage

# `flutter test integration_test/` — tests E2E (requiere dispositivo/emulador + backend)
test-e2e:
    flutter test integration_test/all_tests.dart

# Code generation con build_runner (json_serializable, etc.)
gen:
    dart run build_runner build --delete-conflicting-outputs

# Code generation en modo continuo (regenera al guardar)
gen-watch:
    dart run build_runner watch

# `flutter clean` — limpiar build/ y caches de pub
clean:
    flutter clean

# Listar dispositivos disponibles para `flutter run`
devices:
    flutter devices

# Lanzar la app en DESARROLLO (defaults de EnvConfig → localhost del stack dev)
dev:
    flutter run

# Lanzar la app contra PROD en release (Android o iOS según `flutter devices`)
prod:
    flutter run --release --dart-define-from-file=config/prod.json

# Lanzar contra PROD en release apuntando a Chrome (PWA contra api/auth públicos)
prod-web:
    flutter run -d chrome --release --dart-define-from-file=config/prod.json

# Build APK release contra PROD (sale en build/app/outputs/flutter-apk/)
build-apk-prod:
    flutter build apk --release --dart-define-from-file=config/prod.json

# Build App Bundle release contra PROD (formato para Google Play)
build-aab-prod:
    flutter build appbundle --release --dart-define-from-file=config/prod.json

# Build iOS release contra PROD (firmar después en Xcode si se va a TestFlight)
build-ios-prod:
    flutter build ios --release --dart-define-from-file=config/prod.json

# Build web release contra PROD (sale en build/web/, sirve estática)
build-web-prod:
    flutter build web --release --dart-define-from-file=config/prod.json
