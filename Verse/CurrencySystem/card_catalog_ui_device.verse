using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

# Bouton qui ouvre une interface listant les cartes possédées par le
# joueur (nom, quantité, revenu généré).
#
# Câblage : Button Device + ce script, assigne Button, Catalog, CardCatalog.
card_catalog_ui_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    @editable
    CardCatalog : card_catalog = card_catalog{}

    var OpenUI : [player]canvas = map{}

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Player := player[Agent]):
            OpenCatalogUI(Player)

    OpenCatalogUI(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            OwnedCards := Catalog.GetOwnedCards(Player)

            CardLines := for (CardId -> Count : OwnedCards):
                Card := CardCatalog.FindCard(CardId)
                stack_box_slot:
                    Widget := text_block{DefaultText := "{Card.DisplayName} x{Count} (+{Card.IncomeRate * Count}$/s)"}

            CloseButton := button{DefaultText := "Fermer"}

            ListBox := stack_box:
                Slots := CardLines

            RootCanvas := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := text_block{DefaultText := "Ma collection"}
                        Anchors := anchors{Minimum := vector2{X := 0.3, Y := 0.15}, Maximum := vector2{X := 0.7, Y := 0.22}}
                    canvas_slot:
                        Widget := ListBox
                        Anchors := anchors{Minimum := vector2{X := 0.3, Y := 0.24}, Maximum := vector2{X := 0.7, Y := 0.75}}
                    canvas_slot:
                        Widget := CloseButton
                        Anchors := anchors{Minimum := vector2{X := 0.3, Y := 0.78}, Maximum := vector2{X := 0.7, Y := 0.85}}

            PlayerUI.AddWidget(RootCanvas)
            if (set OpenUI[Player] = RootCanvas):
                true

            CloseButton.OnClick().Subscribe(OnCloseClicked)

    OnCloseClicked(Agent : agent) : void =
        if (Player := player[Agent]):
            if (PlayerUI := GetPlayerUI[Player]):
                if (RootCanvas := OpenUI[Player]):
                    PlayerUI.RemoveWidget(RootCanvas)
