extends Node

const DAMAGE = 3
const FIREBALL= "res://Card/Scenes/projectile.tscn"

func trigger_ability(player_field_manager, opponent_field_manager, battle_manager_reference,input_manager_reference, card_with_ability):
	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_end_turn_button(false)
	battle_manager_reference.opponent_health = max(0, battle_manager_reference.opponent_health - DAMAGE)
	opponent_field_manager.get_node("OpponentHealth").text = str(battle_manager_reference.opponent_health)
	await battle_manager_reference.wait(1)
	battle_manager_reference.destroy_card(card_with_ability,"Player")
	input_manager_reference.inputs_disabled = false
	battle_manager_reference.enable_end_turn_button(true)
	battle_manager_reference.check_game_over()
	
	var fireball = load(FIREBALL).instantiate()
	
	player_field_manager.add_child(fireball)
	fireball.position = card_with_ability.position
	fireball.scale = Vector2(5,5)
	fireball.z_index = 10
	var position = opponent_field_manager.get_node("Character").position
	
	var tween = opponent_field_manager.create_tween()
	tween.tween_property(fireball, "position",position , 1)
	await tween.finished
	
	fireball.get_node("AnimatedSprite2D").play("fireball_on_impact")
	battle_manager_reference.wait(.5)
	player_field_manager.remove_child(fireball)
	
	
func trigger_opponent_ability(player_field_manager, opponent_field_manager, battle_manager_reference, card_with_ability):
	battle_manager_reference.player_health = max(0, battle_manager_reference.player_health - DAMAGE)
	battle_manager_reference.destroy_card(card_with_ability,"Opponent")
	battle_manager_reference.check_game_over()
	
	var fireball = load(FIREBALL).instantiate()
	
	opponent_field_manager.add_child(fireball)
	fireball.position = card_with_ability.position
	fireball.scale = Vector2(5,5)
	fireball.z_index = 10
	var position = player_field_manager.get_node("Character").position
	
	var tween = player_field_manager.create_tween()
	tween.tween_property(fireball, "position",position , 1)
	await tween.finished
	
	fireball.get_node("AnimatedSprite2D").play("fireball_on_impact")
	battle_manager_reference.wait(.1)
	opponent_field_manager.remove_child(fireball)
