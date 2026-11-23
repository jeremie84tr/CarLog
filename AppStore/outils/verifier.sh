#!/bin/sh
# Contrôle les visuels App Store : dimensions exactes, pas de canal alpha, nombre de fichiers, pas de capture vide.
# Usage : AppStore/outils/verifier.sh      (code de sortie ≠ 0 au premier problème détecté)
cd "$(dirname "$0")/.."
erreurs=0
echo_ko() { echo "  ✗ $1"; erreurs=$((erreurs + 1)); }

controle() { # $1 fichier, $2 largeur, $3 hauteur, $4 alpha attendu (no|yes)
    [ -f "$1" ] || { echo_ko "$1 : absent"; return; }
    w=$(sips -g pixelWidth "$1" | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$1" | awk '/pixelHeight/{print $2}')
    al=$(sips -g hasAlpha "$1" | awk '/hasAlpha/{print $2}')
    [ "$w" = "$2" ] && [ "$h" = "$3" ] || echo_ko "$1 : ${w}×${h} au lieu de ${2}×${3}"
    [ "$al" = "$4" ] || echo_ko "$1 : hasAlpha=$al (attendu $4)"
    # une capture quasi uniforme (écran noir/blanc) pèse très peu
    [ "$(wc -c < "$1")" -gt 30000 ] || echo_ko "$1 : fichier suspect (< 30 Ko), capture vide ?"
}

dossier() { # $1 dossier, $2 largeur, $3 hauteur, $4 nombre attendu, $5 alpha
    n=$(ls "$1"/*.png 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -eq "$4" ] || echo_ko "$1 : $n fichier(s) au lieu de $4"
    for f in "$1"/*.png; do [ -f "$f" ] && controle "$f" "$2" "$3" "$5"; done
}

echo "Captures brutes"
dossier captures/brutes/iphone 1320 2868 4 yes
dossier captures/brutes/ipad 2064 2752 4 yes
echo "Captures habillées"
dossier captures/iphone-6.9 1320 2868 4 no
dossier captures/iphone-6.3 1206 2622 4 no
dossier captures/iphone-6.1 1179 2556 4 no
dossier captures/ipad-13 2064 2752 4 no
echo "Promo"
controle promo/entete-3840x1646.png 3840 1646 no
controle promo/recherche-3840x2560.png 3840 2560 no
controle promo/banniere-1920x1080.png 1920 1080 no

if [ "$erreurs" -eq 0 ]; then echo "OK : tous les visuels sont conformes."; else echo "$erreurs problème(s)."; exit 1; fi
