extends Node2D

var card_in_slot = false
var card_slot_type = "Magic"

func _ready() -> void:
	var image = Image.load_from_file("res://Card/magicCardSlot.png")
	get_node("CardSlotImage").texture = ImageTexture.create_from_image(image)
