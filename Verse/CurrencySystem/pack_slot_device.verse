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
# Progression suggérée sur 9 packs, du moins cher au plus cher (TierId entre
# parenthèses). Colonnes = valeurs à copier dans les 9 champs XxxWeight de
# chaque pack_slot_device (elles totalisent toutes 10000) :
#
#                Commun  Rare   Épique  Légend.  Elite  Mythique Secret  Divin  Exotic
#   Common        7000   4000   2000     800      500     200      50      0      0
#   Uncommon      2000   3000   2500    1500     1100     700      200     50      0
#   Rare           800   2000   2500    2200     1850    1500      700    200     50
#   Epic           150    700   1800    2500     2500    2500     1800    700    300
#   Legendary       40    200    800    2000     2250    2500     2500   1800   1200
#   Mythic          10     70    300     700     1250    1800     2500   2500   2300
#   Secret           0     20     70     200      375     550     1700   2500   2600
#   Divine           0      8     20      70      125     180      470   1800   3450
#   Exotic           0      2     10      30       50      70       80    450   100 (1%)
#   TierId       "common" "rare" "epic" "legendary" "elite" "mythic" "secret" "divine" "exotic"
#   Prix suggéré   300$  1500$ 10000$  50000$    250000$    1M$     20M$   400M$   10B$
#   (1M = 1 000 000 / 1Md = 1 000M / 1B = 1Md / 1T = 1 000Md / 1Qa = 1 000T)
#
# "Elite" est un palier intermédiaire entre Legendary et Mythic (l'écart de
# prix entre les deux était trop grand). Rien ne t'empêche d'ajouter encore
# d'autres paliers de la même façon : chaque pack_slot_device est indépendant.
#
# Exotic est la rareté ultime (pas d'Admin). Le pack "exotic" (le plus cher)
# a exactement 1% de chance de donner une carte Exotic ; les autres packs en
# donnent une chance minime en bonus, le reste monte en douceur avant ça.
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
    TierId : string = "common"

    @editable
    CommonWeight : int = 7000

    @editable
    UncommonWeight : int = 2000

    @editable
    RareWeight : int = 800

    @editable
    EpicWeight : int = 150

    @editable
    LegendaryWeight : int = 40

    @editable
    MythicWeight : int = 10

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

    OpenPack(Player : player)<suspends> : void =
        set Occupied = true
        PackProp.Show()
        Sleep(OpenDelaySeconds)
        PackProp.Hide()
        set Occupied = false
        Weights := BuildWeights(Player)
        Card : card_definition = CardCatalog.RollCard(Weights)
        Catalog.AddCard(Player, Card.CardId)
