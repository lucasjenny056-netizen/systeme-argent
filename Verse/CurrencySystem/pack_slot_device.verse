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
# (les 10 champs XxxWeight ci-dessous). Règle-les pour qu'ils totalisent
# 10000 : un poids = un pourcentage x100 (ex: 50 = 0.5%, 200 = 2%).
# LuckWeightPerLevel ajoute un petit bonus (aux raretés non-Common) par
# niveau de chance du joueur, en plus de la table du pack.
#
# Exemple de progression sur 3 packs (à copier dans les propriétés de
# chaque pack_slot_device correspondant, valeurs qui totalisent 10000) :
#
#   Pack "basic" (le moins cher) :
#     Common 6000 / Uncommon 2500 / Rare 1200 / Epic 250 / Legendary 50
#     Mythic 0 / Secret 0 / Divine 0 / Exotic 0 / Admin 0
#     -> 0.5% de Legendary, rien au-dessus.
#
#   Pack "premium" (intermédiaire) :
#     Common 4000 / Uncommon 3000 / Rare 2000 / Epic 700 / Legendary 200
#     Mythic 40 / Secret 10 / Divine 50 / Exotic 0 / Admin 0
#     -> 2% de Legendary, 0.5% de Divine.
#
#   Pack "ultimate" (le plus cher) :
#     Common 1000 / Uncommon 2000 / Rare 2400 / Epic 2000 / Legendary 1200
#     Mythic 700 / Secret 400 / Divine 100 / Exotic 100 / Admin 100
#     -> 1% d'Admin, et tout le reste bien meilleur aussi.
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
    TierId : string = "basic"

    @editable
    CommonWeight : int = 6000

    @editable
    UncommonWeight : int = 2500

    @editable
    RareWeight : int = 1200

    @editable
    EpicWeight : int = 250

    @editable
    LegendaryWeight : int = 50

    @editable
    MythicWeight : int = 0

    @editable
    SecretWeight : int = 0

    @editable
    DivineWeight : int = 0

    @editable
    ExoticWeight : int = 0

    @editable
    AdminWeight : int = 0

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

    BuildWeights(Player : player) : []rarity_weight =
        LuckBonus := Catalog.GetLuckLevel(Player) * LuckWeightPerLevel
        array:
            rarity_weight{Rarity := card_rarity.Common, Weight := CommonWeight}
            rarity_weight{Rarity := card_rarity.Uncommon, Weight := UncommonWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Rare, Weight := RareWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Epic, Weight := EpicWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Legendary, Weight := LegendaryWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Mythic, Weight := MythicWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Secret, Weight := SecretWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Divine, Weight := DivineWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Exotic, Weight := ExoticWeight + LuckBonus}
            rarity_weight{Rarity := card_rarity.Admin, Weight := AdminWeight + LuckBonus}

    OpenPack(Player : player)<suspends> : void =
        set Occupied = true
        PackProp.Show()
        Sleep(OpenDelaySeconds)
        PackProp.Hide()
        set Occupied = false
        Weights := BuildWeights(Player)
        Card : card_definition = CardCatalog.RollCard(Weights)
        Catalog.AddCard(Player, Card.CardId)
