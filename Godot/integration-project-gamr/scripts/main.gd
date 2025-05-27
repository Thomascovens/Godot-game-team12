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
	var player := get_node(active_player)
	_soldier_spawn_count = 0
	
	player.show()
	player.set_physics_process(true)
	player.set_process(true)
	
	$StartTimer.start()
	$HUD.update_score(score)

func hide_all_characters():
	for path in character_nodes:
		var ch := get_node(path)
		ch.hide()
		ch.set_physics_process(false)
		ch.set_process(false)
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
		var old_cam := old.get_node_or_null("Camera2D")
		if old_cam:
			old_cam.enabled = false
	active_player = character_nodes[index]
	var new := get_node(active_player)
	new.show()
	new.set_physics_process(true)
	new.set_process(true)
	if new.has_method("start"):
		new.start($StartPosition.position)
	var cam := new.get_node("Camera2D")
	cam.enabled = true
	
	Global.set_player(new) 

func _on_mob_timer_timeout():
	# 1) Spawn the soldier
	var mob = mob_scene.instantiate()
	mob.player_path = active_player
	add_child(mob)
	mob.global_position = _get_random_spawn_position()

	# 2) Increment our soldier counter
	_soldier_spawn_count += 1

	# 3) Every 10th soldier, also spawn a ghost wizard
	if _soldier_spawn_count % 10 == 0:
		var wiz = shootermob_scene.instantiate()
		wiz.player_path = active_player
		add_child(wiz)
		wiz.global_position = _get_random_spawn_position()

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
	switch_character(start_character_index)  # ✅ Must come first
	Global.set_player(get_node(active_player))  # 🔒 Redundant but safe if switch_character doesn't work

	# ✅ Now it's safe to begin spawning enemies
	new_game()

	# World bounds setup
	var shape = get_node("Mapbounds/Shape")
	if shape is CollisionShape2D and shape.shape is RectangleShape2D:
		var rect_shape = shape.shape as RectangleShape2D
		var center = shape.global_position
		var size = rect_shape.extents * 2
		map_bounds_rect = Rect2(center - rect_shape.extents, size)
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
