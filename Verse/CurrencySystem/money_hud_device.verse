using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Affiche en permanence le solde et l'argent en attente de chaque joueur
# en haut à gauche de l'écran.
#
# Câblage : device vide + ce script, assigne Manager et Catalog.
money_hud_device := class(creative_device):

    @editable
    Manager : currency_manager = currency_manager{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    var BalanceTexts : [player]text_block = map{}
    var PendingTexts : [player]text_block = map{}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        Manager.BalanceChanged.Subscribe(OnBalanceChanged)
        spawn{ RefreshPendingLoop() }

    OnPlayerAdded(Agent : agent) : void =
        if (Player := player[Agent]):
            BuildHud(Player)

    BuildHud(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            BalanceText := text_block{DefaultText := DynamicText("{Manager.GetBalance(Player)}$")}
            PendingText := text_block{DefaultText := DynamicText("")}

            RootCanvas := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := BalanceText
                        Anchors := anchors{Minimum := vector2{X := 0.02, Y := 0.02}, Maximum := vector2{X := 0.3, Y := 0.08}}
                    canvas_slot:
                        Widget := PendingText
                        Anchors := anchors{Minimum := vector2{X := 0.02, Y := 0.08}, Maximum := vector2{X := 0.3, Y := 0.13}}

            PlayerUI.AddWidget(RootCanvas)
            if (set BalanceTexts[Player] = BalanceText):
                true
            if (set PendingTexts[Player] = PendingText):
                true

    OnBalanceChanged(Player : player) : void =
        if (Text := BalanceTexts[Player]):
            Text.SetText(DynamicText("{Manager.GetBalance(Player)}$"))

    RefreshPendingLoop()<suspends> : void =
        loop:
            Sleep(1.0)
            for (Player -> Text : PendingTexts):
                Pending := Catalog.GetPendingCash(Player)
                Text.SetText(DynamicText("+{Pending}$ en attente"))
