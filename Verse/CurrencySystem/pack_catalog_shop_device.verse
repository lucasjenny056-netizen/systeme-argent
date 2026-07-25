using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Bouton qui ouvre une interface listant TOUS les paliers de packs d'un
# coup : prix + détail des probabilités de chaque rareté + un bouton
# d'achat par palier.
#
# Câblage : Button Device + ce script, assigne Button, Manager, Catalog,
# puis pour chaque palier XxxSlot (référence le pack_slot_device
# correspondant à ce palier, sert à lire ses probabilités réelles) et
# XxxPrice (le prix de vente : doit correspondre au PackCost du
# pack_shop_device/pack_shop_ui_device de ce palier).
#
# Les probabilités affichées viennent directement des champs XxxWeight de
# chaque pack_slot_device référencé (pas de duplication à maintenir à la
# main) : si tu changes les poids d'un pack_slot_device, l'affichage suit.
pack_catalog_shop_device := class(creative_device):

    @editable
    Button : button_device = button_device{}

    @editable
    Manager : currency_manager = currency_manager{}

    @editable
    Catalog : player_catalog_manager = player_catalog_manager{}

    @editable
    CommonSlot : pack_slot_device = pack_slot_device{}

    @editable
    CommonPrice : int = 300

    @editable
    RareSlot : pack_slot_device = pack_slot_device{}

    @editable
    RarePrice : int = 1500

    @editable
    EpicSlot : pack_slot_device = pack_slot_device{}

    @editable
    EpicPrice : int = 10000

    @editable
    LegendarySlot : pack_slot_device = pack_slot_device{}

    @editable
    LegendaryPrice : int = 50000

    @editable
    EliteSlot : pack_slot_device = pack_slot_device{}

    @editable
    ElitePrice : int = 250000

    @editable
    MythicSlot : pack_slot_device = pack_slot_device{}

    @editable
    MythicPrice : int = 1000000

    @editable
    SecretSlot : pack_slot_device = pack_slot_device{}

    @editable
    SecretPrice : int = 20000000

    @editable
    DivineSlot : pack_slot_device = pack_slot_device{}

    @editable
    DivinePrice : int = 400000000

    @editable
    ExoticSlot : pack_slot_device = pack_slot_device{}

    @editable
    ExoticPrice : int = 10000000000

    var OpenUI : [player]canvas = map{}

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Player := player[Agent]):
            OpenCatalog(Player)

    RarityName(Rarity : card_rarity) : string =
        if (Rarity = card_rarity.Common):
            "Common"
        else if (Rarity = card_rarity.Rare):
            "Rare"
        else if (Rarity = card_rarity.Epic):
            "Epic"
        else if (Rarity = card_rarity.Legendary):
            "Legendary"
        else if (Rarity = card_rarity.Elite):
            "Elite"
        else if (Rarity = card_rarity.Mythic):
            "Mythic"
        else if (Rarity = card_rarity.Secret):
            "Secret"
        else if (Rarity = card_rarity.Divine):
            "Divine"
        else:
            "Exotic"

    # Construit une ligne du style "Common 70%  Rare 20%  Epic 8%  Legendary 2%".
    BuildOddsText(Slot : pack_slot_device) : string =
        Weights := Slot.GetBaseWeights()
        var Parts : string = ""
        for (W : Weights):
            if (W.Weight > 0):
                if (Percent := Floor(W.Weight / 100)):
                    set Parts += "{RarityName(W.Rarity)} {Percent}%  "
        Parts

    BuildRowText(Name : string, Price : int, Slot : pack_slot_device) : string =
        "{Name} - {Price}$\n{BuildOddsText(Slot)}"

    BuyPack(Player : player, TierId : string, Price : int) : void =
        Spent : logic = Manager.TrySpend(Player, Price)
        if (Spent?):
            Catalog.GrantPack(Player, TierId, 1)

    # Construit une "carte" verticale compacte : texte (prix + odds) + bouton d'achat.
    BuildCard(Name : string, Price : int, Slot : pack_slot_device, BuyButton : button_loud) : stack_box =
        stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot{Widget := text_block{DefaultText := DynamicText(BuildRowText(Name, Price, Slot))}}
                stack_box_slot{Widget := BuyButton}

    # Assemble 3 cartes côte à côte (une rangée du tableau 3x3).
    BuildRow(CardA : stack_box, CardB : stack_box, CardC : stack_box) : stack_box =
        stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot{Widget := CardA}
                stack_box_slot{Widget := CardB}
                stack_box_slot{Widget := CardC}

    OpenCatalog(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            CloseButton := button_quiet{DefaultText := DynamicText("Fermer")}
            CommonButton := button_loud{DefaultText := DynamicText("Acheter Common")}
            RareButton := button_loud{DefaultText := DynamicText("Acheter Rare")}
            EpicButton := button_loud{DefaultText := DynamicText("Acheter Epic")}
            LegendaryButton := button_loud{DefaultText := DynamicText("Acheter Legendary")}
            EliteButton := button_loud{DefaultText := DynamicText("Acheter Elite")}
            MythicButton := button_loud{DefaultText := DynamicText("Acheter Mythic")}
            SecretButton := button_loud{DefaultText := DynamicText("Acheter Secret")}
            DivineButton := button_loud{DefaultText := DynamicText("Acheter Divine")}
            ExoticButton := button_loud{DefaultText := DynamicText("Acheter Exotic")}

            # Grille 3x3 : 3 rangées de 3 packs, du moins cher au plus cher.
            Row1 := BuildRow(BuildCard("Common", CommonPrice, CommonSlot, CommonButton), BuildCard("Rare", RarePrice, RareSlot, RareButton), BuildCard("Epic", EpicPrice, EpicSlot, EpicButton))
            Row2 := BuildRow(BuildCard("Legendary", LegendaryPrice, LegendarySlot, LegendaryButton), BuildCard("Elite", ElitePrice, EliteSlot, EliteButton), BuildCard("Mythic", MythicPrice, MythicSlot, MythicButton))
            Row3 := BuildRow(BuildCard("Secret", SecretPrice, SecretSlot, SecretButton), BuildCard("Divine", DivinePrice, DivineSlot, DivineButton), BuildCard("Exotic", ExoticPrice, ExoticSlot, ExoticButton))

            Grid := stack_box:
                Orientation := orientation.Vertical
                Slots := array:
                    stack_box_slot{Widget := Row1}
                    stack_box_slot{Widget := Row2}
                    stack_box_slot{Widget := Row3}

            # Enveloppe la grille dans une zone défilante au cas où les 3 rangées
            # dépasseraient la hauteur visible (permet de descendre pour tout voir).
            ScrollArea := scroll_box:
                Orientation := orientation.Vertical
                Slots := array:
                    scroll_box_slot{Widget := Grid}

            RootCanvas := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := ScrollArea
                        Anchors := anchors{Minimum := vector2{X := 0.06, Y := 0.10}, Maximum := vector2{X := 0.94, Y := 0.97}}
                    canvas_slot:
                        Widget := CloseButton
                        Anchors := anchors{Minimum := vector2{X := 0.42, Y := 0.02}, Maximum := vector2{X := 0.58, Y := 0.08}}

            PlayerUI.AddWidget(RootCanvas, player_ui_slot{InputMode := ui_input_mode.All})
            if (set OpenUI[Player] = RootCanvas):
                true

            CloseButton.OnClick().Subscribe(OnCloseClicked)
            CommonButton.OnClick().Subscribe(OnBuyCommonClicked)
            RareButton.OnClick().Subscribe(OnBuyRareClicked)
            EpicButton.OnClick().Subscribe(OnBuyEpicClicked)
            LegendaryButton.OnClick().Subscribe(OnBuyLegendaryClicked)
            EliteButton.OnClick().Subscribe(OnBuyEliteClicked)
            MythicButton.OnClick().Subscribe(OnBuyMythicClicked)
            SecretButton.OnClick().Subscribe(OnBuySecretClicked)
            DivineButton.OnClick().Subscribe(OnBuyDivineClicked)
            ExoticButton.OnClick().Subscribe(OnBuyExoticClicked)

    OnBuyCommonClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, CommonSlot.TierId, CommonPrice)

    OnBuyRareClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, RareSlot.TierId, RarePrice)

    OnBuyEpicClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, EpicSlot.TierId, EpicPrice)

    OnBuyLegendaryClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, LegendarySlot.TierId, LegendaryPrice)

    OnBuyEliteClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, EliteSlot.TierId, ElitePrice)

    OnBuyMythicClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, MythicSlot.TierId, MythicPrice)

    OnBuySecretClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, SecretSlot.TierId, SecretPrice)

    OnBuyDivineClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, DivineSlot.TierId, DivinePrice)

    OnBuyExoticClicked(WParam : widget_message) : void =
        BuyPack(WParam.Player, ExoticSlot.TierId, ExoticPrice)

    OnCloseClicked(WParam : widget_message) : void =
        Player := WParam.Player
        if (PlayerUI := GetPlayerUI[Player]):
            if (RootCanvas := OpenUI[Player]):
                PlayerUI.RemoveWidget(RootCanvas)
