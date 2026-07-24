using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }

card_rarity := enum:
    Common
    Rare
    Epic
    Legendary
    Mythic

card_definition := struct<concrete>:
    CardId : string = ""
    DisplayName : string = ""
    Rarity : card_rarity = card_rarity.Common
    # Argent généré par seconde tant que le joueur possède un exemplaire de cette carte.
    IncomeRate : int = 0

# Table de toutes les cartes du jeu + tirage aléatoire pondéré par rareté.
# Une seule instance sur la map. Remplis "Cards" dans les propriétés du
# device (éditeur UEFN) avec tes propres cartes brainrot.
#
# Exemples fournis pour montrer le format attendu :
#   skibidi_common  / Common    / 1 $/s
#   sigma_rare      / Rare      / 3 $/s
#   rizz_epic       / Epic      / 8 $/s
#   gyatt_legendary / Legendary / 20 $/s
#   ohio_mythic     / Mythic    / 50 $/s
card_catalog := class(creative_device):

    @editable
    Cards : []card_definition = array:
        card_definition{CardId := "skibidi_common", DisplayName := "Skibidi Toilet", Rarity := card_rarity.Common, IncomeRate := 1}
        card_definition{CardId := "sigma_rare", DisplayName := "Sigma Grindset", Rarity := card_rarity.Rare, IncomeRate := 3}
        card_definition{CardId := "rizz_epic", DisplayName := "Unspeakable Rizz", Rarity := card_rarity.Epic, IncomeRate := 8}
        card_definition{CardId := "gyatt_legendary", DisplayName := "Gyatt Supreme", Rarity := card_rarity.Legendary, IncomeRate := 20}
        card_definition{CardId := "ohio_mythic", DisplayName := "Only in Ohio", Rarity := card_rarity.Mythic, IncomeRate := 50}

    # Poids de base de chaque rareté (plus le nombre est grand, plus c'est fréquent).
    @editable
    CommonWeight : int = 60

    @editable
    RareWeight : int = 25

    @editable
    EpicWeight : int = 10

    @editable
    LegendaryWeight : int = 4

    @editable
    MythicWeight : int = 1

    # Poids ajouté aux raretés non-Common par niveau de chance du joueur.
    @editable
    LuckWeightPerLevel : int = 3

    RollRarity(BonusWeight : int) : card_rarity =
        CommonW := CommonWeight
        RareW := RareWeight + BonusWeight
        EpicW := EpicWeight + BonusWeight
        LegendaryW := LegendaryWeight + BonusWeight
        MythicW := MythicWeight + BonusWeight
        Roll := GetRandomInt(0, CommonW + RareW + EpicW + LegendaryW + MythicW - 1)
        if (Roll < CommonW):
            card_rarity.Common
        else if (Roll < CommonW + RareW):
            card_rarity.Rare
        else if (Roll < CommonW + RareW + EpicW):
            card_rarity.Epic
        else if (Roll < CommonW + RareW + EpicW + LegendaryW):
            card_rarity.Legendary
        else:
            card_rarity.Mythic

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
