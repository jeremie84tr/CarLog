#!/bin/sh
# Habille les captures brutes (titre + fond) aux tailles exactes de l'App Store, et génère les visuels promo.
# Usage : AppStore/outils/composer.sh      (après captures.sh)
set -e
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
T="${TMPDIR:-/tmp}/carlog-composer"; mkdir -p "$T"
BIN="$T/composer"; PROMO="$T/promo"
swiftc -O outils/composer.swift -o "$BIN"
swiftc -O outils/promo.swift -o "$PROMO"
mkdir -p captures/iphone-6.9 captures/iphone-6.3 captures/iphone-6.1 captures/ipad-13 promo

legende() { # nom → « titre|sous-titre »
    case "$1" in
        01-liste)       echo "Tous vos frais auto au même endroit|Pleins et réparations, du plus récent au plus ancien" ;;
        02-statistiques) echo "Suivez votre consommation|Kilométrage, prix du carburant et L/100 km" ;;
        03-plein)       echo "Un plein en quelques secondes|Prix, litres et prix au litre calculé" ;;
        04-reparation)  echo "Réparations et pièces détaillées|Forfait, pièces et total automatique" ;;
    esac
}

habiller() { # $1 dossier brut, $2 dossier final, $3 largeur, $4 hauteur, $5 mode
    for f in captures/brutes/$1/*.png; do
        nom=$(basename "$f" .png)
        l=$(legende "$nom")
        "$BIN" "$f" "captures/$2/$nom.png" "$3" "$4" "${l%%|*}" "${l#*|}" $5
        echo "  $2/$nom.png"
    done
}

habiller iphone iphone-6.9 1320 2868 iphone
habiller iphone iphone-6.3 1206 2622 iphone
habiller iphone iphone-6.1 1179 2556 iphone
habiller ipad ipad-13 2064 2752 ipad

B=captures/brutes/iphone
"$BIN" $B/01-liste.png promo/banniere-1920x1080.png 1920 1080 \
    "CarLog : suivi auto" "Pleins, consommation et réparations, sur iPhone et iPad" banniere
"$PROMO" promo/entete-3840x1646.png 3840 1646 \
    "$B/04-reparation.png:0.78:0.14:0.55" "$B/03-plein.png:0.78:0.86:0.55" \
    "$B/02-statistiques.png:0.88:0.62:0.52" "$B/01-liste.png:0.88:0.38:0.52"
"$PROMO" promo/recherche-3840x2560.png 3840 2560 \
    "$B/01-liste.png:0.74:0.25:0.53" "$B/02-statistiques.png:0.74:0.75:0.53" "$B/03-plein.png:0.86:0.50:0.50"
cp ../CarLog/Assets.xcassets/AppIcon.appiconset/Logo.png promo/icone-1024.png
echo "  promo/"
