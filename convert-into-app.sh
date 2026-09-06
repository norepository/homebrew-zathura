#!/usr/bin/env bash
# Build a self-contained /Applications/Zathura.app: every dylib, plugin and GTK
# runtime file is copied inside the bundle and relinked to @executable_path, so
# the app keeps working after `brew upgrade` or even `brew uninstall`.
set -euo pipefail

APP=${1:-/Applications/Zathura.app}
[[ $APP == *.app ]] || { echo "target must be a *.app path, got '$APP'" >&2; exit 1; }
BREW=$(brew --prefix)
RES="$APP/Contents/Resources"
FW="$APP/Contents/Frameworks"

command -v dylibbundler >/dev/null || brew install dylibbundler
ZATHURA_BIN="$(brew --prefix zathura)/bin/zathura"
[[ -x $ZATHURA_BIN ]] || { echo "zathura not installed: brew install zathura" >&2; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$RES/plugins" "$FW"
cp "$ZATHURA_BIN" "$APP/Contents/MacOS/zathura-bin"

### plugins ####################################################################
EXTS=""
add_plugin() { # $1 = plugin name, $2 = extensions it handles
  local p="$(brew --prefix "zathura-$1" 2>/dev/null || true)/lib$1.dylib"
  [[ -f $p ]] || return 0
  cp "$p" "$RES/plugins/"
  EXTS="$EXTS $2"
  echo "  + zathura-$1"
}
add_plugin cb "cbr cbz cbt cba cb7"
add_plugin djvu "djvu djv"
add_plugin pdf-mupdf "pdf mobi epub oxps"
add_plugin pdf-poppler "pdf"
add_plugin ps "ps eps"
[[ -n $EXTS ]] || { echo "no zathura-* plugin installed" >&2; exit 1; }

### gdk-pixbuf loaders (image + svg icon rendering) ############################
LOADERDIR="$RES/lib/gdk-pixbuf-2.0/2.10.0/loaders"
mkdir -p "$LOADERDIR"
ORIG_LOADERS=()
for keg in gdk-pixbuf librsvg; do
  d="$(brew --prefix "$keg" 2>/dev/null || true)/lib/gdk-pixbuf-2.0/2.10.0/loaders"
  [[ -d $d ]] || continue
  cp "$d"/*.so "$LOADERDIR/"
  ORIG_LOADERS+=("$d"/*.so)
done

### copy + relink every dependency #############################################
XARGS=()
for f in "$APP/Contents/MacOS/zathura-bin" "$RES/plugins"/*.dylib "$LOADERDIR"/*.so; do
  XARGS+=(-x "$f")
done
dylibbundler -b -of -cd -d "$FW" -p "@executable_path/../Frameworks" \
  -s "$BREW/lib" "${XARGS[@]}" >/dev/null

# dylibbundler can append an rpath a library already has; dyld rejects duplicates
while read -r f; do
  otool -l "$f" | awk '/LC_RPATH/{getline;getline;print $2}' | sort | uniq -d |
    while read -r rp; do install_name_tool -delete_rpath "$rp" "$f" 2>/dev/null || true; done
done < <(find "$APP" \( -name '*.dylib' -o -name '*.so' \))

# loaders.cache: query the original (loadable) modules, then point at the bundle
"$(brew --prefix gdk-pixbuf)/bin/gdk-pixbuf-query-loaders" "${ORIG_LOADERS[@]}" |
  sed -E 's|"[^"]*/loaders/([^"]+)"|"@LOADERDIR@/\1"|' \
    >"$RES/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"

### runtime data ###############################################################
mkdir -p "$RES/share/glib-2.0/schemas" "$RES/share/icons" "$RES/share/misc" "$RES/etc"
cp "$BREW/share/glib-2.0/schemas/gschemas.compiled" "$RES/share/glib-2.0/schemas/"
cp -RL "$BREW/etc/fonts" "$RES/etc/fonts"
cp "$(brew --prefix libmagic)/share/misc/magic.mgc" "$RES/share/misc/"
for theme in Adwaita hicolor; do
  [[ -d "$BREW/share/icons/$theme" ]] && cp -RL "$BREW/share/icons/$theme" "$RES/share/icons/"
done

### launcher ###################################################################
cat >"$APP/Contents/MacOS/zathura" <<'EOF'
#!/bin/bash
here=$(cd "$(dirname "$0")/.." && pwd)
res="$here/Resources"
export XDG_DATA_DIRS="$res/share"
export GSETTINGS_SCHEMA_DIR="$res/share/glib-2.0/schemas"
export FONTCONFIG_PATH="$res/etc/fonts"
export MAGIC="$res/share/misc/magic.mgc"
# loaders.cache needs absolute paths; materialise it outside the signed bundle
src="$res/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
cache="$HOME/Library/Caches/org.pwmt.zathura.loaders.cache"
[[ $src -nt $cache ]] && sed "s|@LOADERDIR@|$res/lib/gdk-pixbuf-2.0/2.10.0/loaders|g" "$src" >"$cache"
export GDK_PIXBUF_MODULE_FILE="$cache"
exec "$here/MacOS/zathura-bin" "$@"
EOF
chmod +x "$APP/Contents/MacOS/zathura"

### Info.plist #################################################################
VER=$("$ZATHURA_BIN" --version | head -n1 | cut -d' ' -f2)
EXTS_XML=$(echo "$EXTS" | xargs -n1 | sort -u | sed 's|.*|                <string>&</string>|')
cat >"$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Zathura</string>
    <key>CFBundleDisplayName</key>
    <string>Zathura</string>
    <key>CFBundleIdentifier</key>
    <string>com.pwmt.zathura</string>
    <key>CFBundleVersion</key>
    <string>${VER}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VER}</string>
    <key>CFBundleExecutable</key>
    <string>zathura</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright (c) 2009-$(date +%Y), pwmt.org</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
${EXTS_XML}
            </array>
            <key>CFBundleTypeIconFile</key>
            <string>AppIcon</string>
            <key>CFBundleTypeName</key>
            <string>Documents</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
EOF

### icon #######################################################################
ICON_SRC="$(dirname "${BASH_SOURCE[0]:-.}")/zathura-brosasaki.icns"
if [[ -f $ICON_SRC ]]; then
  cp "$ICON_SRC" "$RES/AppIcon.icns"
else
  curl -fsSL -o "$RES/AppIcon.icns" \
    https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/refs/heads/master/zathura-brosasaki.icns
fi

### ad-hoc sign (install_name_tool invalidates signatures on arm64) ############
find "$APP" \( -name '*.dylib' -o -name '*.so' \) -exec codesign -f -s - {} + 2>/dev/null
codesign -f -s - "$APP/Contents/MacOS/zathura-bin" 2>/dev/null
codesign -f -s - "$APP" 2>/dev/null
codesign --verify "$APP"

echo
echo "Built $APP ($(du -sh "$APP" | cut -f1)), self-contained."
echo "Every brew package used to build it can now be removed:"
echo "  brew uninstall --force --ignore-dependencies zathura zathura-pdf-mupdf girara gtk+3"
echo "Optional CLI: ln -sf '$APP/Contents/MacOS/zathura' /usr/local/bin/zathura"
