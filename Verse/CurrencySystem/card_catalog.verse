using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }

# Du plus fréquent au plus rare. 9 raretés, une par palier de pack.
card_rarity := enum:
    Common
    Rare
    Epic
    Legendary
    Elite
    Mythic
    Secret
    Divine
    Exotic

card_definition := struct<concrete>:
    CardId : string = ""
    DisplayName : string = ""
    Rarity : card_rarity = card_rarity.Common
    # Argent généré par seconde tant que le joueur possède un exemplaire de cette carte.
    IncomeRate : int = 0

# Paire rareté/poids : une table complète de 9 (une par rareté) est fournie
# par CHAQUE pack_slot_device (voir ce fichier), pas par card_catalog. Ça
# permet à chaque type de pack d'avoir ses propres chances exactes.
rarity_weight := struct<concrete>:
    Rarity : card_rarity = card_rarity.Common
    Weight : int = 0

# Table de toutes les cartes du jeu (indépendante des probabilités de pack).
# Une seule instance sur la map. Remplis "Cards" dans les propriétés du
# device (éditeur UEFN) avec tes propres cartes brainrot.
#
# Exemples fournis pour montrer le format attendu (un par rareté) :
#   skibidi_common   / Common    / 1 $/s
#   gyatt_rare       / Rare      / 4 $/s
#   rizz_epic        / Epic      / 8 $/s
#   gyatt_legendary  / Legendary / 20 $/s
#   sigma_elite      / Elite     / 40 $/s
#   ohio_mythic      / Mythic    / 80 $/s
#   fanum_secret     / Secret    / 150 $/s
#   livvy_divine     / Divine    / 350 $/s
#   sussy_exotic     / Exotic    / 800 $/s
card_catalog := class(creative_device):

    @editable
    Cards : []card_definition = array:
        card_definition{CardId := "skibidi_common", DisplayName := "Skibidi Toilet", Rarity := card_rarity.Common, IncomeRate := 1}
        card_definition{CardId := "gyatt_rare", DisplayName := "Gyatt Rizzler", Rarity := card_rarity.Rare, IncomeRate := 4}
        card_definition{CardId := "banana_monkey", DisplayName := "Banana Monkey", Rarity := card_rarity.Rare, IncomeRate := 5}
        card_definition{CardId := "rizz_epic", DisplayName := "Unspeakable Rizz", Rarity := card_rarity.Epic, IncomeRate := 8}
        card_definition{CardId := "gyatt_legendary", DisplayName := "Gyatt Supreme", Rarity := card_rarity.Legendary, IncomeRate := 20}
        card_definition{CardId := "sigma_elite", DisplayName := "Sigma Elite", Rarity := card_rarity.Elite, IncomeRate := 40}
        card_definition{CardId := "ohio_mythic", DisplayName := "Only in Ohio", Rarity := card_rarity.Mythic, IncomeRate := 80}
        card_definition{CardId := "fanum_secret", DisplayName := "Fanum Tax Collector", Rarity := card_rarity.Secret, IncomeRate := 150}
        card_definition{CardId := "livvy_divine", DisplayName := "Certified Divine", Rarity := card_rarity.Divine, IncomeRate := 350}
        card_definition{CardId := "sussy_exotic", DisplayName := "Sussy Baka Imposter", Rarity := card_rarity.Exotic, IncomeRate := 800}

    # Renvoie toutes les cartes du jeu (utilisé par le catalogue façon "pokédex" :
    # il affiche aussi les cartes non encore obtenues, en "???").
    GetAllCards<public>() : []card_definition =
        Cards

    RollRarity(Weights : []rarity_weight) : card_rarity =
        var TotalWeight : int = 0
        for (Tier : Weights):
            set TotalWeight += Tier.Weight

        Roll := GetRandomInt(0, TotalWeight - 1)

        var CumulativeWeight : int = 0
        var Result : card_rarity = card_rarity.Common
        for (Tier : Weights):
            NewCumulative := CumulativeWeight + Tier.Weight
            if (Roll >= CumulativeWeight, Roll < NewCumulative):
                set Result = Tier.Rarity
            set CumulativeWeight = NewCumulative

        Result

    # Tire une carte au hasard selon la table de poids fournie par l'appelant
    # (voir pack_slot_device.BuildWeights). Renvoie une carte "vide"
    # (CardId := "") si "Cards" n'a aucune entrée.
    RollCard<public>(Weights : []rarity_weight) : card_definition =
        if (Cards.Length = 0):
            card_definition{}
        else:
            WantedRarity := RollRarity(Weights)
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
