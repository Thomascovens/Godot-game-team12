extends Node

@export var mob_scene: PackedScene
@export var shootermob_scene: PackedScene
@export var player_group := "Player"
@export var mob_group    := "Mobs"

var score: int
var _soldier_spawn_count: int = 0
var map_bounds_rect: Rect2  # Store world bounds rectangle here

# Track which bodies are overlapping each pillar
var _overlaps: Dictionary = {}

func new_game():
	score = 0
	_soldier_spawn_count = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()

func _on_mob_timer_timeout():
	# 1) Spawn the soldier
	var mob = mob_scene.instantiate()
	mob.player_path = $Player.get_path()
	add_child(mob)
	mob.global_position = _get_random_spawn_position()

	# 2) Increment our soldier counter
	_soldier_spawn_count += 1

	# 3) Every 10th soldier, also spawn a ghost wizard
	if _soldier_spawn_count % 10 == 0:
		var wiz = shootermob_scene.instantiate()
		wiz.player_path = $Player.get_path()
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
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		MultiplayerManager.become_host()

	randomize()  # so randi() is different each run

	# Get the world bounds rectangle from Mapbounds/Shape node
	var shape = get_node("Mapbounds/Shape")
	if shape is CollisionShape2D and shape.shape is RectangleShape2D:
		var rect_shape = shape.shape as RectangleShape2D
		var center = shape.global_position
		var size = rect_shape.extents * 2
		map_bounds_rect = Rect2(center - rect_shape.extents, size)
	else:
		push_error("Mapbounds/Shape must be a RectangleShape2D!")

	new_game()

	# Connect each pillar's Check area
	var deco = get_node("map/3D decoration")
	for pillar in deco.get_children():
		var check_area = pillar.get_node_or_null("StaticBody2D/Check") as Area2D
		if check_area:
			# initialize overlap list
			_overlaps[pillar] = []
			# connect signals, binding pillar
			var enter_cb = Callable(self, "_on_body_entered").bind(pillar)
			check_area.connect("body_entered", enter_cb)
			var exit_cb = Callable(self, "_on_body_exited").bind(pillar)
			check_area.connect("body_exited", exit_cb)

	set_process(true)

func _process(_delta):
	# Continuously update z_index for any bodies currently inside a pillar's check
	for pillar in _overlaps.keys():
		var foot_y = pillar.get_node("StaticBody2D").global_position.y
		for body in _overlaps[pillar]:
			if not is_instance_valid(body):
				continue
			var actor_y = body.global_position.y
			if actor_y > foot_y:
				body.z_index = pillar.z_index + 1
			else:
				body.z_index = pillar.z_index - 1

# Helper: pick a random spawn position inside the map bounds
func _get_random_spawn_position() -> Vector2:
	var x = randf_range(map_bounds_rect.position.x, map_bounds_rect.position.x + map_bounds_rect.size.x)
	var y = randf_range(map_bounds_rect.position.y, map_bounds_rect.position.y + map_bounds_rect.size.y)
	return Vector2(x, y)

# Multiplayer RPC controls
func become_host():
	print("Become host pressed")
	%MultiplayerHUD.hide()
	MultiplayerManager.become_host()

func join_as_player_2():
	print("Join as player 2")
	%MultiplayerHUD.hide()
	MultiplayerManager.join_as_player_2()

# Pillar Check signal handlers
func _on_body_entered(body: Node, pillar: Node) -> void:
	# Add to overlap list
	if _overlaps.has(pillar):
		_overlaps[pillar].append(body)
	#print debug
	print("[DEBUG] Enter: %s in %s" % [body.name, pillar.name])

func _on_body_exited(body: Node, pillar: Node) -> void:
	# Remove from overlap list
	if _overlaps.has(pillar):
		_overlaps[pillar].erase(body)
	#print debug
	print("[DEBUG] Exit: %s from %s" % [body.name, pillar.name])
	# Reset z_index to default
	body.z_index = int(body.global_position.y)
