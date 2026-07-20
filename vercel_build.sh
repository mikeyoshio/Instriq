#!/bin/bash
# Build script para Vercel: instala Flutter (no viene preinstalado en el
# entorno de build de Vercel) y compila la app web.
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

flutter config --enable-web
flutter pub get
flutter gen-l10n
flutter build web --release
