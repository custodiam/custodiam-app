# Etapa 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .
# --dart-define-from-file=config/prod.json injects the public API/Keycloak URLs
# into the bundle. Without it the web build keeps the EnvConfig defaults
# (http://localhost:8000/api/v1, http://localhost:8080), and the PWA served at
# app.custodiam.es would try to login against localhost — see EN-08-32.
RUN flutter build web --release --dart-define-from-file=config/prod.json

# Etapa 2: Servir con Nginx
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
