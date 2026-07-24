using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }

# Du plus fréquent au plus rare.
card_rarity := enum:
    Common
    Uncommon
    Rare
    Epic
    Legendary
    Mythic
    Secret
    Divine
    Exotic
    Admin

card_definition := struct<concrete>:
    CardId : string = ""
    DisplayName : string = ""
    Rarity : card_rarity = card_rarity.Common
    # Argent généré par seconde tant que le joueur possède un exemplaire de cette carte.
    IncomeRate : int = 0

# Paire rareté/poids utilisée en interne par le tirage aléatoire pondéré.
rarity_weight := struct<concrete>:
    Rarity : card_rarity = card_rarity.Common
    Weight : int = 0

# Table de toutes les cartes du jeu + tirage aléatoire pondéré par rareté.
# Une seule instance sur la map. Remplis "Cards" dans les propriétés du
# device (éditeur UEFN) avec tes propres cartes brainrot.
#
# Exemples fournis pour montrer le format attendu (un par rareté) :
#   skibidi_common   / Common    / 1 $/s
#   sigma_uncommon   / Uncommon  / 2 $/s
#   gyatt_rare       / Rare      / 4 $/s
#   rizz_epic        / Epic      / 8 $/s
#   gyatt_legendary  / Legendary / 20 $/s
#   ohio_mythic      / Mythic    / 50 $/s
#   fanum_secret     / Secret    / 120 $/s
#   livvy_divine     / Divine    / 300 $/s
#   sussy_exotic     / Exotic    / 750 $/s
#   owner_admin      / Admin     / 2000 $/s
card_catalog := class(creative_device):

    @editable
    Cards : []card_definition = array:
        card_definition{CardId := "skibidi_common", DisplayName := "Skibidi Toilet", Rarity := card_rarity.Common, IncomeRate := 1}
        card_definition{CardId := "sigma_uncommon", DisplayName := "Sigma Grindset", Rarity := card_rarity.Uncommon, IncomeRate := 2}
        card_definition{CardId := "gyatt_rare", DisplayName := "Gyatt Rizzler", Rarity := card_rarity.Rare, IncomeRate := 4}
        card_definition{CardId := "rizz_epic", DisplayName := "Unspeakable Rizz", Rarity := card_rarity.Epic, IncomeRate := 8}
        card_definition{CardId := "gyatt_legendary", DisplayName := "Gyatt Supreme", Rarity := card_rarity.Legendary, IncomeRate := 20}
        card_definition{CardId := "ohio_mythic", DisplayName := "Only in Ohio", Rarity := card_rarity.Mythic, IncomeRate := 50}
        card_definition{CardId := "fanum_secret", DisplayName := "Fanum Tax Collector", Rarity := card_rarity.Secret, IncomeRate := 120}
        card_definition{CardId := "livvy_divine", DisplayName := "Certified Divine", Rarity := card_rarity.Divine, IncomeRate := 300}
        card_definition{CardId := "sussy_exotic", DisplayName := "Sussy Baka Imposter", Rarity := card_rarity.Exotic, IncomeRate := 750}
        card_definition{CardId := "owner_admin", DisplayName := "Server Owner", Rarity := card_rarity.Admin, IncomeRate := 2000}

    # Poids de base de chaque rareté (plus le nombre est grand, plus c'est fréquent).
    @editable
    CommonWeight : int = 10000

    @editable
    UncommonWeight : int = 5000

    @editable
    RareWeight : int = 2000

    @editable
    EpicWeight : int = 800

    @editable
    LegendaryWeight : int = 300

    @editable
    MythicWeight : int = 100

    @editable
    SecretWeight : int = 30

    @editable
    DivineWeight : int = 8

    @editable
    ExoticWeight : int = 2

    # À 0 par défaut : personne ne peut tirer une carte Admin via les packs.
    # Monte ce nombre si tu veux qu'elle soit obtenable normalement.
    @editable
    AdminWeight : int = 0

    # Poids ajouté aux raretés non-Common par niveau de chance du joueur.
    @editable
    LuckWeightPerLevel : int = 3

    RollRarity(BonusWeight : int) : card_rarity =
        Tiers : []rarity_weight = array:
            rarity_weight{Rarity := card_rarity.Common, Weight := CommonWeight}
            rarity_weight{Rarity := card_rarity.Uncommon, Weight := UncommonWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Rare, Weight := RareWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Epic, Weight := EpicWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Legendary, Weight := LegendaryWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Mythic, Weight := MythicWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Secret, Weight := SecretWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Divine, Weight := DivineWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Exotic, Weight := ExoticWeight + BonusWeight}
            rarity_weight{Rarity := card_rarity.Admin, Weight := AdminWeight + BonusWeight}

        var TotalWeight : int = 0
        for (Tier : Tiers):
            set TotalWeight += Tier.Weight

        Roll := GetRandomInt(0, TotalWeight - 1)

        var CumulativeWeight : int = 0
        var Result : card_rarity = card_rarity.Common
        for (Tier : Tiers):
            NewCumulative := CumulativeWeight + Tier.Weight
            if (Roll >= CumulativeWeight, Roll < NewCumulative):
                set Result = Tier.Rarity
            set CumulativeWeight = NewCumulative

        Result

    # Tire une carte au hasard en tenant compte de la rareté, du niveau de
    # chance du joueur ET du bonus propre au type de pack ouvert (un pack
    # plus cher passe un PackBonusWeight plus élevé -> meilleures chances).
    # Renvoie une carte "vide" (CardId := "") si "Cards" n'a aucune entrée.
    RollCard<public>(LuckLevel : int, PackBonusWeight : int) : card_definition =
        if (Cards.Length = 0):
            card_definition{}
        else:
            BonusWeight := LuckLevel * LuckWeightPerLevel + PackBonusWeight
            WantedRarity := RollRarity(BonusWeight)
            Matches := for (Card : Cards, Card.Rarity = WantedRarity):
                Card
            FinalPool := if (Matches.Length > 0) then Matches else Cards
            Index := GetRandomInt(0, FinalPool.Length - 1)
            if (Chosen := FinalPool[Index]) then Chosen else card_definition{}

    # Recherche une carte par son identifiant. Renvoie une carte "vide" (CardId := "") si non trouvée.
    FindCard<public>(CardId : string) : card_definition =
        Matches := for (Card : Cards, Card.CardId = CardId):
            Card
        if (Found := Matches[0]) then Found else card_definition{}
