extends Node

@export var mob_scene: PackedScene
@export var shootermob_scene: PackedScene
@export var character_nodes: Array[NodePath]
@export var start_character_index: int = 0

var score: int
var _soldier_spawn_count: int = 0
var active_player: NodePath

const SPAWN_MARGIN = 16  # Keep margin for spawning

func new_game():
	score = 0
	_soldier_spawn_count = 0

	$StartTimer.start()
	$HUD.update_score(score)


func hide_all_characters():
	for path in character_nodes:
		if not path.is_empty() and has_node(path):
			var ch := get_node(path)
			ch.hide()
			ch.set_process(false)
			ch.set_physics_process(false)
			ch.set_process_input(false)
			ch.set_process_unhandled_input(false)

			# 🔧 Disabling all cameras
			var cam := ch.get_node_or_null("Camera2D")
			if cam:
				cam.enabled = false


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()


func switch_character(index: int):
	if index < 0 or index >= character_nodes.size():
		return

	if not active_player.is_empty():
		var old := get_node(active_player)
		old.hide()
		old.set_physics_process(false)
		old.set_process(false)
		old.set_process_input(false)
		old.set_process_unhandled_input(false)

		var old_cam := old.get_node_or_null("Camera2D")
		if old_cam:
			old_cam.enabled = false

	active_player = character_nodes[index]
	var new := get_node(active_player)

	var sprite := new.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.visible = true

	new.show()

	# Position without mapbounds, so just spawn at StartPosition with margin clamp if needed
	var safe_pos = $StartPosition.global_position
	# Optionally clamp here if you keep map bounds in some variable, but now we assume no clamp
	new.global_position = safe_pos

	new.set_physics_process(true)
	new.set_process(true)
	new.set_process_input(true)
	new.set_process_unhandled_input(true)

	if new.has_method("start"):
		new.start(safe_pos)

	var cam := new.get_node("Camera2D")
	cam.enabled = true

	Global.set_player(new)
	print("Activated character: ", new.name)


func _on_mob_timer_timeout():
	var mob = mob_scene.instantiate()
	add_child(mob)
	# Without map bounds, spawn anywhere or implement your own logic
	mob.global_position = _get_random_spawn_position()

	_soldier_spawn_count += 1

	if _soldier_spawn_count % 10 == 0:
		var wiz = shootermob_scene.instantiate()
		add_child(wiz)
		wiz.global_position = _get_random_spawn_position()
		print("Spawning ghost wizard at:", wiz.global_position)


func increment_score():
	score += 1
	$HUD/ScoreLabel.text = str(score)


func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
	$HUD.update_score(score)


func _ready():
	randomize()

	hide_all_characters()
	switch_character(start_character_index)
	Global.set_player(get_node(active_player))

	new_game()

	# Removed Mapbounds detection and rect calculation


func _get_random_spawn_position() -> Vector2:
	# Since Mapbounds is gone, spawn randomly in some area you define here manually
	# Example: spawn anywhere inside 0,0 to 1024,768 - adjust to your game world size
	return Vector2(
		randf_range(0 + SPAWN_MARGIN, 1024 - SPAWN_MARGIN),
		randf_range(0 + SPAWN_MARGIN, 768 - SPAWN_MARGIN)
	)


func _get_random_camera_corner() -> Vector2:
	var player := get_node(active_player)
	var cam: Camera2D = player.get_node("Camera2D")
	var vp_size : Vector2 = get_viewport().get_visible_rect().size
	var half_extents := (vp_size * 0.5) * cam.zoom
	var center := cam.global_position
	var corners = [
		center + Vector2(-half_extents.x, -half_extents.y),  # top-left
		center + Vector2( half_extents.x, -half_extents.y),  # top-right
		center + Vector2( half_extents.x,  half_extents.y),  # bottom-right
		center + Vector2(-half_extents.x,  half_extents.y)   # bottom-left
	]
	return corners[randi() % corners.size()]
