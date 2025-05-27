extends RigidBody2D

signal hit(new_health: int) 

@export var speed: float = 100.0
@export var player_path: NodePath
@export var max_health: int = 120
@export var shoot_cooldown: float = 1.5
@export var attack_range: float = 600

# ← Preload your mob‐projectile scene here:
const ProjectileScene: PackedScene = preload("res://scenes/Projectile_mob_ghost_wizard.tscn")

var player: Node2D
var health: int
var is_dead: bool = false
var can_shoot: bool = true

@onready var sprite: AnimatedSprite2D              = $AnimatedSprite2D
@onready var muzzle: Marker2D                      = $shootlocation
@onready var collision_shape: CollisionShape2D     = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	health = max_health
	if player_path != null and not player_path.is_empty() and has_node(player_path):
		player = get_node(player_path)
	else:
		push_error("Invalid or empty player_path in Ghost Wizard mob!")
		return

	collision_layer = 0
	collision_mask = 0
	# start running
	sprite.animation = "run"
	sprite.play()

	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	screen_notifier.connect("screen_exited", Callable(self, "_on_screen_exited"))

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		linear_velocity = Vector2.ZERO
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > attack_range:
		var dir = to_player.normalized()
		linear_velocity = dir * speed
	else:
		linear_velocity = Vector2.ZERO
		if can_shoot:
			_shoot_at(player.global_position)

func _shoot_at(target_pos: Vector2) -> void:
	can_shoot = false

	# play attack anim
	sprite.sprite_frames.set_animation_loop("attack", false)
	sprite.animation = "attack"
	sprite.frame = 0
	sprite.play()

	# ← instance the preloaded scene
	var proj = ProjectileScene.instantiate()
	proj.global_position = muzzle.global_position
	var dir = (target_pos - proj.global_position).normalized()
	# assumes your projectile script has `velocity` & `speed`
	proj.velocity = dir * proj.speed
	proj.rotation = dir.angle()
	get_tree().get_current_scene().add_child(proj)

	# cooldown
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func _on_animation_finished() -> void:
	match sprite.animation:
		"attack":
			sprite.animation = "run"
			sprite.play()
		"die":
			queue_free()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = clamp(health - amount, 0, max_health)
	emit_signal("hit", health)
	if health == 0:
		die()

func die() -> void:
	is_dead = true
	linear_velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	sprite.sprite_frames.set_animation_loop("die", false)
	sprite.animation = "die"
	sprite.frame = 0
	sprite.play()
