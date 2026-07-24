using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Emplacement où un joueur pose un pack pour l'ouvrir. Le pack met un
# certain temps à s'ouvrir, puis une carte est ajoutée automatiquement à
# la collection du joueur.
#
# TierId doit correspondre au TierId du pack_shop_device/pack_shop_ui_device
# qui vend ce pack : ce slot ne consomme et n'ouvre que des packs de ce
# type-là. TierBonusWeight règle les chances de rareté propres à ce type de
# pack (s'ajoute au niveau de chance du joueur) : plus le pack est cher,
# plus tu peux monter ce nombre.
# Exemples suggérés : basic 0, premium 15, legendary 40.
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
    TierBonusWeight : int = 0

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

    OpenPack(Player : player)<suspends> : void =
        set Occupied = true
        PackProp.Show()
        Sleep(OpenDelaySeconds)
        PackProp.Hide()
        set Occupied = false
        Card : card_definition = CardCatalog.RollCard(Catalog.GetLuckLevel(Player), TierBonusWeight)
        Catalog.AddCard(Player, Card.CardId)
