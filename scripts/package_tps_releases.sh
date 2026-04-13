#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPS_DIR="$ROOT_DIR/tps"
DIST_DIR="$ROOT_DIR/dist"
TOOLS_DIR="$ROOT_DIR/tools"
TEMPLATE_ARCHIVE="$TOOLS_DIR/Godot_v4.6.2-stable_export_templates.tpz"
TEMPLATE_URL="https://github.com/godotengine/godot/releases/download/4.6.2-stable/Godot_v4.6.2-stable_export_templates.tpz"
APPIMAGE_TOOL="$TOOLS_DIR/appimagetool-x86_64.AppImage"
APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
EXPORT_TEMPLATE_ROOT="$HOME/.local/share/godot/export_templates"

LINUX_BIN="$DIST_DIR/linux/WAR30K_Adventure_TPS.x86_64"
LINUX_PCK="$DIST_DIR/linux/WAR30K_Adventure_TPS.pck"
WINDOWS_EXE="$DIST_DIR/windows/WAR30K_Adventure_TPS.exe"
WINDOWS_PCK="$DIST_DIR/windows/WAR30K_Adventure_TPS.pck"
WINDOWS_ZIP="$DIST_DIR/windows/WAR30K_Adventure_TPS_windows_x86_64.zip"
APPDIR="$DIST_DIR/appimage/WAR30K-Adventure-TPS.AppDir"
APPIMAGE_OUT="$DIST_DIR/appimage/WAR30K-Adventure-TPS-x86_64.AppImage"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

ensure_templates() {
  local need_install=1
  local check_dir
  for check_dir in "4.6.2.stable" "4.6.2.stable.arch_linux.001aa128b"; do
    if [[ -f "$EXPORT_TEMPLATE_ROOT/$check_dir/linux_release.x86_64" && -f "$EXPORT_TEMPLATE_ROOT/$check_dir/windows_release_x86_64.exe" ]]; then
      need_install=0
      break
    fi
  done

  if [[ "$need_install" -eq 0 ]]; then
    return
  fi

  mkdir -p "$TOOLS_DIR"
  if [[ ! -f "$TEMPLATE_ARCHIVE" ]]; then
    wget -O "$TEMPLATE_ARCHIVE" "$TEMPLATE_URL"
  fi

  python - "$TEMPLATE_ARCHIVE" "$EXPORT_TEMPLATE_ROOT" <<'PY'
import os
import sys
import zipfile

archive_path = sys.argv[1]
export_root = sys.argv[2]
targets = [
    "4.6.2.stable",
    "4.6.2.stable.arch_linux.001aa128b",
]
files = [
    "templates/linux_release.x86_64",
    "templates/windows_release_x86_64.exe",
    "templates/version.txt",
    "templates/icudt_godot.dat",
]

with zipfile.ZipFile(archive_path) as zf:
    for target in targets:
        out_dir = os.path.join(export_root, target)
        os.makedirs(out_dir, exist_ok=True)
        for name in files:
            data = zf.read(name)
            dst = os.path.join(out_dir, os.path.basename(name))
            with open(dst, "wb") as handle:
                handle.write(data)
PY
}

write_export_presets() {
  cat > "$TPS_DIR/export_presets.cfg" <<'EOF'
[preset.0]
name="Linux/X11"
platform="Linux/X11"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="art/sources/*"
export_path="../dist/linux/WAR30K_Adventure_TPS.x86_64"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]
binary_format/architecture="x86_64"
binary_format/embed_pck=false
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false

[preset.1]
name="Windows Desktop"
platform="Windows Desktop"
runnable=false
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="art/sources/*"
export_path="../dist/windows/WAR30K_Adventure_TPS.exe"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.1.options]
binary_format/architecture="x86_64"
codesign/enable=false
codesign/timestamp=false
codesign/timestamp_server_url=""
codesign/digest_algorithm=1
codesign/description=""
codesign/custom_options=PackedStringArray()
application/modify_resources=false
application/icon=""
application/console_wrapper_icon=""
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
EOF
}

ensure_appimagetool() {
  mkdir -p "$TOOLS_DIR"
  if [[ ! -x "$APPIMAGE_TOOL" ]]; then
    wget -O "$APPIMAGE_TOOL" "$APPIMAGE_TOOL_URL"
    chmod +x "$APPIMAGE_TOOL"
  fi
}

build_exports() {
  mkdir -p "$DIST_DIR/linux" "$DIST_DIR/windows" "$DIST_DIR/appimage"
  GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path "$TPS_DIR" --export-release "Linux/X11" "$LINUX_BIN"
  GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path "$TPS_DIR" --export-release "Windows Desktop" "$WINDOWS_EXE"
}

build_appimage() {
  rm -rf "$APPDIR"
  mkdir -p "$APPDIR/usr/bin"

  cp "$LINUX_BIN" "$APPDIR/usr/bin/"
  cp "$LINUX_PCK" "$APPDIR/usr/bin/"
  cp "$TPS_DIR/icon.svg" "$APPDIR/war30k-adventure-tps.svg"

  cat > "$APPDIR/war30k-adventure-tps.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=WAR30K Adventure TPS
Comment=Third-person Death Guard action prototype
Exec=WAR30K_Adventure_TPS.x86_64
Icon=war30k-adventure-tps
Categories=Game;ActionGame;
Terminal=false
EOF

  cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export PATH="$HERE/usr/bin:$PATH"
exec "$HERE/usr/bin/WAR30K_Adventure_TPS.x86_64" "$@"
EOF
  chmod +x "$APPDIR/AppRun"

  ARCH=x86_64 "$APPIMAGE_TOOL" "$APPDIR" "$APPIMAGE_OUT"
}

build_windows_zip() {
  rm -f "$WINDOWS_ZIP"
  (
    cd "$DIST_DIR/windows"
    zip -9 -q "$(basename "$WINDOWS_ZIP")" "$(basename "$WINDOWS_EXE")" "$(basename "$WINDOWS_PCK")"
  )
}

main() {
  require_cmd godot
  require_cmd wget
  require_cmd python
  require_cmd zip

  ensure_templates
  write_export_presets
  ensure_appimagetool
  build_exports
  build_appimage
  build_windows_zip

  echo "Created Linux AppImage: $APPIMAGE_OUT"
  echo "Created Windows executable: $WINDOWS_EXE"
  echo "Created Windows bundle: $WINDOWS_ZIP"
}

main "$@"
