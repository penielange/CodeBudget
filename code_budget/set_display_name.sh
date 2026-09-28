#!/bin/bash
# Définit le nom affiché "CodeBudget" (pas code_budget) sur Android / Linux / Web / iOS
set -e
cd "$(dirname "$0")"

# Android
if [ -f android/app/src/main/AndroidManifest.xml ]; then
  sed -i 's/android:label="[^"]*"/android:label="CodeBudget"/g' android/app/src/main/AndroidManifest.xml
  echo "✓ Android label → CodeBudget"
fi

# Linux
if [ -f linux/CMakeLists.txt ]; then
  sed -i 's/set(APPLICATION_ID "[^"]*")/set(APPLICATION_ID "com.codeanytime.codebudget")/g' linux/CMakeLists.txt 2>/dev/null || true
fi
# my_application.cc window title
if [ -f linux/runner/my_application.cc ]; then
  sed -i 's/gtk_header_bar_set_title(header_bar, "[^"]*")/gtk_header_bar_set_title(header_bar, "CodeBudget")/g' linux/runner/my_application.cc
  sed -i 's/gtk_window_set_title(window, "[^"]*")/gtk_window_set_title(window, "CodeBudget")/g' linux/runner/my_application.cc
  echo "✓ Linux window title → CodeBudget"
fi

# Web
if [ -f web/index.html ]; then
  sed -i 's/<title>[^<]*<\/title>/<title>CodeBudget<\/title>/g' web/index.html
  echo "✓ Web title → CodeBudget"
fi
if [ -f web/manifest.json ]; then
  sed -i 's/"name": "[^"]*"/"name": "CodeBudget"/g' web/manifest.json
  sed -i 's/"short_name": "[^"]*"/"short_name": "CodeBudget"/g' web/manifest.json
  echo "✓ Web manifest → CodeBudget"
fi

# iOS
if [ -f ios/Runner/Info.plist ]; then
  # CFBundleDisplayName
  /usr/bin/python3 - <<'PY'
import re, pathlib
p = pathlib.Path("ios/Runner/Info.plist")
if p.exists():
    t = p.read_text()
    t = re.sub(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*', r'\1CodeBudget', t)
    t = re.sub(r'(<key>CFBundleName</key>\s*<string>)[^<]*', r'\1CodeBudget', t)
    p.write_text(t)
    print("✓ iOS display name → CodeBudget")
PY
fi

echo "Terminé. Relance l'app / rebuild pour voir le nouveau nom."
