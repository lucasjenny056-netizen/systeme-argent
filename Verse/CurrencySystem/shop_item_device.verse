using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# A associer à un "Button Device" (bouton d'interaction) placé sur la map :
# le joueur interagit dessus, l'argent est déduit s'il en a assez, et
# l'évènement OnPurchased est déclenché en cas de succès.
#
# Câblage dans l'éditeur UEFN :
#   1. Place un Button Device (ex: sur un présentoir/PNJ/porte).
#   2. Crée un device vide, attache ce script Verse dessus.
#   3. Assigne "Button" au Button Device et "Manager" au currency_manager.
#   4. Règle "Cost" au prix de l'objet.
#   5. Pour donner une récompense (arme, accès, prop...), abonne-toi à
#      OnPurchased depuis un autre script Verse qui référence ce device,
#      ou étends OnInteracted ci-dessous directement.
shop_item_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Manager : currency_manager = currency_manager{}

    @editable
    Cost : int = 50

    # Diffusé uniquement si l'achat a réussi (fonds suffisants).
    OnPurchased<public> : event(player) = event(player){}

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(MaybeAgent : ?agent) : void =
        if (Agent := MaybeAgent?, Player := player[Agent]):
            if (Manager.TrySpend(Player, Cost)):
                OnPurchased.Signal(Player)
