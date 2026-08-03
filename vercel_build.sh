#!/bin/bash
# Build script para Vercel: instala Flutter (no viene preinstalado en el
# entorno de build de Vercel) y compila la app web.
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

# lib/firebase_options.dart no se commitea (ver .gitignore) -- se genera aqui
# a partir de variables de entorno de Vercel. Solo hace falta el bloque
# `web`: en el target web, DefaultFirebaseOptions.currentPlatform (llamado
# desde main.dart) siempre devuelve `web` via kIsWeb, sin pasar por android/
# ios/windows -- no hace falta exponer esas claves en Vercel para compilar.
: "${FIREBASE_WEB_API_KEY:?Falta configurar FIREBASE_WEB_API_KEY en las variables de entorno de Vercel (ver README, seccion Despliegue)}"
: "${FIREBASE_WEB_APP_ID:?Falta configurar FIREBASE_WEB_APP_ID en las variables de entorno de Vercel}"
: "${FIREBASE_MESSAGING_SENDER_ID:?Falta configurar FIREBASE_MESSAGING_SENDER_ID en las variables de entorno de Vercel}"
: "${FIREBASE_PROJECT_ID:?Falta configurar FIREBASE_PROJECT_ID en las variables de entorno de Vercel}"
: "${FIREBASE_AUTH_DOMAIN:?Falta configurar FIREBASE_AUTH_DOMAIN en las variables de entorno de Vercel}"
: "${FIREBASE_STORAGE_BUCKET:?Falta configurar FIREBASE_STORAGE_BUCKET en las variables de entorno de Vercel}"
: "${FIREBASE_MEASUREMENT_ID:?Falta configurar FIREBASE_MEASUREMENT_ID en las variables de entorno de Vercel}"

cat > lib/firebase_options.dart <<EOF
// Generado en build time por vercel_build.sh a partir de variables de
// entorno de Vercel -- no editar a mano, no se commitea (ver .gitignore).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '${FIREBASE_WEB_API_KEY}',
    appId: '${FIREBASE_WEB_APP_ID}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID}',
    projectId: '${FIREBASE_PROJECT_ID}',
    authDomain: '${FIREBASE_AUTH_DOMAIN}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET}',
    measurementId: '${FIREBASE_MEASUREMENT_ID}',
  );
}
EOF

flutter config --enable-web
flutter pub get
flutter gen-l10n
flutter build web --release
