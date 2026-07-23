# Système d'argent (Verse / UEFN)

Trois scripts Verse pour gérer une monnaie de map (coins, cash, "rizz points"...
renomme comme tu veux, ça reste juste un `int`).

## Fichiers

- `currency_manager.verse` — le cœur du système : solde par joueur, ajout,
  dépense, remise à zéro. **Une seule instance sur la map.**
- `money_pickup_device.verse` — donne de l'argent quand un joueur traverse
  une zone (`trigger_device`). Utile pour des pièces au sol, un coffre, etc.
- `shop_item_device.verse` — déduit de l'argent quand un joueur interagit
  avec un bouton (`button_device`), si le achat réussit ça diffuse un
  évènement `OnPurchased` pour donner la récompense de ton choix.

## Installation dans ton projet UEFN

1. Copie le dossier `CurrencySystem` dans le dossier `Content` de ton projet
   UEFN (n'importe quel sous-dossier convient).
2. Ouvre le projet dans Fortnite Creative / UEFN, laisse Verse compiler.
3. Dans l'éditeur de niveau :
   - Place un device vide, attache `currency_manager`.
   - Place un `Trigger Device` (pièce à ramasser) + un device vide avec
     `money_pickup_device`, et dans ses propriétés assigne `Trigger` et
     `Manager`.
   - Place un `Button Device` (boutique) + un device vide avec
     `shop_item_device`, assigne `Button`, `Manager`, et le `Cost`.
4. Compile (Verse > Build Verse Code) et lance une session de test.

## Idées pour continuer

- Afficher le solde à l'écran : abonne un device custom à
  `Manager.BalanceChanged` et envoie un message via un `hud_message_device`.
- Classement des joueurs les plus riches : itère sur `Balances` dans
  `currency_manager` (à exposer via une méthode publique si besoin).
- Sauvegarder l'argent entre les sessions : possible avec le système de
  persistance de Verse, mais l'API a changé plusieurs fois selon les
  versions d'UEFN — dis-moi la version que tu utilises et je l'ajoute.
