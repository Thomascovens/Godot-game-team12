extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 0.6
const CARD_BIGGER_SCALE = 1
const CARD_SMALLER_SCALE = 0.4
const HOVER_ANIMATION_SPEED = 0.05

var highlight_timer = null
var currently_highlighted_card = null
var default_y_pos 

var screen_size
var card_being_dragged
var is_hovering_on_card
var selected_monster

var player_hand_reference

func _ready() -> void:
	screen_size = Vector2(1920, 1080)
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
	
	player_hand_reference = $"../PlayerHand"
	highlight_timer = Timer.new()
	highlight_timer.one_shot = true
	add_child(highlight_timer)

func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0 , screen_size.x),
		clamp(mouse_pos.y,0,screen_size.y))

func card_clicked(card):
	if card.card_slot_card_is_in:
			if card  in $"../BattleManager".player_cards_that_attacked_this_turn:
				return
			if card.card_type != "Unit":
				return
			if $"../BattleManager".opponent_cards_on_battlefield.size() == 0:
				$"../BattleManager".direct_attack(card)
			else:
				select_card_for_battle(card)
	else:
		start_drag(card)

func select_card_for_battle(card):
	if selected_monster:
		if selected_monster == card:
			card.position.y += 20
			selected_monster = null
		else:
			selected_monster.position.y += 20
			selected_monster = card
			card.position.y -= 20
	else:
		selected_monster = card
		card.position.y -= 20

func unselect_selected_monster():
	if selected_monster:
		selected_monster.position.y +=20
		selected_monster = null

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE,DEFAULT_CARD_SCALE)

func finish_drag():
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot and card_being_dragged.cost <= $"../BattleManager".energy:
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			var player_id = multiplayer.get_unique_id()
			$"../BattleManager".reduce_energy(card_being_dragged.cost)
			player_card_here_and_for_clients_opponents(player_id, str(card_being_dragged.name),str(card_slot_found.name))
			rpc("player_card_here_and_for_clients_opponents", player_id, str(card_being_dragged.name),str(card_slot_found.name))

		currently_highlighted_card = null
		is_hovering_on_card = false
		highlight_timer.stop()
		card_being_dragged = null
		return
	
	player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null

@rpc("any_peer")
func player_card_here_and_for_clients_opponents(player_id, card_name, card_slot_name):
	var card
	var card_slot
	var same_peer = multiplayer.get_unique_id() == player_id
	
	if same_peer:
		card = get_node(card_name)
		card_slot = $"../CardSlots".get_node(card_slot_name)
		is_hovering_on_card = false
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		card.position = card_slot.position
		card_slot.get_node("Area2D/CollisionShape2D").disabled = true
		$"../BattleManager".player_cards_on_battlefield.append(card)
		card.card_slot_card_is_in = card_slot
		card_slot.card_in_slot = true
		if card.card_type == "Magic":
			card.ability_script.trigger_ability($"..", get_parent().get_parent().get_node("OpponentField") ,$"../BattleManager", $"../InputManager", card)
		
	else:
		var opponent_field_ref = get_parent().get_parent().get_node("OpponentField")
		card = opponent_field_ref.get_node("CardManager/" + card_name)
		card_slot = opponent_field_ref.get_node("CardSlots/"+ card_slot_name)
		opponent_field_ref.get_node("OpponentHand").remove_card_from_hand(card)
		var tween = get_tree().create_tween()
		tween.tween_property(card,"position",card_slot.position,DEFAULT_CARD_MOVE_SPEED)
		card.get_node("AnimationPlayer").play("card_flip")
		$"../BattleManager".opponent_cards_on_battlefield.append(card)
		card.card_slot_card_is_in = card_slot
		card_slot.card_in_slot = true
		if card.card_type == "Magic":
			card.ability_script.trigger_opponent_ability($"..",get_parent().get_parent().get_node("OpponentField"),$"../BattleManager", card)
	
	
	card.scale = Vector2(CARD_SMALLER_SCALE,CARD_SMALLER_SCALE)
	card.z_index = -1
	
	

	




func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	if card.card_slot_card_is_in:
		animate_card_scale(card, Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE))
		card.z_index = 0
	elif !is_hovering_on_card:
		highlight_timer.stop()

		if currently_highlighted_card != null and currently_highlighted_card != card:
			highlight_card(currently_highlighted_card, false)

		default_y_pos = card.position.y
		is_hovering_on_card = true
		currently_highlighted_card = card
		highlight_card(card,true)

func on_hovered_off_card(card):
	if !card.defeated and card == currently_highlighted_card:
		if !card_being_dragged && !card.card_slot_card_is_in:
			var new_card_hovered = raycast_check_for_card()
			if new_card_hovered:
				highlight_timer.wait_time = 0.1
				highlight_timer.start()

			# Connect one-shot signal to handle unhighlighting after delay
				if not highlight_timer.timeout.is_connected(_on_highlight_timer_timeout):
					highlight_timer.timeout.connect(_on_highlight_timer_timeout)
			else:
				is_hovering_on_card = false
		elif card.card_slot_card_is_in:
			card.scale = Vector2(CARD_SMALLER_SCALE,CARD_SMALLER_SCALE)
			card.z_index = 0

func _on_highlight_timer_timeout():
	var new_card_hovered = raycast_check_for_card()
	
	
	# Only unhighlight if we're not hovering over another card
	if currently_highlighted_card and (!new_card_hovered or new_card_hovered != currently_highlighted_card):
		highlight_card(currently_highlighted_card, false)
		currently_highlighted_card = null
		is_hovering_on_card = false
	
	# Clean up the signal connection
	if highlight_timer.timeout.is_connected(_on_highlight_timer_timeout):
		highlight_timer.timeout.disconnect(_on_highlight_timer_timeout)

func highlight_card(card, hovered):
	if hovered:
		animate_card_scale(card, Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE))
		animate_card_position(card, Vector2(card.position.x, $"../PlayerHand".HAND_Y_POSITION - 200))
		card.z_index = 2
	else:
		animate_card_scale(card, Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE))
		animate_card_position(card, Vector2(card.position.x, $"../PlayerHand".HAND_Y_POSITION))
		card.z_index = 1

func animate_card_scale(card, target_scale):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "scale", target_scale, HOVER_ANIMATION_SPEED).set_ease(Tween.EASE_OUT)
	
func animate_card_position(card, target_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", target_position, HOVER_ANIMATION_SPEED).set_ease(Tween.EASE_OUT)


func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() >0:
		return result[0].collider.get_parent()
	return null
	
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() >0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1,cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card

func on_left_click_released():
	if card_being_dragged:
		finish_drag()
