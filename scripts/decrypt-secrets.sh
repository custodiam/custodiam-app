#!/usr/bin/env bash
# Descifra los secretos de cliente (sops+age) a los archivos en claro
# que Gradle (Android) y Xcode (iOS) leen al compilar.
#
# Se ejecuta UNA vez tras clonar (y solo de nuevo si rota una clave).
# Tras esto, `flutter run` / `flutter build` no cambian. Los archivos
# generados están gitignored; nunca se commitean en claro.
#
# Uso: `just secrets`  (o  `bash scripts/decrypt-secrets.sh`)
set -euo pipefail

cd "$(dirname "$0")/.."

# En Windows sops busca la clave age en %APPDATA%; en este equipo vive
# en ~/.config/sops/age/keys.txt. Respetamos un SOPS_AGE_KEY_FILE ya
# exportado; si no, usamos la ruta canónica del proyecto.
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

secrets_file="secrets/maps.sops.env"
if [[ ! -f "$secrets_file" ]]; then
  echo "ERROR: no existe $secrets_file" >&2
  exit 1
fi

decrypted="$(sops -d --input-type dotenv --output-type dotenv "$secrets_file")"

value_of() { printf '%s\n' "$decrypted" | grep "^$1=" | cut -d= -f2-; }

android_key="$(value_of MAPS_API_KEY_ANDROID)"
ios_key="$(value_of MAPS_API_KEY_IOS)"

if [[ -z "$android_key" || -z "$ios_key" ]]; then
  echo "ERROR: faltan MAPS_API_KEY_ANDROID / MAPS_API_KEY_IOS en $secrets_file" >&2
  exit 1
fi

mkdir -p android ios/Flutter
printf 'MAPS_API_KEY=%s\n' "$android_key" > android/secrets.properties
printf 'MAPS_API_KEY = %s\n' "$ios_key" > ios/Flutter/Secrets.xcconfig

echo "OK: generados android/secrets.properties y ios/Flutter/Secrets.xcconfig"
