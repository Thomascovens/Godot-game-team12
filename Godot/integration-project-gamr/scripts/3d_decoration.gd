extends Node2D

@export var player_path: NodePath
var player: Node2D

func _ready():
	player = get_node_or_null(player_path)
	if not player:
		push_error("Player node not found at " + str(player_path))

func _process(_delta):
	if not player:
		return

	# Each child is a pillar with a StaticBody2D footprint
	for pillar in get_children():
		if not pillar.has_node("StaticBody2D"):
			continue

		var foot := pillar.get_node("StaticBody2D") as StaticBody2D
		var base_y := foot.global_position.y

		# If the player is below that Y, draw the pillar on top; otherwise behind
		if player.global_position.y > base_y:
			pillar.z_index = -1
		else:
			pillar.z_index = 1
