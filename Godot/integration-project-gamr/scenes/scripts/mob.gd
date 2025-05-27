extends RigidBody2D

@export var speed: float = 100.0
@export var player_path: NodePath
@export var max_health: int = 30

var player: Node2D
var health: int
var is_dead := false
var is_attacking: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	collision_mask = 1 << 0  # only “see” layer 1 (Player)
	health = max_health

	if player_path != null:
		player = get_node(player_path)
		agent.target_position = player.global_position

	sprite.animation = "run"
	sprite.play()

	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	connect("body_entered", Callable(self, "_on_body_entered"))
	screen_notifier.connect("screen_exited", Callable(self, "_on_screen_exited"))

func _physics_process(_delta: float) -> void:
	if is_dead or is_attacking or player == null:
		linear_velocity = Vector2.ZERO
		return

	# Update the target if player moved
	if agent.target_position.distance_to(player.global_position) > 8.0:
		agent.target_position = player.global_position

	if agent.is_navigation_finished():
		linear_velocity = Vector2.ZERO
		return

	var next_position = agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	linear_velocity = direction * speed

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if is_dead or is_attacking:
		return

	is_attacking = true
	linear_velocity = Vector2.ZERO

	if body.has_method("take_damage"):
		body.take_damage(10)

	sprite.sprite_frames.set_animation_loop("attack", false)
	sprite.animation = "attack"
	sprite.frame = 0
	sprite.play()

func _on_animation_finished() -> void:
	match sprite.animation:
		"attack":
			is_attacking = false
			sprite.animation = "run"
			sprite.play()
		"die":
			queue_free()

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
