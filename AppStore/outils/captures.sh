#!/bin/sh
# Prend les captures d'écran brutes pour l'App Store (iPhone 6,9", iPad 13").
# Usage : AppStore/outils/captures.sh [iphone] [ipad]   (depuis la racine du dépôt, Xcode requis ; tout par défaut)
# Résultat : AppStore/captures/brutes/{iphone,ipad}/*.png
# L'app est lancée en DEBUG avec -donneesExemple 1 (données fictives en mémoire, voir CaptureSupport.swift).
set -e
CIBLES="${*:-iphone ipad}"
cd "$(dirname "$0")/../.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TRAVAIL="${TMPDIR:-/tmp}/carlog-captures"
BRUT="AppStore/captures/brutes"
DD="$TRAVAIL/dd"
BUNDLE="lohyer.carlog"
mkdir -p "$TRAVAIL" "$BRUT/iphone" "$BRUT/ipad"

# nom | argument -ecran
PLANS="01-liste|liste
02-statistiques|statistiques
03-plein|plein
04-reparation|reparation"

simulateur() { # $1 = nom du modèle, $2 = dossier
    UDID=$(xcrun simctl list devices available | grep -m1 "    $1 (" | grep -oE "[0-9A-F-]{36}")
    [ -n "$UDID" ] || { echo "Simulateur introuvable : $1" >&2; exit 1; }
    xcrun simctl boot "$UDID" 2>/dev/null || true
    xcrun simctl bootstatus "$UDID" >/dev/null
    xcrun simctl ui "$UDID" appearance light
    xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
    xcodebuild -project CarLog.xcodeproj -scheme CarLog -configuration Debug -destination "platform=iOS Simulator,id=$UDID" \
        -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO build -quiet
    xcrun simctl install "$UDID" "$DD/Build/Products/Debug-iphonesimulator/CarLog.app"
    echo "$PLANS" | while IFS='|' read -r nom ecran; do
        xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
        xcrun simctl launch "$UDID" "$BUNDLE" -donneesExemple 1 -ecran "$ecran" >/dev/null
        sleep 6
        xcrun simctl io "$UDID" screenshot "$BRUT/$2/$nom.png" >/dev/null 2>&1
        echo "  $2/$nom.png"
    done
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
}

case " $CIBLES " in *" iphone "*) echo "iPhone 6,9 pouces"; simulateur "iPhone 17 Pro Max" iphone ;; esac
case " $CIBLES " in *" ipad "*) echo "iPad 13 pouces"; simulateur "iPad Pro 13-inch (M4)" ipad ;; esac
