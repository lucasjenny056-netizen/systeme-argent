using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Bouton qui ouvre un catalogue façon "pokédex" : TOUTES les cartes du jeu
# sont affichées en grille (3x3 par page), avec Précédent/Suivant pour
# parcourir les pages. Nom et rareté d'une carte sont toujours visibles,
# mais tant que le joueur ne l'a pas obtenue elle reste en gris et son
# revenu ($/s) affiche "???" ; dès qu'elle tombe d'un pack, elle passe en
# couleur (une couleur par rareté) et son revenu s'affiche.
#
# Verse n'a pas de zone de défilement (scroll_box) utilisable pour ce genre
# de grille dynamique : la pagination par page de 9 cartes remplace le
# défilement à la souris.
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
    var CurrentPage : [player]int = map{}

    OnBegin<override>()<suspends> : void =
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent : agent) : void =
        if (Player := player[Agent]):
            if (set CurrentPage[Player] = 0):
                true
            OpenCatalogUI(Player)

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

    IsOwned(OwnedCards : [string]int, CardId : string) : logic =
        if (OwnedCards[CardId]):
            true
        else:
            false

    # Couleur grise utilisée pour une carte pas encore obtenue.
    LockedColor : color = color{R := 0.45, G := 0.45, B := 0.45, A := 1.0}

    # Une couleur par rareté, appliquée une fois la carte obtenue.
    RarityColor(Rarity : card_rarity) : color =
        if (Rarity = card_rarity.Common):
            color{R := 0.85, G := 0.85, B := 0.85, A := 1.0}
        else if (Rarity = card_rarity.Rare):
            color{R := 0.2, G := 0.6, B := 1.0, A := 1.0}
        else if (Rarity = card_rarity.Epic):
            color{R := 0.65, G := 0.2, B := 0.95, A := 1.0}
        else if (Rarity = card_rarity.Legendary):
            color{R := 1.0, G := 0.6, B := 0.0, A := 1.0}
        else if (Rarity = card_rarity.Elite):
            color{R := 0.0, G := 0.9, B := 0.9, A := 1.0}
        else if (Rarity = card_rarity.Mythic):
            color{R := 0.9, G := 0.1, B := 0.15, A := 1.0}
        else if (Rarity = card_rarity.Secret):
            color{R := 1.0, G := 0.1, B := 0.6, A := 1.0}
        else if (Rarity = card_rarity.Divine):
            color{R := 1.0, G := 0.85, B := 0.0, A := 1.0}
        else:
            color{R := 0.9, G := 0.0, B := 0.0, A := 1.0}

    # Renvoie la carte à Index dans Cards, ou une carte "vide" (CardId := "")
    # si Index dépasse la fin du tableau (sert à toujours avoir 9 cases par page).
    CardAt(Cards : []card_definition, Index : int) : card_definition =
        if (Found := Cards[Index]) then Found else card_definition{}

    # Construit une case de la grille. Case vide (fin de la liste des cartes) :
    # un bloc de texte blanc. Case avec carte : nom et rareté toujours visibles ;
    # tant que le joueur ne possède pas la carte, tout s'affiche en gris et le
    # revenu affiche "???" ; une fois obtenue, tout passe dans la couleur de sa
    # rareté et le revenu réel s'affiche.
    BuildCardBox(Card : card_definition, Owned : logic) : stack_box =
        if (Card.CardId = ""):
            stack_box:
                Orientation := orientation.Vertical
                Slots := array:
                    stack_box_slot{Widget := text_block{DefaultText := DynamicText("")}}
        else:
            TextColor : color = if (Owned?) then RarityColor(Card.Rarity) else LockedColor
            IncomeText : string = if (Owned?) then "{Card.IncomeRate}$/s" else "???"
            stack_box:
                Orientation := orientation.Vertical
                Slots := array:
                    stack_box_slot{Widget := text_block{DefaultText := DynamicText(IncomeText), DefaultTextColor := TextColor}}
                    stack_box_slot{Widget := text_block{DefaultText := DynamicText(Card.DisplayName), DefaultTextColor := TextColor}}
                    stack_box_slot{Widget := text_block{DefaultText := DynamicText(RarityName(Card.Rarity)), DefaultTextColor := TextColor}}

    BuildRow(BoxA : stack_box, BoxB : stack_box, BoxC : stack_box) : stack_box =
        stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot{Widget := BoxA}
                stack_box_slot{Widget := BoxB}
                stack_box_slot{Widget := BoxC}

    OpenCatalogUI(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            OwnedCards := Catalog.GetOwnedCards(Player)
            AllCards := CardCatalog.GetAllCards()
            Page := if (P := CurrentPage[Player]) then P else 0
            Base := Page * 9

            Card0 := CardAt(AllCards, Base + 0)
            Card1 := CardAt(AllCards, Base + 1)
            Card2 := CardAt(AllCards, Base + 2)
            Card3 := CardAt(AllCards, Base + 3)
            Card4 := CardAt(AllCards, Base + 4)
            Card5 := CardAt(AllCards, Base + 5)
            Card6 := CardAt(AllCards, Base + 6)
            Card7 := CardAt(AllCards, Base + 7)
            Card8 := CardAt(AllCards, Base + 8)

            Row1 := BuildRow(BuildCardBox(Card0, IsOwned(OwnedCards, Card0.CardId)), BuildCardBox(Card1, IsOwned(OwnedCards, Card1.CardId)), BuildCardBox(Card2, IsOwned(OwnedCards, Card2.CardId)))
            Row2 := BuildRow(BuildCardBox(Card3, IsOwned(OwnedCards, Card3.CardId)), BuildCardBox(Card4, IsOwned(OwnedCards, Card4.CardId)), BuildCardBox(Card5, IsOwned(OwnedCards, Card5.CardId)))
            Row3 := BuildRow(BuildCardBox(Card6, IsOwned(OwnedCards, Card6.CardId)), BuildCardBox(Card7, IsOwned(OwnedCards, Card7.CardId)), BuildCardBox(Card8, IsOwned(OwnedCards, Card8.CardId)))

            Grid := stack_box:
                Orientation := orientation.Vertical
                Slots := array:
                    stack_box_slot{Widget := Row1}
                    stack_box_slot{Widget := Row2}
                    stack_box_slot{Widget := Row3}

            CloseButton := button_quiet{DefaultText := DynamicText("Fermer")}
            PrevButton := button_quiet{DefaultText := DynamicText("< Précédent")}
            NextButton := button_quiet{DefaultText := DynamicText("Suivant >")}
            PageText := text_block{DefaultText := DynamicText("Page {Page + 1}")}

            RootCanvas := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := text_block{DefaultText := DynamicText("Ma collection")}
                        Anchors := anchors{Minimum := vector2{X := 0.3, Y := 0.02}, Maximum := vector2{X := 0.7, Y := 0.08}}
                    canvas_slot:
                        Widget := Grid
                        Anchors := anchors{Minimum := vector2{X := 0.02, Y := 0.10}, Maximum := vector2{X := 0.98, Y := 0.85}}
                    canvas_slot:
                        Widget := PageText
                        Anchors := anchors{Minimum := vector2{X := 0.42, Y := 0.86}, Maximum := vector2{X := 0.58, Y := 0.90}}
                    canvas_slot:
                        Widget := PrevButton
                        Anchors := anchors{Minimum := vector2{X := 0.15, Y := 0.90}, Maximum := vector2{X := 0.40, Y := 0.97}}
                    canvas_slot:
                        Widget := NextButton
                        Anchors := anchors{Minimum := vector2{X := 0.60, Y := 0.90}, Maximum := vector2{X := 0.85, Y := 0.97}}
                    canvas_slot:
                        Widget := CloseButton
                        Anchors := anchors{Minimum := vector2{X := 0.42, Y := 0.90}, Maximum := vector2{X := 0.58, Y := 0.97}}

            PlayerUI.AddWidget(RootCanvas, player_ui_slot{InputMode := ui_input_mode.All})
            if (set OpenUI[Player] = RootCanvas):
                true

            CloseButton.OnClick().Subscribe(OnCloseClicked)
            PrevButton.OnClick().Subscribe(OnPrevClicked)
            NextButton.OnClick().Subscribe(OnNextClicked)

    CloseUI(Player : player) : void =
        if (PlayerUI := GetPlayerUI[Player]):
            if (RootCanvas := OpenUI[Player]):
                PlayerUI.RemoveWidget(RootCanvas)

    OnPrevClicked(WParam : widget_message) : void =
        Player := WParam.Player
        Page := if (P := CurrentPage[Player]) then P else 0
        NewPage := if (Page > 0) then Page - 1 else 0
        CloseUI(Player)
        if (set CurrentPage[Player] = NewPage):
            true
        OpenCatalogUI(Player)

    OnNextClicked(WParam : widget_message) : void =
        Player := WParam.Player
        Page := if (P := CurrentPage[Player]) then P else 0
        AllCards := CardCatalog.GetAllCards()
        NewPage := if ((Page + 1) * 9 < AllCards.Length) then Page + 1 else Page
        CloseUI(Player)
        if (set CurrentPage[Player] = NewPage):
            true
        OpenCatalogUI(Player)

    OnCloseClicked(WParam : widget_message) : void =
        CloseUI(WParam.Player)
