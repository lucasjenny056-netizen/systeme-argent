using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Plaque au sol : le joueur marche dessus pour récupérer l'argent généré
# passivement par sa collection de cartes.
#
# Câblage : Trigger Device (zone au sol) + ce script, avec Catalog assigné.
collection_plate_device := class(creative_device):

    @editable
    Trigger : trigger_device = trigger_device{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    OnBegin<override>()<suspends> : void =
        Trigger.TriggeredEvent.Subscribe(OnTriggered)

    OnTriggered(Agent : agent) : void =
        if (Player := player[Agent]):
            Catalog.CollectPending(Player)
