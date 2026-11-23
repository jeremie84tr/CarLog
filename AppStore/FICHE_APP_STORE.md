# Fiche App Store Connect : prête à copier-coller

> **À vérifier avant de soumettre**
> 1. **Bundle ID.** Actuellement `lohyer.carlog` (équipe `XK27PY3L36`).
> 2. **Site d'aide.** Activer GitHub Pages : Settings › Pages › *Deploy from a branch* › `main` / `/docs`. Dépôt public requis. Pousser d'abord le dépôt (`origin` est configuré).
> 3. **Icône.** `Logo.png` est maintenant 1024×1024 sans transparence (fait).
> 4. **CloudKit** (conteneur `iCloud.lohyer.carlog`, déjà déclaré dans le code et les entitlements). À faire par vous :
>    - Xcode › *Signing & Capabilities* › iCloud › cocher CloudKit et le conteneur `iCloud.lohyer.carlog` (Xcode le crée sur votre compte), + *Push Notifications* et *Background Modes › Remote notifications*.
>    - Lancer l'app une fois en Debug sur un appareil connecté à iCloud, créer quelques entrées : cela crée le schéma en *Development*.
>    - [CloudKit Dashboard](https://icloud.developer.apple.com) › conteneur › *Deploy Schema Changes to Production*. Sans cela, la synchro échoue en production (TestFlight/App Store).
> 5. **Chiffrement.** `ITSAppUsesNonExemptEncryption = NO` est ajouté dans `Info.plist` (fait).
> 6. Version minimale actuelle : iOS 18.5 (réduire si vous voulez toucher plus d'appareils).

## Informations sur l'app

**Nom** (30 max)
```
CarLog : suivi auto
```
**Sous-titre** (30 max)
```
Pleins, conso et réparations
```
**Catégorie principale :** Style de vie (ou Productivité) · **Secondaire :** Utilitaires
**Droits d'auteur**
```
2026 Jérémie Lohyer
```

## Version 1.0

**Texte promotionnel** (170 max)
```
Notez vos pleins et réparations en quelques secondes, suivez votre consommation réelle et gardez un œil sur ce que coûte vraiment votre voiture.
```
**Description**
```
CarLog est le carnet de bord de votre voiture : pleins de carburant, réparations, pièces et kilométrage au même endroit.

PLEINS ET CONSOMMATION
• Prix total, litres, prix au litre calculé automatiquement.
• Consommation en L/100 km calculée de plein à plein, pleins partiels inclus.

RÉPARATIONS
• Forfait et pièces détaillées, total calculé pour vous.

STATISTIQUES
• Résumé des dépenses et graphiques de consommation et de prix.

SYNCHRONISATION ICLOUD
Vos données se synchronisent entre vos appareils via votre compte iCloud.

EXPORT
Exportez tout en CSV (ZIP) ou JSON, à tout moment.

VIE PRIVÉE
Aucun compte, aucune publicité, aucune collecte de données par le développeur.
```
**Mots-clés** (100 max)
```
voiture,auto,carburant,plein,consommation,essence,diesel,entretien,réparation,garage,kilométrage,dépenses
```
**URL d'assistance / marketing**
```
https://jeremie84tr.github.io/CarLog/
```
**Nouveautés**
```
Première version : pleins, consommation, réparations, statistiques, synchronisation iCloud et export.
```

## Confidentialité
**URL de la politique**
```
https://jeremie84tr.github.io/CarLog/confidentialite.html
```
**Collecte de données :** « Non, nous ne collectons pas de données » (les données restent sur l'appareil et dans l'iCloud privé de l'utilisateur ; ni serveur, ni analytique, ni SDK tiers).

## Classification par âge
Répondre **Aucun / Non** partout. Résultat attendu : **4+**.

## App Review
**Connexion requise :** non.
**Remarques**
```
CarLog est un carnet de suivi des dépenses d'une voiture (pleins, réparations). Aucun compte, achat ni jeu d'argent. La synchronisation utilise l'iCloud privé de l'utilisateur (CloudKit). Pour tester : touchez « + », choisissez « Plein », saisissez kilométrage, prix et litres ; répétez avec un second plein complet pour voir la consommation.
```

## Envoi du build
1. `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` (une fois).
2. Xcode : *Signing & Capabilities* › équipe ; incrémenter `CURRENT_PROJECT_VERSION` à chaque envoi.
3. *Product › Archive* (« Any iOS Device ») › *Distribute App › App Store Connect*. (`aps-environment` passe en production automatiquement à la distribution.)
4. Captures : voir ci-dessous.

## Visuels

| Emplacement App Store Connect | Fichiers | Taille |
|---|---|---|
| iPhone 6,9 pouces | `captures/iphone-6.9/*.png` | 1320 × 2868 |
| iPhone 6,3 pouces | `captures/iphone-6.3/*.png` | 1206 × 2622 |
| iPhone 6,1 pouces | `captures/iphone-6.1/*.png` | 1179 × 2556 |
| iPad 13 pouces | `captures/ipad-13/*.png` | 2064 × 2752 |
| Ressource d'en-tête | `promo/entete-3840x1646.png` | 3840 × 1646 |
| Ressource de résultats de recherche | `promo/recherche-3840x2560.png` | 3840 × 2560 |

Régénérer (Xcode requis, depuis la racine du dépôt) :
`AppStore/outils/captures.sh` → `AppStore/outils/composer.sh` → `AppStore/outils/verifier.sh`.
Les captures utilisent le mode DEBUG `-donneesExemple 1 -ecran liste|statistiques|plein|reparation` (`CarLog/CaptureSupport.swift`) : données fictives en mémoire, sans iCloud.
