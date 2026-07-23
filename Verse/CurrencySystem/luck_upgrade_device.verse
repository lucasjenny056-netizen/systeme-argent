using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Bouton pour améliorer la "chance" du joueur (meilleures probabilités de
# tirer des cartes rares/épiques/légendaires/mythiques) en dépensant de
# l'argent. Le coût augmente à chaque niveau (voir LuckUpgradeBaseCost sur
# player_catalog_manager).
#
# Câblage : Button Device + ce script, avec Catalog assigné.
luck_upgrade_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Player := player[Agent]):
            Catalog.TryUpgradeLuck(Player)
