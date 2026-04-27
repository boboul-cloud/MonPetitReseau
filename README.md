# MonPetitRéseau

Réseau familial privé pour iPhone — sans serveur, sans compte, sans pistage.

## Concept

Une petite app iOS pour rester en contact avec votre famille :

- 👥 **Annuaire** : tous les membres avec liens parentaux et anniversaires
- 💬 **Mur** : timeline de discussion familiale
- 📷 **Photos** : galerie de souvenirs partagés
- 📅 **Événements** : calendrier des retrouvailles
- ✅ **Tâches** : courses et choses à faire en famille

Le partage entre proches passe par un **lien magique** envoyé par SMS — pas de serveur, pas de compte.

## Stack

- **iOS** : SwiftUI, Swift 6, `@Observable`, MainActor
- **Web companion** : PWA single HTML (lecture + composition de message), CSP stricte, dépendances locales
- **Codec d'URL** : JSON → zlib raw deflate → base64url (compatible Swift `Compression` ↔ JS `pako.deflateRaw`)

## Sécurité & vie privée

- Aucun serveur, aucun compte, aucun analytics
- Données persistées localement (UserDefaults sur iPhone, URL sur web)
- Web : CSP stricte, `frame-ancestors 'none'`, `noindex/nofollow`, no-referrer
- Toutes les sorties HTML sont échappées (anti-XSS)
- Pako auto-hébergé (pas de CDN tiers au runtime)
- Le lien de partage **donne accès à la famille** : ne le partagez qu'à des personnes de confiance

## Structure

```
MonPetitReseau/         # app iOS (SwiftUI)
web/                    # companion web (PWA, déployable sur GitHub Pages)
```

## Companion web

Déployé sur GitHub Pages depuis le dossier `web/`. Le code source iOS reste **privé**.

## Licence

Privé / personnel.
