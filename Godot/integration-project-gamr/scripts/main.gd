extends Node

@export var mob_scene: PackedScene
@export var shootermob_scene: PackedScene
@export var character_nodes: Array[NodePath]
@export var start_character_index: int = 0

var score: int
var _soldier_spawn_count: int = 0
var active_player: NodePath

var map_bounds_rect: Rect2  # Store world bounds rectangle here

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

	# -- FIX: Set position BEFORE enabling physics processing
	var safe_pos = _clamp_spawn_to_bounds($StartPosition.global_position)
	new.global_position = safe_pos

	new.set_physics_process(true)
	new.set_process(true)
	new.set_process_input(true)
	new.set_process_unhandled_input(true)

	# If your character has a 'start' method, call it AFTER setting position and enabling processes
	if new.has_method("start"):
		new.start(safe_pos)

	var cam := new.get_node("Camera2D")
	cam.enabled = true

	Global.set_player(new)
	print("Activated character: ", new.name)

# Updated clamp function with margin inside the map bounds
const SPAWN_MARGIN = 16

func _clamp_spawn_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, map_bounds_rect.position.x + SPAWN_MARGIN, map_bounds_rect.end.x - SPAWN_MARGIN),
		clamp(pos.y, map_bounds_rect.position.y + SPAWN_MARGIN, map_bounds_rect.end.y - SPAWN_MARGIN)
	)





func _on_mob_timer_timeout():
	# 1) Spawn the soldier
	var mob = mob_scene.instantiate()
	add_child(mob)
	mob.global_position = _get_random_spawn_position()

	# 2) Increment our soldier counter
	_soldier_spawn_count += 1

	# 3) Every 10th soldier, also spawn a ghost wizard
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

	# ✅ Correct world bounds setup
	var shape_node = get_node("Mapbounds/Shape")
	if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
		var rect_shape = shape_node.shape as RectangleShape2D
		var extents = rect_shape.extents
		var global_origin = shape_node.global_transform.origin
		# This is the center of the rect in world space
		var top_left = global_origin - extents
		var size = extents * 2
		map_bounds_rect = Rect2(top_left, size)
	else:
		push_error("Mapbounds/Shape must be a RectangleShape2D!")

# Helper function to pick a random spawn position inside the map bounds
func _get_random_spawn_position() -> Vector2:
	var x = randf_range(map_bounds_rect.position.x, map_bounds_rect.position.x + map_bounds_rect.size.x)
	var y = randf_range(map_bounds_rect.position.y, map_bounds_rect.position.y + map_bounds_rect.size.y)
	return Vector2(x, y)


# — helper to pick one of the four view‐corners in world space —
func _get_random_camera_corner() -> Vector2:
	# find your player‐camera
	var player := get_node(active_player)
	var cam: Camera2D = player.get_node("Camera2D")
	# get the current visible viewport size in pixels
	var vp_size : Vector2 = get_viewport().get_visible_rect().size
	# half‐extents in world units (accounting for zoom)
	var half_extents := (vp_size * 0.5) * cam.zoom
	# camera center in world space
	var center := cam.global_position
	# build the four corners
	var corners = [
		center + Vector2(-half_extents.x, -half_extents.y),  # top‐left
		center + Vector2( half_extents.x, -half_extents.y),  # top‐right
		center + Vector2( half_extents.x,  half_extents.y),  # bottom‐right
		center + Vector2(-half_extents.x,  half_extents.y)   # bottom‐left
	]
	# return one at random
	return corners[randi() % corners.size()]
