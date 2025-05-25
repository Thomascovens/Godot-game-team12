extends Node2D

const CARD_SCENE_PATH = "res://Card/Scenes/card.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTING_HAND_SIZE = 6
const DRAW_CARD_COST = 1

var player_deck = ["Knight", "Mage","Mage","Assassin","Assassin" , "General","Knight", "Mage","Mage","Assassin","Assassin" , "General","Knight", "Mage","Mage","Assassin","Assassin" , "General","Knight", "Mage","Mage","Assassin","Assassin" , "General","Tornado","Tornado","Tornado","Knight","Knight","Knight", "Lightning","Lightning","Sword","Sword","Sword","Fireball","Fireball","Fireball","Fireball","Knight", "Mage","Mage","Assassin","Assassin" , "General","Tornado","Tornado","Tornado","Knight","Knight","Knight", "Lightning","Lightning","Sword","Sword","Sword","Fireball","Fireball","Fireball","Fireball","Knight", "Mage","Mage","Assassin","Assassin" , "General","Tornado","Tornado","Tornado","Knight","Knight","Knight", "Lightning","Lightning","Sword","Sword","Sword","Fireball","Fireball","Fireball","Fireball"]
var card_database_reference
var drawn_card_this_turn = false
var deck_timer


func _ready() -> void:
	player_deck.shuffle()
	#$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://Card/Scripts/CardDatabase.gd")
	#for i in range(STARTING_HAND_SIZE):
		#draw_card()
		#drawn_card_this_turn = false
	deck_timer = $DeckTimer
	deck_timer.one_shot = true
	deck_timer.wait_time = 1.0
	
func draw_initial_hand():
	deck_timer.start()
	await deck_timer.timeout
	
	deck_timer.wait_time = .1
	var player_id = multiplayer.get_unique_id()
	
	for i in range(STARTING_HAND_SIZE):
		var card_drawn_name = player_deck[0]
		draw_here_and_for_clients_opponent(player_id, card_drawn_name)
		rpc("draw_here_and_for_clients_opponent",player_id, card_drawn_name)
		drawn_card_this_turn = false
		deck_timer.start()
		await deck_timer.timeout

@rpc("any_peer")
func draw_here_and_for_clients_opponent(player_id, card_drawn_name):
	if multiplayer.get_unique_id() == player_id:
		draw_card(card_drawn_name)
	else:
		get_parent().get_parent().get_node("OpponentField/OpponentDeck").draw_card(card_drawn_name)
	

func deck_clicked():
	if drawn_card_this_turn or $"../BattleManager".energy < DRAW_CARD_COST:
		return
	$"../BattleManager".reduce_energy(DRAW_CARD_COST)
	var card_drawn_name = player_deck[0]
	var player_id = multiplayer.get_unique_id()
	draw_here_and_for_clients_opponent(player_id,card_drawn_name)
	rpc("draw_here_and_for_clients_opponent",player_id,card_drawn_name)

func draw_card(card_drawn_name):

	drawn_card_this_turn = true
	
	player_deck.erase(card_drawn_name)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
	$RichTextLabel.text = str(player_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Card/Assets/Cards/" + card_drawn_name + ".png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	
	new_card.card_type = str(card_database_reference.CARDS[card_drawn_name][3])
	new_card.cost = card_database_reference.CARDS[card_drawn_name][2]
	new_card.get_node("Cost").text = str(new_card.cost)
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
		var new_card_ability_script_path = card_database_reference.CARDS[card_drawn_name][5]
		if new_card_ability_script_path:
			new_card.ability_script = load(new_card_ability_script_path).new()
	else:
		new_card.get_node("Ability").visible = true
		new_card.get_node("Attack").visible = false
		new_card.get_node("Health").visible = false
		new_card.get_node("Ability").text = card_database_reference.CARDS[card_drawn_name][4]
		var new_card_ability_script_path = card_database_reference.CARDS[card_drawn_name][5]
		if new_card_ability_script_path:
			new_card.ability_script = load(new_card_ability_script_path).new()
		
	

	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

func reset_draw():
	drawn_card_this_turn = false
