extends Node

@export var mob_scene: PackedScene
var score = 0

func new_game():
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()

func _on_mob_timer_timeout():
	var mob = mob_scene.instantiate()
	# 1) Tell it who to chase *before* adding to the scene
	mob.player_path = $Player.get_path()
	# 2) Add & position
	add_child(mob)
	mob.global_position = _get_random_camera_corner()


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
	new_game()
	

# — helper to pick one of the four view‐corners in world space —
func _get_random_camera_corner() -> Vector2:
	# find your player‐camera
	var cam : Camera2D = $Player/Camera2D
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
