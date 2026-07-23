# Système d'argent + collection de cartes (Verse / UEFN)

Système complet type "brainrot collector" : argent, packs à ouvrir, cartes à
rareté, revenu passif à récupérer, amélioration de chance.

## Fichiers

| Fichier | Rôle | Instances sur la map |
|---|---|---|
| `currency_manager.verse` | Solde d'argent de chaque joueur (500$ au départ). Ajout/dépense/lecture. | 1 seule |
| `card_catalog.verse` | Table de toutes les cartes (rareté + revenu/s) et tirage aléatoire pondéré. | 1 seule |
| `player_catalog_manager.verse` | Packs possédés, cartes collectées, argent en attente, niveau de chance. | 1 seule |
| `pack_shop_device.verse` | Bouton pour acheter un pack (déduit l'argent, ajoute le pack à l'inventaire). | autant que voulu |
| `pack_slot_device.verse` | Emplacement où poser un pack ; il s'ouvre après un délai et donne une carte. | autant que voulu |
| `collection_plate_device.verse` | Plaque au sol : récupère l'argent généré passivement par la collection. | autant que voulu |
| `luck_upgrade_device.verse` | Bouton pour dépenser de l'argent et améliorer ses chances de rareté. | autant que voulu |

## Comment ça s'enchaîne

1. Le joueur rejoint la partie → 500$ (réglable via `StartingBalance` sur
   `currency_manager`).
2. Il achète un pack sur `pack_shop_device` → argent déduit, +1 pack dans son
   inventaire (`player_catalog_manager`).
3. Il va sur un `pack_slot_device` et interagit → le pack est consommé, un
   minuteur démarre (`OpenDelaySeconds`), puis une carte est tirée au sort
   selon les poids de rareté (+ bonus lié à son niveau de chance) et ajoutée
   à sa collection.
4. Chaque carte possédée génère de l'argent par seconde (`IncomeRate`,
   défini par carte dans `card_catalog`), qui s'accumule "en attente".
5. Le joueur marche sur un `collection_plate_device` → l'argent en attente
   est transféré sur son solde réel (`currency_manager`).
6. Il peut dépenser son solde sur `luck_upgrade_device` pour augmenter son
   niveau de chance (coût croissant, plafonné par `MaxLuckLevel`), ce qui
   améliore ses futurs tirages de packs.

## Limite importante : "poser le pack où on veut"

Un vrai objet d'inventaire qu'on ramasse et qu'on pose n'importe où au sol
demande des assets UEFN (Item Definition + système de placement) en plus du
Verse, ce qui sort du cadre d'un simple script. Ici, le pack acheté est
compté dans un inventaire virtuel (`PackCount`), et il s'ouvre sur des
emplacements fixes (`pack_slot_device`) que tu places toi-même sur la map.
Place-en plusieurs pour permettre l'ouverture simultanée par plusieurs
joueurs. Si tu veux vraiment un objet physique déplaçable, dis-le moi, on
peut regarder une approche avec un Prop Spawner + Item Granted Device.

## Installation dans ton projet UEFN

1. Copie tout le dossier `CurrencySystem` dans `Content` de ton projet UEFN,
   **en gardant tous les fichiers `.verse` dans le même dossier**. En Verse,
   des fichiers dans des dossiers différents sont dans des modules
   différents et ne se voient pas sans `using` explicite — si tu vois une
   erreur "Unknown identifier `currency_manager`" (ou un autre type défini
   ici), c'est presque toujours parce qu'un fichier a été déplacé/recréé
   ailleurs. Ne renomme pas non plus les fichiers un par un depuis
   l'éditeur UEFN (ça peut les faire atterrir dans des dossiers séparés) :
   copie-colle le dossier entier tel quel.
2. Laisse Verse compiler, puis dans l'éditeur de niveau :
   - Un device vide → `currency_manager`.
   - Un device vide → `card_catalog` (remplis/édite la liste `Cards`,
     5 exemples brainrot fournis par défaut).
   - Un device vide → `player_catalog_manager`, assigne `Manager` et
     `CardCatalog`.
   - Un `Button Device` + device vide `pack_shop_device` → assigne
     `Button`, `Manager`, `Catalog`, règle `PackCost`.
   - Un `Button Device` (+ un Creative Prop optionnel) + device vide
     `pack_slot_device` → assigne `Button`, `PackProp`, `Catalog`,
     `CardCatalog`, règle `OpenDelaySeconds`. Répète pour plusieurs
     emplacements.
   - Un `Trigger Device` + device vide `collection_plate_device` → assigne
     `Trigger`, `Catalog`.
   - Un `Button Device` + device vide `luck_upgrade_device` → assigne
     `Button`, `Catalog`.
3. Compile (Verse > Build Verse Code) et teste en session.

## Idées pour continuer

- Afficher solde / argent en attente / niveau de chance à l'écran via un
  `hud_message_device` abonné à `Manager.BalanceChanged`.
- Classement des collections les plus riches.
- Sauvegarder l'argent et la collection entre les sessions (persistance
  Verse — dis-moi ta version d'UEFN et je l'ajoute).
