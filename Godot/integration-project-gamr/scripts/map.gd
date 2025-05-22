extends Node2D

func _ready():
	# 1) Lake animations
	_play_all_animated($Lake_animations)
	# 2) Everything under 3D decoration/animated objects
	var anim_objs = get_node("3D decoration/animated_objects")
	_play_all_animated(anim_objs)

func _play_all_animated(root: Node) -> void:
	for child in root.get_children():
		if child is AnimatedSprite2D:
			child.play()
		else:
			# recurse into any non‐sprite container
			_play_all_animated(child)
