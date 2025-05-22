extends Node2D

func _ready():
	# Get the Area2D that holds all AnimatedSprite2D children
	var area = $Lake_animations
	for sprite in area.get_children():
		if sprite is AnimatedSprite2D:
			# Play the sprite's default animation (will loop if the animation resource is set to loop)
			sprite.play()
