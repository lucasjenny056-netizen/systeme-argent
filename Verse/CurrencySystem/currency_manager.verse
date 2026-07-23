using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Gestionnaire central de la monnaie de la map.
#
# Mets UNE SEULE instance de ce device sur la map (glisse ce script sur un
# device vide dans l'éditeur UEFN), puis référence-le depuis les autres
# devices (ramassage, boutique, etc.) via leurs propriétés @editable.
#
# Ce système est en mémoire uniquement (le solde repart de StartingBalance
# à chaque reconnexion). Si tu veux que l'argent soit sauvegardé entre les
# sessions, dis-le moi, ça demande le système de persistance de Verse en plus.
currency_manager := class(creative_device):

    # Solde de départ donné à chaque joueur qui rejoint la partie.
    @editable
    StartingBalance : int = 0

    # Solde courant de chaque joueur.
    var Balances : [player]int = map{}

    # Diffusé à chaque fois que le solde d'un joueur change (nouveau solde inclus).
    # D'autres devices/scripts peuvent s'y abonner pour mettre à jour un affichage.
    BalanceChanged<public> : event(player, int) = event(player, int){}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)

    OnPlayerAdded(Agent : agent) : void =
        if (Player := player[Agent]):
            set Balances[Player] = StartingBalance
            BalanceChanged.Signal(Player, StartingBalance)

    # Renvoie le solde actuel du joueur (0 s'il n'a pas encore rejoint).
    GetBalance<public>(Player : player) : int =
        if (Balance := Balances[Player]):
            Balance
        else:
            0

    # Ajoute de l'argent (ignore les montants négatifs ou nuls).
    AddMoney<public>(Player : player, Amount : int) : void =
        if (Amount > 0):
            NewBalance := GetBalance(Player) + Amount
            set Balances[Player] = NewBalance
            BalanceChanged.Signal(Player, NewBalance)

    # Tente de dépenser Amount. Renvoie true et déduit la somme si le joueur
    # a les fonds nécessaires, sinon renvoie false et ne touche à rien.
    TrySpend<public>(Player : player, Amount : int) : logic =
        Current := GetBalance(Player)
        if (Amount > 0, Current >= Amount):
            NewBalance := Current - Amount
            set Balances[Player] = NewBalance
            BalanceChanged.Signal(Player, NewBalance)
            true
        else:
            false

    # Force le solde à une valeur précise (utile pour un admin/debug command).
    SetBalance<public>(Player : player, NewBalance : int) : void =
        if (NewBalance >= 0):
            set Balances[Player] = NewBalance
            BalanceChanged.Signal(Player, NewBalance)
