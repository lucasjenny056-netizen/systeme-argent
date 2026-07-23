using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# A associer à un "Trigger Device" (zone de déclenchement) placé sur la map :
# quand un joueur entre dedans, il reçoit de l'argent.
#
# Câblage dans l'éditeur UEFN :
#   1. Place un Trigger Device à l'endroit voulu (ex: sur un billet/pièce au sol).
#   2. Crée un device vide, attache ce script Verse dessus.
#   3. Dans les propriétés du script, assigne "Trigger" au Trigger Device,
#      et "Manager" au currency_manager de la map.
money_pickup_device := class(creative_device):

    @editable
    Trigger : trigger_device = trigger_device{}

    @editable
    Manager : currency_manager = currency_manager{}

    # Montant donné à chaque déclenchement.
    @editable
    Amount : int = 10

    # Si activé, chaque joueur ne peut collecter cette source d'argent qu'une seule fois.
    @editable
    OneTimeOnly : logic = false

    var AlreadyCollected : [player]logic = map{}

    OnBegin<override>()<suspends> : void =
        Trigger.TriggeredEvent.Subscribe(OnTriggered)

    OnTriggered(MaybeAgent : ?agent) : void =
        if (Agent := MaybeAgent?, Player := player[Agent]):
            GrantMoney(Player)

    HasCollected(Player : player) : logic =
        if (Collected := AlreadyCollected[Player]) then Collected else false

    GrantMoney(Player : player) : void =
        if (OneTimeOnly?):
            if (not HasCollected(Player)):
                if (set AlreadyCollected[Player] = true):
                    Manager.AddMoney(Player, Amount)
        else:
            if (set AlreadyCollected[Player] = true):
                Manager.AddMoney(Player, Amount)
