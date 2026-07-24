using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

# Bouton qui ouvre une interface d'achat de pack, au lieu d'acheter
# directement (contrairement à pack_shop_device).
#
# Câblage : Button Device (pour ouvrir la boutique) + ce script, assigne
# Button, Manager, Catalog, règle PackCost.
pack_shop_ui_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Manager : currency_manager = currency_manager{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    @editable
    PackCost : int = 100

    var OpenUI : [player]canvas = map{}

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Player := player[Agent]):
            OpenShop(Player)

    OpenShop(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            PriceText := text_block{DefaultText := "Prix : {PackCost}$"}
            BuyButton := button{DefaultText := "Acheter un pack"}
            CloseButton := button{DefaultText := "Fermer"}

            RootCanvas := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := text_block{DefaultText := "Boutique de packs"}
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.30}, Maximum := vector2{X := 0.65, Y := 0.38}}
                    canvas_slot:
                        Widget := PriceText
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.40}, Maximum := vector2{X := 0.65, Y := 0.46}}
                    canvas_slot:
                        Widget := BuyButton
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.48}, Maximum := vector2{X := 0.65, Y := 0.56}}
                    canvas_slot:
                        Widget := CloseButton
                        Anchors := anchors{Minimum := vector2{X := 0.35, Y := 0.58}, Maximum := vector2{X := 0.65, Y := 0.66}}

            PlayerUI.AddWidget(RootCanvas)
            if (set OpenUI[Player] = RootCanvas):
                true

            BuyButton.OnClick().Subscribe(OnBuyClicked)
            CloseButton.OnClick().Subscribe(OnCloseClicked)

    OnBuyClicked(Agent : agent) : void =
        if (Player := player[Agent]):
            Spent : logic = Manager.TrySpend(Player, PackCost)
            if (Spent?):
                Catalog.GrantPack(Player, 1)

    OnCloseClicked(Agent : agent) : void =
        if (Player := player[Agent]):
            CloseShop(Player)

    CloseShop(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            if (RootCanvas := OpenUI[Player]):
                PlayerUI.RemoveWidget(RootCanvas)
