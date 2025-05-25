extends Node2D

var starting_position
var card_slot_card_is_in
var attack
var health
var card_type
var defeated
var ability_script
var defence = false
var focus = false
var rage = false
var cost: int

func _process(delta: float) -> void:
	$Health.text = str(health)
	$Attack.text = str(attack)
