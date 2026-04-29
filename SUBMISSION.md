# Soumission App Store — MonPetitRéseau

Tous les éléments à coller dans App Store Connect lors de la soumission.

## URLs (à fournir dans App Store Connect)

- **Site marketing / promo** : https://boboul-cloud.github.io/MonPetitReseau/promo.html
- **Politique de confidentialité** : https://boboul-cloud.github.io/MonPetitReseau/privacy.html
- **Support** : https://boboul-cloud.github.io/MonPetitReseau/support.html

## Identifiants

- **Bundle ID** : `bob.oulhen-gmail.com.MonPetitReseau`
- **Version** : 1.0
- **Build** : 1
- **Catégorie principale** : Réseaux sociaux (Social Networking)
- **Catégorie secondaire** : Style de vie (Lifestyle)
- **Plateforme** : iPhone + iPad (Universal)
- **iOS minimum** : iOS 17

## Tarification

- **Prix** : Gratuit
- **In-App Purchase** : aucun
- **Pub** : aucune

## App Privacy (questionnaire Apple)

| Catégorie | Réponse |
|---|---|
| Data collected | **None** |
| Tracking | **No** |

L'app ne collecte rien côté éditeur. Les données utilisateur (membres, messages, photos) sont stockées localement et synchronisées via le **CloudKit privé** de l'utilisateur (compte iCloud personnel) — ce n'est pas considéré comme une collecte côté éditeur.

## Description (FR)

```
MonPetitRéseau, c'est le petit réseau privé de votre famille.

Un annuaire, un mur pour discuter, des photos, un calendrier d'événements et des
listes de tâches partagées — tout ce qu'il faut pour rester proche de vos
proches, en restant complètement privé.

PAS DE COMPTE, PAS DE SERVEUR, PAS DE PISTAGE
• Aucun compte à créer.
• Aucun mot de passe à retenir.
• Aucune donnée envoyée à un serveur tiers.
• Aucune publicité, aucun abonnement.

UN LIEN MAGIQUE POUR PARTAGER
• Vous créez votre famille en quelques secondes.
• Vous générez un lien et l'envoyez par SMS ou iMessage à vos proches.
• Ils l'ouvrent et rejoignent instantanément votre réseau.

CINQ ESPACES POUR VOTRE FAMILLE
• Annuaire : tous les membres, leurs anniversaires, leurs liens familiaux.
• Mur : une timeline commune où chacun peut écrire.
• Photos : galerie partagée des souvenirs.
• Événements : déjeuners, vacances, anniversaires automatiques.
• Tâches : courses et démarches à se partager.

VIE PRIVÉE PAR CONCEPTION
• Vos données vivent sur votre iPhone.
• La synchronisation entre les iPhones de la famille passe par votre propre iCloud.
• Le créateur du groupe maîtrise qui peut gérer la liste des membres.
• Pas d'analyse, pas de tracker, pas de télémétrie.

POUR QUI ?
Pour toutes les familles qui veulent rester en contact sans passer par les
réseaux sociaux publics, sans laisser de traces ailleurs que sur leurs propres
appareils. Parfait pour les grands-parents, les parents éloignés, les fratries.

Fait avec ❤️ en France.
```

## Description (EN)

```
MonPetitRéseau is the private little network of your family.

A directory, a wall to chat, photos, an event calendar and shared task lists —
everything you need to stay close to your loved ones, while staying completely
private.

NO ACCOUNT, NO SERVER, NO TRACKING
• No account to create.
• No password to remember.
• No data sent to any third-party server.
• No ads, no subscription.

A MAGIC LINK TO SHARE
• Create your family in seconds.
• Generate a link and send it to your relatives by SMS or iMessage.
• They tap it and instantly join your network.

FIVE SPACES FOR YOUR FAMILY
• Directory: all members, their birthdays, family ties.
• Wall: a common timeline where everyone posts.
• Photos: shared memory gallery.
• Events: lunches, holidays, automatic birthdays.
• Tasks: errands and to-dos to share.

PRIVACY BY DESIGN
• Your data lives on your iPhone.
• Sync between family iPhones uses your own iCloud.
• The group creator controls who manages the member list.
• No analytics, no tracker, no telemetry.

FOR WHOM?
For families who want to stay in touch without going through public social
networks, without leaving traces anywhere but on their own devices. Perfect
for grandparents, distant relatives, siblings.

Made with ❤️ in France.
```

## Promotional text (170 caractères max — modifiable sans relivraison)

**FR** : Le petit réseau privé de votre famille. Annuaire, mur, photos, événements, tâches. Sans compte, sans serveur, sans pistage. Un lien suffit pour partager.

**EN** : Your family's private little network. Directory, wall, photos, events, tasks. No account, no server, no tracking. One link is enough to share.

## Keywords (100 caractères max, virgules)

**FR** : famille,réseau,privé,annuaire,partage,iCloud,proches,sans compte,messagerie,événement

**EN** : family,private,network,sharing,relatives,iCloud,no account,wall,photos,events,tasks

## What's New (FR)

```
Première version. Restez proches sans passer par les réseaux sociaux publics.
```

## What's New (EN)

```
Initial release. Stay close to your loved ones without going through public social networks.
```

## Notes pour la review (App Review Information)

```
This app is a private family network. There is no login system because there is
no server: data is shared between family iPhones via the user's own iCloud (CloudKit
private database). To test:

1. Launch the app, fill in your family name and your first member card.
2. The "Family" tab shows the directory. Add a few members.
3. Use the "Wall" tab to post a message — it is stored locally, then synced via
   the user's own iCloud to other family iPhones.
4. Use Settings → Share my family to generate a share link (SMS-friendly URL).

No demo account is needed. The app is fully usable in standalone mode.

Notification permissions: requested only if the user opts in (used for new wall
messages). Photo library permission: requested only when adding a photo.
```

## Coordonnées (Apple Review)

- **Nom** : Robert Oulhen
- **E-mail** : bob.oulhen@gmail.com
- **Téléphone** : (à compléter)

## Captures d'écran requises

- **iPhone 6.9"** (15 / 16 Pro Max) : 3 minimum, 10 max — 1290 × 2796
- **iPhone 6.5"** (legacy, optionnel) : 1242 × 2688
- **iPad 13"** : 2064 × 2752 ou 2048 × 2732

Suggestion de scénarios :
1. L'annuaire avec quelques membres et un anniversaire à venir.
2. Le mur avec quelques messages.
3. La galerie photos.
4. L'écran d'événements.
5. L'écran de partage avec un QR / lien.

## Checklist avant Submit

- [ ] Build 1.0 archivé et uploadé via Xcode (Product → Archive)
- [ ] Captures d'écran ajoutées (iPhone + iPad)
- [ ] Description FR + EN
- [ ] Politique de confidentialité publiée et accessible
- [ ] URL de support publiée et accessible
- [ ] Questionnaire App Privacy rempli (no data collected)
- [ ] Build sélectionné dans la version 1.0
- [ ] Notes de review remplies
- [ ] Soumis à la review
