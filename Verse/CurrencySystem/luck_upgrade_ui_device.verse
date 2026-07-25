using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Bouton qui ouvre une interface d'amélioration de chance (niveau actuel +
# coût du prochain niveau + bouton), au lieu d'améliorer directement
# (contrairement à luck_upgrade_device).
#
# Câblage : Button Device + ce script, assigne Button et Catalog.
luck_upgrade_ui_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    var OpenUI : [player]canvas = map{}
    var LevelTexts : [player]text_block = map{}

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Player := player[Agent]):
            OpenUpgradeUI(Player)

    OpenUpgradeUI(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            LevelText := text_block{DefaultText := DynamicText(BuildLevelText(Player))}
            UpgradeButton := button_loud{DefaultText := DynamicText("Améliorer")}
            CloseButton := button_quiet{DefaultText := DynamicText("Fermer")}

            RootCanvas := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := text_block{DefaultText := DynamicText("Chance")}
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.30}, Maximum := vector2{X := 0.65, Y := 0.38}}
                    canvas_slot:
                        Widget := LevelText
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.40}, Maximum := vector2{X := 0.65, Y := 0.46}}
                    canvas_slot:
                        Widget := UpgradeButton
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.48}, Maximum := vector2{X := 0.65, Y := 0.56}}
                    canvas_slot:
                        Widget := CloseButton
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.58}, Maximum := vector2{X := 0.65, Y := 0.66}}

            PlayerUI.AddWidget(RootCanvas, player_ui_slot{InputMode := ui_input_mode.All})
            if (set OpenUI[Player] = RootCanvas):
                true
            if (set LevelTexts[Player] = LevelText):
                true

            UpgradeButton.OnClick().Subscribe(OnUpgradeClicked)
            CloseButton.OnClick().Subscribe(OnCloseClicked)

    BuildLevelText(Player : player) : string =
        Level := Catalog.GetLuckLevel(Player)
        Cost := Catalog.GetNextUpgradeCost(Player)
        "Niveau {Level} - prochain niveau : {Cost}$"

    OnUpgradeClicked(WParam : widget_message) : void =
        Player := WParam.Player
        Upgraded : logic = Catalog.TryUpgradeLuck(Player)
        if (Upgraded?):
            if (Text := LevelTexts[Player]):
                Text.SetText(DynamicText(BuildLevelText(Player)))

    OnCloseClicked(WParam : widget_message) : void =
        Player := WParam.Player
        if (PlayerUI := GetPlayerUI[Player]):
            if (RootCanvas := OpenUI[Player]):
                PlayerUI.RemoveWidget(RootCanvas)
