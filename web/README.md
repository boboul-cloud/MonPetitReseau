# MonPetitRéseau — Companion web

Page web compagnon pour l'app iOS **MonPetitRéseau**.

## Concept

Un proche reçoit par SMS un lien du type :

```
https://boboul-cloud.github.io/MonPetitReseau/#d=<token>&me=<uuid>
```

Le `token` est un payload JSON compressé (zlib raw deflate + base64url) qui contient :
- Membres de la famille
- Messages du mur
- Événements à venir
- Tâches partagées

Aucun serveur. Tout vit dans l'URL.

## Fonctionnalités web

- Lecture du réseau familial (annuaire, mur, événements, tâches)
- Verrouillage d'identité par `?me=<uuid>` (qui suis-je ?)
- Composition de message → génère un nouveau lien à renvoyer par SMS
- PWA installable (manifest + service worker)

## Déploiement GitHub Pages

1. Pousser le contenu du dossier `web/` sur la branche `gh-pages` (ou activer Pages sur `/web` dans `main`).
2. URL publique : `https://<user>.github.io/MonPetitReseau/`
3. Mettre à jour `webBase` dans `FamilyStore.swift` si besoin.

## Compatibilité du codec

| iOS Swift                  | Web JS               |
| -------------------------- | -------------------- |
| `compression_encode_buffer` (`COMPRESSION_ZLIB`) | `pako.deflate()` |
| `compression_decode_buffer`                     | `pako.inflate()` |
| base64url (RFC 4648 §5)                         | `base64urlEncode/Decode` |

Les deux côtés utilisent du **raw deflate** (pas de wrapper zlib/gzip).
