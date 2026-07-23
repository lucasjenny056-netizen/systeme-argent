using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Bouton pour acheter un pack. L'argent est déduit et le pack est ajouté à
# l'inventaire de packs du joueur (à poser ensuite sur un pack_slot_device
# pour l'ouvrir).
#
# Câblage : Button Device + ce script, avec Manager et Catalog assignés.
pack_shop_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Manager : currency_manager = currency_manager{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    @editable
    PackCost : int = 100

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Player := player[Agent]):
            Spent : logic = Manager.TrySpend(Player, PackCost)
            if (Spent?):
                Catalog.GrantPack(Player, 1)
