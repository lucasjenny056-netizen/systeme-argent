using { /Fortnite.com/UI }

# Convertit une chaîne (avec interpolation "{Valeur}") en message affichable
# par un widget (text_block, button...). DynamicText n'est pas une fonction
# native de Verse, c'est ce petit helper partagé par tous les devices UI.
DynamicText<localizes>(Msg : string) : message = "{Msg}"
