using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Gestionnaire de la collection de cartes de chaque joueur : packs en
# inventaire, cartes possédées, argent généré passivement (à récupérer sur
# une plaque), et niveau de "chance" (améliore les tirages de packs).
#
# Une seule instance sur la map, référencée par pack_shop_device,
# pack_slot_device, collection_plate_device et luck_upgrade_device.
player_catalog_manager := class(creative_device):

    @editable
    Manager : currency_manager = currency_manager{}

    @editable
    CardCatalog : card_catalog = card_catalog{}

    # Coût de base pour passer au niveau de chance suivant (multiplié par le niveau visé).
    @editable
    LuckUpgradeBaseCost : int = 100

    @editable
    MaxLuckLevel : int = 10

    # Nombre de packs non ouverts possédés par chaque joueur.
    var PackCount : [player]int = map{}

    # Cartes possédées : nombre d'exemplaires par CardId.
    var Catalog : [player][string]int = map{}

    # Argent généré passivement, en attente d'être récupéré sur la plaque.
    var PendingCash : [player]int = map{}

    # Niveau de chance de chaque joueur.
    var LuckLevel : [player]int = map{}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        spawn{ IncomeLoop() }

    OnPlayerAdded(Agent : agent) : void =
        if (Player := player[Agent]):
            if (set PackCount[Player] = 0, set Catalog[Player] = map{}, set PendingCash[Player] = 0, set LuckLevel[Player] = 0):
                true

    # Distribue l'argent passif toutes les secondes selon les cartes possédées par chacun.
    IncomeLoop()<suspends> : void =
        loop:
            Sleep(1.0)
            for (Player -> PlayerCards : Catalog):
                Rate := GetIncomeRate(Player)
                if (Rate > 0):
                    Current := if (Pending := PendingCash[Player]) then Pending else 0
                    if (set PendingCash[Player] = Current + Rate):
                        true

    # Somme des revenus/seconde de toutes les cartes possédées par le joueur.
    GetIncomeRate<public>(Player : player) : int =
        if (Cards := Catalog[Player]):
            var Total : int = 0
            for (CardId -> Count : Cards):
                Card := CardCatalog.FindCard(CardId)
                set Total += Card.IncomeRate * Count
            Total
        else:
            0

    GetPendingCash<public>(Player : player) : int =
        if (Pending := PendingCash[Player]) then Pending else 0

    GetPackCount<public>(Player : player) : int =
        if (Count := PackCount[Player]) then Count else 0

    GetLuckLevel<public>(Player : player) : int =
        if (Level := LuckLevel[Player]) then Level else 0

    GetNextUpgradeCost<public>(Player : player) : int =
        LuckUpgradeBaseCost * (GetLuckLevel(Player) + 1)

    GetOwnedCards<public>(Player : player) : [string]int =
        if (Cards := Catalog[Player]) then Cards else map{}

    # Ajoute Count pack(s) non ouverts à l'inventaire du joueur (achat réussi).
    GrantPack<public>(Player : player, Count : int) : void =
        if (Count > 0):
            Current := GetPackCount(Player)
            if (set PackCount[Player] = Current + Count):
                true

    # Consomme un pack si le joueur en possède au moins un. Renvoie true si consommé.
    TryConsumePack<public>(Player : player) : logic =
        Current := GetPackCount(Player)
        if (Current > 0):
            if (set PackCount[Player] = Current - 1):
                true
            else:
                false
        else:
            false

    # Ajoute une carte à la collection du joueur (appelé quand un pack s'ouvre).
    AddCard<public>(Player : player, CardId : string) : void =
        ExistingCards := if (Cards := Catalog[Player]) then Cards else map{}
        CurrentCount := if (Count := ExistingCards[CardId]) then Count else 0
        var UpdatedCards : [string]int = ExistingCards
        if (set UpdatedCards[CardId] = CurrentCount + 1):
            if (set Catalog[Player] = UpdatedCards):
                true

    # Transfère l'argent en attente vers le solde principal du joueur.
    CollectPending<public>(Player : player) : void =
        Pending := GetPendingCash(Player)
        if (Pending > 0):
            if (set PendingCash[Player] = 0):
                Manager.AddMoney(Player, Pending)

    # Dépense de l'argent pour augmenter le niveau de chance du joueur.
    TryUpgradeLuck<public>(Player : player) : logic =
        CurrentLevel := GetLuckLevel(Player)
        if (CurrentLevel < MaxLuckLevel):
            Cost := LuckUpgradeBaseCost * (CurrentLevel + 1)
            Spent : logic = Manager.TrySpend(Player, Cost)
            if (Spent?):
                if (set LuckLevel[Player] = CurrentLevel + 1):
                    true
                else:
                    false
            else:
                false
        else:
            false
