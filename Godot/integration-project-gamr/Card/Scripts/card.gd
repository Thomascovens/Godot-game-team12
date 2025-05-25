extends Node2D

signal hovered
signal hovered_off

var starting_position
var health
var attack
var card_slot_card_is_in
var defeated = false
var card_type
var ability_script
var defence = false
var focus = false
var rage = false
var cost: int

func _ready() -> void:
	get_parent().connect_card_signals(self)

func _process(delta: float) -> void:
	$Health.text = str(health)
	$Attack.text = str(attack)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
