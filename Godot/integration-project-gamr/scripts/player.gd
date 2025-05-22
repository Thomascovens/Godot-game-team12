extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed: float     = 200.0
@export var run_speed:  float     = 400.0
@export var max_health: int       = 100
@export var projectile_scene: PackedScene
@export var projectile_offset: Vector2 = Vector2.ZERO

var health:         int
var is_attacking:   bool  = false
var is_invincible:  bool  = false
var map_bounds_rect: Rect2

func _ready():
	health = max_health
	$AnimatedSprite2D.frame_changed.connect(Callable(self, "_on_frame_changed"))

	var shape = get_node("../Mapbounds/Shape")
	if shape is CollisionShape2D and shape.shape is RectangleShape2D:
		var rect_shape = shape.shape as RectangleShape2D
		var center     = shape.global_position
		var size       = rect_shape.extents * 2
		map_bounds_rect = Rect2(center - rect_shape.extents, size)
	else:
		push_error("Mapbounds/Shape must be a RectangleShape2D!")

func _physics_process(delta):
	# 1) Attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		$AnimatedSprite2D.play("fireball")

	# 2) Movement input
	var input_vec: Vector2 = Vector2(
		Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left"),
		Input.get_action_strength("walk_down")  - Input.get_action_strength("walk_up")
	)
	# Normalize only if non-zero, else zero
	var dir: Vector2 = input_vec.normalized() if input_vec != Vector2.ZERO else Vector2.ZERO

	# 3) Running toggle
	var is_running: bool = Input.is_action_pressed("run")

	# 4) Move
	var speed: float = run_speed if is_running else walk_speed
	velocity = dir * speed
	move_and_slide()

	# 5) Clamp to map bounds
	global_position.x = clamp(
		global_position.x,
		map_bounds_rect.position.x,
		map_bounds_rect.position.x + map_bounds_rect.size.x
	)
	global_position.y = clamp(
		global_position.y,
		map_bounds_rect.position.y,
		map_bounds_rect.position.y + map_bounds_rect.size.y
	)

	# 6) Animation (skip if attacking)
	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.animation = "run" if is_running else "walk"
		$AnimatedSprite2D.flip_h  = dir.x < 0
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

func shoot_fireball() -> void:
	var proj = projectile_scene.instantiate() as Area2D
	proj.global_position = global_position + projectile_offset
	var mouse_pos: Vector2 = get_global_mouse_position()
	var shoot_dir: Vector2 = (mouse_pos - proj.global_position).normalized()
	proj.velocity = shoot_dir * proj.speed
	proj.rotation = shoot_dir.angle()
	get_tree().get_current_scene().add_child(proj)

func _on_frame_changed() -> void:
	var sprite = $AnimatedSprite2D
	if sprite.animation == "fireball":
		var last = sprite.sprite_frames.get_frame_count("fireball") - 1
		if sprite.frame == last:
			shoot_fireball()
			is_attacking = false

func _on_Hitbox_body_entered(body: Node) -> void:
	if is_invincible:
		return
	if body.is_in_group("Mobs"):
		take_damage(10)

func take_damage(amount: int) -> void:
	if is_invincible:
		return

	health = clamp(health - amount, 0, max_health)
	emit_signal("hit", health)
	var hb = get_node_or_null("/root/Main/HUD/HealthBar")
	if hb:
		hb.health = health
	else:
		push_warning("HealthBar node not found!")

	if health == 0:
		if get_parent().has_method("game_over"):
			get_parent().game_over()
		else:
			push_error("Parent has no game_over()!")
		return

	is_invincible = true
	$AnimatedSprite2D.modulate.a = 0.3
	await get_tree().create_timer(2.0).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0

func start(pos: Vector2):
	position = pos
	show()
	$CollisionShape2D.disabled = false
