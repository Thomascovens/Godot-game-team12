extends RigidBody2D

@export var speed: float = 100.0
@export var player_path: NodePath
@export var max_health: int = 30

var player: Node2D
var health: int
var is_dead := false
var is_attacking: bool = false

@onready var sprite: AnimatedSprite2D              = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D     = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
	
func _ready() -> void:
	collision_mask = 1 << 0  # only “see” layer 1 (Player)
	health = max_health
	if player_path != null:
		player = get_node(player_path)

	# start running
	sprite.animation = "run"
	sprite.play()
	#print("[mob] READY, starting 'run'")

	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	connect("body_entered", Callable(self, "_on_body_entered"))
	screen_notifier.connect("screen_exited", Callable(self, "_on_screen_exited"))

func _physics_process(delta: float) -> void:
	if is_dead or is_attacking or player == null:
		linear_velocity = Vector2.ZERO
		return

	var dir = (player.global_position - global_position).normalized()
	linear_velocity = dir * speed

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	#print("[mob] _on_body_entered, attacking?", is_attacking, "body=", body.name)
	if is_dead or is_attacking:
		#print("[mob]   skipping because dead/attacking")
		return

	#print("[mob]   HIT PLAYER → launching attack")
	is_attacking = true
	linear_velocity = Vector2.ZERO

	# Deal damage
	if body.has_method("take_damage"):
		body.take_damage(10)

	# Play attack animation once
	sprite.sprite_frames.set_animation_loop("attack", false)
	sprite.animation = "attack"
	sprite.frame = 0
	sprite.play()

func _on_animation_finished() -> void:
	var just_finished = sprite.animation
	#print("[mob] animation_finished callback, current animation property is:", just_finished)
	match just_finished:
		"attack":
			#print("[mob]   attack finished → back to run")
			is_attacking = false
			sprite.animation = "run"
			sprite.play()
		"die":
			#print("[mob]   die finished → queue_free")
			queue_free()
			#print("[mob]   finished other clip:", just_finished)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	linear_velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	sprite.sprite_frames.set_animation_loop("die", false)
	sprite.animation = "die"
	sprite.frame = 0
	sprite.play()
	#print("[mob] DIE animation started")
