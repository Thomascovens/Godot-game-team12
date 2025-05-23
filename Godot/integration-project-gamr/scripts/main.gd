extends Node

@export var mob_scene: PackedScene
@export var shootermob_scene: PackedScene

var score: int
var _soldier_spawn_count: int = 0

var map_bounds_rect: Rect2  # Store world bounds rectangle here

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
	if not multiplayer.is_server():
		return  # Only the server should spawn enemies

	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		print("No players found!")
		return

	var spawn_position = _get_random_spawn_position()

	# Spawn the soldier mob via MultiplayerSpawner
	var mob = $MultiplayerSpawner.spawn(mob_scene)
	if mob:
		mob.global_position = spawn_position
		mob.player_path = players[0].get_path()
		_soldier_spawn_count += 1

	# Every 10th soldier, also spawn a ghost wizard
	if _soldier_spawn_count % 10 == 0:
		var wiz = $MultiplayerSpawner.spawn(shootermob_scene)
		if wiz:
			wiz.global_position = _get_random_spawn_position()
			wiz.player_path = players[0].get_path()

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
	
	
	
	randomize()      # so randi() is different each run

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

# Helper function to pick a random spawn position inside the map bounds
func _get_random_spawn_position() -> Vector2:
	var x = randf_range(map_bounds_rect.position.x, map_bounds_rect.position.x + map_bounds_rect.size.x)
	var y = randf_range(map_bounds_rect.position.y, map_bounds_rect.position.y + map_bounds_rect.size.y)
	return Vector2(x, y)




# /-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#/-/-/-/-/-/-/-/-/Multiplayer/-/-/-/-/-/-/-/-/
#/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/--/-/-/
func become_host():
	print("Become host pressed")
	%MultiplayerHUD.hide()
	MultiplayerManager.become_host()
	
func join_as_player_2():
	print("Join as player 2")
	%MultiplayerHUD.hide()
	MultiplayerManager.join_as_player_2()
