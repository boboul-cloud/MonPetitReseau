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

## Réponse au rejet Guideline 2.1 — VERSION COURTE (à coller)

Version compacte qui rentre dans la limite de caractères de la Resolution Center.

```
Hello, thank you for the review. Replies to the 6 points:

1) SCREEN RECORDING: attached (MonPetitReseau-demo.mp4), captured on a
physical iPhone. It shows: app launch, onboarding (family + first member),
Directory (add member), Wall (post message), Photos (with iOS photo
permission prompt), Events (add event), Tasks (add task), Settings →
Share my family (link + QR), notifications permission prompt.

2) PURPOSE: a private little social network for ONE family. Lets
relatives share a directory, a wall, photos, events and to-dos without
public social networks and without creating an account on a third-party
server. Audience: families, especially with grandparents or distant
relatives, who want a low-friction private space.

3) HOW TO ACCESS: no demo account is needed — the app has NO login,
because it has NO server backend. Steps:
  a) Launch the app, fill family name + your name, tap Create.
  b) Directory tab → "+" to add members.
  c) Wall tab → "+" to post a message.
  d) Photos tab → "+" to add a photo (iOS asks for photo permission).
  e) Events tab → "+" to add an event.
  f) Todos tab → "+" to add a task.
  g) Settings → "Share my family" generates a link + QR (SMS-friendly).
     Opening the link on another iPhone with the app joins the same
     family. Opening it in a browser shows a read-only web companion.

4) EXTERNAL SERVICES:
  - Apple CloudKit, private database of the user's own iCloud account,
    to sync family data between the user's devices and family members'
    devices. No third-party server, no public CloudKit container.
  - Apple Push Notification service (APNs) for optional new-message
    notifications.
  - GitHub Pages hosts only static pages (privacy / support / promo /
    read-only web companion). No backend, no data collection.
  - No analytics, no tracker, no ad SDK, no payment processor, no AI
    service, no third-party authentication. Only Apple frameworks at
    runtime.

5) REGIONAL DIFFERENCES: none. Same features everywhere. Only the UI
language adapts (full FR + EN localization, follows device language).

6) REGULATED INDUSTRY: not applicable (no health, finance, gambling,
crypto, government). No license required.

App Privacy: "No data collected" — user content stays on the device
and in the user's own iCloud private database.

Thank you.
```

---

## Réponse au rejet Guideline 2.1 — version longue (référence)

Version détaillée originale, à garder en référence pour les Notes du champ App Review Information lors des prochaines soumissions.

```
Hello, thank you for the review. Please find below the requested information.

1) SCREEN RECORDING
A screen recording captured on a physical iPhone is attached to this reply
(file: MonPetitReseau-demo.mp4). It starts with launching the app from the
home screen and goes through the typical user flow:
  - First launch: create the family and the first member card.
  - Directory tab: add a couple of members and view birthdays.
  - Wall tab: post a message.
  - Photos tab: add a photo (the system permission prompt for the photo
    library is shown and accepted).
  - Events tab: create an event.
  - Tasks tab: add a task.
  - Settings → Share my family: generate the share link (SMS-friendly URL)
    and show the QR code.
  - Open the link on a second iPhone to demonstrate joining the family.
  - Settings → notifications: the system permission prompt is shown.
The recording shows no login screen because the app does not have any
account system (see point 3).

2) APP PURPOSE
MonPetitRéseau is a private little social network for one family.
Problem it solves: families (especially with grandparents, distant
relatives or siblings) want to share news, photos, events and to-dos
without using public social networks (Facebook, Instagram, WhatsApp groups)
and without creating yet another account on a third-party server.
Value provided: a single, ad-free, account-free, server-free space that
lives on the family members' iPhones and syncs through their own iCloud.
Target audience: families that want a private, low-friction way to stay
in touch.

3) HOW TO ACCESS AND REVIEW THE MAIN FEATURES
No demo account or credentials are needed. The app has NO login system
because it has NO server backend.

Step-by-step:
  a) Launch the app. On first launch you are asked for the family name
     and your own first/last name. Fill them in and tap "Create".
  b) The "Directory" tab opens. Tap "+" to add a few family members
     (name, optional birthday, optional family tie). Each member is
     stored locally and synced via the reviewer's iCloud account.
  c) Open the "Wall" tab and tap "+" to post a short message.
  d) Open the "Photos" tab and tap "+" to add a photo from the library
     (iOS will ask for photo library permission — this is expected).
  e) Open the "Events" tab and add an event (e.g. a lunch next Sunday).
     Birthdays added in the directory automatically appear here.
  f) Open the "Todos" tab and add a shared task.
  g) Open "Settings" → "Share my family". The app generates a link
     (https://boboul-cloud.github.io/MonPetitReseau/?data=...) and a QR
     code. The link can be sent by SMS / iMessage. Opening the link on
     another iPhone with MonPetitRéseau installed adds that device to
     the same family. If the link is opened in a browser, a read-only
     web companion is shown.
  h) The creator of the family is the only member who can manage the
     member list (add / remove other members). Other members get a
     read-only banner on the directory.

4) EXTERNAL SERVICES, TOOLS OR PLATFORMS USED
  - Apple CloudKit (private database of the user's own iCloud account)
    is used to sync the family data between the user's own iPhones and
    between iPhones of family members who have joined via the share link.
    No third-party server is involved. The app uses only the user's own
    iCloud private database — there is no public CloudKit container,
    no shared CloudKit zone managed by us.
  - Apple Push Notification service (APNs) for the optional new-message
    notifications, via the standard NotificationService extension.
  - GitHub Pages hosts the static web companion / privacy / support /
    promo pages (https://boboul-cloud.github.io/MonPetitReseau/). The
    web companion is a single static HTML file that decodes the share
    link client-side. It does not collect anything and does not call
    any backend.
  - No analytics SDK, no tracker, no advertising SDK, no payment
    processor, no AI service, no third-party authentication, no data
    broker. The app does not embed any third-party code at runtime
    other than Apple's frameworks.

5) REGIONAL DIFFERENCES
The app behaves identically in all regions. The only regional
adaptation is the user interface language: the app is fully localized
in French and English and follows the device language. There is no
geo-restricted feature, no geo-restricted content, and no feature that
depends on the user's country, carrier or region.

6) HIGHLY REGULATED INDUSTRY
The app does not operate in a regulated industry (no health, no
finance, no gambling, no government, no crypto, no medical advice).
No special license or credential is required.

Additional notes:
  - The app does not collect any data on our side (App Privacy
    questionnaire = "No data collected"). User content is stored
    locally on the device and synced to the user's own iCloud private
    database.
  - Permission prompts: photo library (only when adding a photo),
    notifications (only if the user enables wall notifications in
    settings). Each Info.plist purpose string explains the use.

Thank you for the additional review.
```

### Pense-bête pour l'enregistrement vidéo

À filmer sur **iPhone physique** (pas le simulateur) avec l'enregistreur d'écran iOS :

1. Écran d'accueil → tape sur l'icône MonPetitRéseau (montre bien le lancement).
2. Onboarding : nom de famille + prénom/nom + Créer.
3. Annuaire : ajoute 2 membres avec anniversaire.
4. Mur : poste un message.
5. Photos : ajoute une photo → **laisse bien apparaître la pop-up de permission Photos** et accepte.
6. Événements : ajoute un événement.
7. Tâches : ajoute une tâche.
8. Réglages → Partager ma famille : montre le QR + le lien.
9. (Si possible) Ouvre le lien sur un 2ᵉ iPhone et montre l'arrivée du nouveau membre.
10. Réglages → active les notifications → **laisse apparaître la pop-up système** et accepte.

Garde la vidéo entre **30 s et 2 min**, format portrait, son désactivé OK. Upload `.mp4` ou `.mov` en pièce jointe dans la réponse au Resolution Center.

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
