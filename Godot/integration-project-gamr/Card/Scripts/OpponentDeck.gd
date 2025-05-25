extends Node2D

const CARD_SCENE_PATH = "res://Card/Scenes/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTING_HAND_SIZE = 4

var card_database_reference
var deck_size


func _ready() -> void:

	#$RichTextLabel.text = str(opponent_deck.size())
	card_database_reference = preload("res://Card/Scripts/CardDatabase.gd")
	#for i in range(STARTING_HAND_SIZE):
		#draw_card()
	
	
func draw_card(card_drawn_name):	
	if deck_size -1 == 0:
		visible = false
	else:
		deck_size -= 1
		$RichTextLabel.text = str(deck_size)
	
		
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Card/Assets/Cards/" + card_drawn_name + ".png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][3]
	new_card.cost = card_database_reference.CARDS[card_drawn_name][2]
	if new_card.card_type == "Unit":
		new_card.get_node("Ability").visible = false
		new_card.attack = card_database_reference.CARDS[card_drawn_name][0]
		new_card.get_node("Attack").text = str(new_card.attack)
		new_card.health = card_database_reference.CARDS[card_drawn_name][1]
		new_card.get_node("Health").text = str(new_card.health)
		if card_database_reference.CARDS[card_drawn_name][4] != null:
			new_card.get_node("Ability").text = card_database_reference.CARDS[card_drawn_name][4]
			new_card.get_node("Ability").visible = true
		new_card.defence = card_database_reference.CARDS[card_drawn_name][6]
		new_card.focus = card_database_reference.CARDS[card_drawn_name][7]
		new_card.rage = card_database_reference.CARDS[card_drawn_name][8]
	else: 
		
		new_card.get_node("Attack").visible = false
		new_card.get_node("Health").visible = false
		new_card.get_node("Ability").text = card_database_reference.CARDS[card_drawn_name][4]	
		new_card.get_node("Ability").visible = true
		var new_card_ability_script_path = card_database_reference.CARDS[card_drawn_name][5]
		if new_card_ability_script_path:
			new_card.ability_script = load(new_card_ability_script_path).new()

	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
