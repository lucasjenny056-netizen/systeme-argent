using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Emplacement où un joueur pose un pack pour l'ouvrir. Le pack met un
# certain temps à s'ouvrir, puis une carte est ajoutée automatiquement à
# la collection du joueur.
#
# TierId doit correspondre au TierId du pack_shop_device/pack_shop_ui_device
# qui vend ce pack : ce slot ne consomme et n'ouvre que des packs de ce
# type-là.
#
# Chaque instance de ce device définit SA PROPRE table de probabilités
# (les 9 champs XxxWeight ci-dessous, un par rareté). Règle-les pour qu'ils
# totalisent 10000 : un poids = un pourcentage x100 (ex: 50 = 0.5%, 200 = 2%).
# LuckWeightPerLevel ajoute un petit bonus (aux raretés non-Common) par
# niveau de chance du joueur, en plus de la table du pack.
#
# Règle : un pack ne peut JAMAIS donner une carte de rareté supérieure à son
# propre nom (poids à 0 au-dessus), mais peut donner toutes les raretés en
# dessous. Table complète (poids sur 10000, colonnes = packs, du moins cher
# au plus cher) :
#
#              Commun  Rare   Épique Légend. Elite  Mythique Secret Divin  Exotic
#   Common      7000      0      0      0      0        0       0      0      0
#   Rare        2000   6500      0      0      0        0       0      0      0
#   Epic         800   2500   6000      0      0        0       0      0      0
#   Legendary    200    800   2500   6000      0        0       0      0      0
#   Elite          0    200   1000   2500   6000        0       0      0      0
#   Mythic         0      0    500   1000   2500     6000    7000      0      0
#   Secret         0      0      0    500   1000     2500    2000   7000      0
#   Divine         0      0      0      0    500     1000     800   2500   7500
#   Exotic         0      0      0      0      0      500     200    500   2500
#   TierId    "common" "rare" "epic" "legendary" "elite" "mythic" "secret" "divine" "exotic"
#   Prix       300$  1500$ 10000$  50000$  250000$   1M$    20M$   400M$   10B$
#   (1M = 1 000 000 / 1Md = 1 000M / 1B = 1Md / 1T = 1 000Md / 1Qa = 1 000T)
#
# Limite : un emplacement UEFN est un point fixe sur la map (pas une vraie
# position libre choisie par le joueur, ce qui demanderait un système
# d'objets d'inventaire plaçables bien plus complexe). Place plusieurs
# pack_slot_device (un par TierId) si tu veux plusieurs types de packs et/ou
# que plusieurs joueurs puissent ouvrir en même temps.
#
# Câblage : Button Device (interaction "Ouvrir le pack") + optionnellement
# un Creative Prop pour représenter visuellement le pack qui s'ouvre.
pack_slot_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    @editable
    CardCatalog : card_catalog = card_catalog{}

    @editable
    TierId<public> : string = "common"

    @editable
    CommonWeight : int = 7000

    @editable
    RareWeight : int = 2000

    @editable
    EpicWeight : int = 800

    @editable
    LegendaryWeight : int = 200

    @editable
    EliteWeight : int = 0

    @editable
    MythicWeight : int = 0

    @editable
    SecretWeight : int = 0

    @editable
    DivineWeight : int = 0

    @editable
    ExoticWeight : int = 0

    # Bonus ajouté aux raretés non-Common par niveau de chance du joueur.
    @editable
    LuckWeightPerLevel : int = 5

    # Prop optionnel affiché pendant l'ouverture.
    @editable
    PackProp : creative_prop = creative_prop{}

    @editable
    OpenDelaySeconds : float = 5.0

    var Occupied : logic = false

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Occupied?):
            true
        else:
            if (Player := player[Agent]):
                Consumed : logic = Catalog.TryConsumePack(Player, TierId)
                if (Consumed?):
                    spawn{ OpenPack(Player) }

    # Table de probabilités du pack SANS le bonus de chance du joueur (sert
    # uniquement à l'affichage, ex: dans un catalogue listant tous les packs).
    GetBaseWeights<public>() : []rarity_weight =
        array:
            rarity_weight{Rarity := card_rarity.Common, Weight := CommonWeight}
            rarity_weight{Rarity := card_rarity.Rare, Weight := RareWeight}
            rarity_weight{Rarity := card_rarity.Epic, Weight := EpicWeight}
            rarity_weight{Rarity := card_rarity.Legendary, Weight := LegendaryWeight}
            rarity_weight{Rarity := card_rarity.Elite, Weight := EliteWeight}
            rarity_weight{Rarity := card_rarity.Mythic, Weight := MythicWeight}
            rarity_weight{Rarity := card_rarity.Secret, Weight := SecretWeight}
            rarity_weight{Rarity := card_rarity.Divine, Weight := DivineWeight}
            rarity_weight{Rarity := card_rarity.Exotic, Weight := ExoticWeight}

    BuildWeights(Player : player) : []rarity_weight =
        LuckBonus := Catalog.GetLuckLevel(Player) * LuckWeightPerLevel
        array:
            rarity_weight{Rarity := card_rarity.Common, Weight := CommonWeight}
            rarity_weight{Rarity := card_rarity.Rare, Weight := RareWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Epic, Weight := EpicWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Legendary, Weight := LegendaryWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Elite, Weight := EliteWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Mythic, Weight := MythicWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Secret, Weight := SecretWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Divine, Weight := DivineWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Exotic, Weight := ExoticWeight + LuckBonus}

    OpenPack(Player : player)<suspends> : void =
        set Occupied = true
        PackProp.Show()
        Sleep(OpenDelaySeconds)
        PackProp.Hide()
        set Occupied = false
        Weights := BuildWeights(Player)
        Card : card_definition = CardCatalog.RollCard(Weights)
        Catalog.AddCard(Player, Card.CardId)
