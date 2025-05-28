extends Area2D
class_name AttackBringerOfDeath

@export var damage: int = 30

var in_impact_phase := false
var damaged_players := []

func _ready() -> void:

	# Track bodies entering/exiting
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Start fly animation
	$AnimatedSprite2D.animation = "fly"
	$AnimatedSprite2D.play()

	# Wait 2 seconds, then enter impact phase
	await get_tree().create_timer(2.0).timeout

	in_impact_phase = true
	$AnimatedSprite2D.animation = "impact"
	$AnimatedSprite2D.play()

	# Damage all overlapping bodies once
	_check_and_damage_bodies()

	# Stay for 3 seconds in impact phase
	await get_tree().create_timer(3.0).timeout
	queue_free()


func _on_body_entered(body: Node) -> void:
	if in_impact_phase:
		_try_damage(body)

func _on_body_exited(body: Node) -> void:
	if body in damaged_players:
		damaged_players.erase(body)

func _check_and_damage_bodies():
	for body in get_overlapping_bodies():
		_try_damage(body)

func _try_damage(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if body in damaged_players:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		damaged_players.append(body)
