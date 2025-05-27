extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed := 200
@export var run_speed := 400
@export var max_health: int = 100
@export var projectile_scene: PackedScene
@export var projectile_offset: Vector2 = Vector2.ZERO

var health: int
var is_attacking: bool = false
var is_invincible: bool = false
var map_bounds_rect: Rect2

func _ready():
	health = max_health
	$AnimatedSprite2D.frame_changed.connect(Callable(self, "_on_frame_changed"))

	# Calculate map bounds from Mapbounds/Shape (must be RectangleShape2D)
	var shape = get_node("../Mapbounds/Shape")
	if shape is CollisionShape2D and shape.shape is RectangleShape2D:
		var rect_shape = shape.shape as RectangleShape2D
		var center = shape.global_position
		var size = rect_shape.extents * 2
		map_bounds_rect = Rect2(center - rect_shape.extents, size)
	else:
		push_error("Mapbounds/Shape must be a RectangleShape2D!")

func _physics_process(_delta):
	# 1) Start attack if just pressed (fires once)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		$AnimatedSprite2D.play("fireball")

	# 2) Gather movement input
	var dir := Vector2.ZERO
	var is_running := false

	if Input.is_action_pressed("walk_right"):
		dir.x += 1
	if Input.is_action_pressed("walk_left"):
		dir.x -= 1
	if Input.is_action_pressed("walk_down"):
		dir.y += 1
	if Input.is_action_pressed("walk_up"):
		dir.y -= 1

	if Input.is_action_pressed("run_right"):
		dir.x += 1
		is_running = true
	if Input.is_action_pressed("run_left"):
		dir.x -= 1
		is_running = true
	if Input.is_action_pressed("run_down"):
		dir.y += 1
		is_running = true
	if Input.is_action_pressed("run_up"):
		dir.y -= 1
		is_running = true

	# 3) Apply movement using move_and_slide (handles collisions)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		var speed = run_speed if is_running else walk_speed
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Clamp position to map bounds (ignores collisions beyond bounds)
	global_position.x = clamp(global_position.x, map_bounds_rect.position.x, map_bounds_rect.position.x + map_bounds_rect.size.x)
	global_position.y = clamp(global_position.y, map_bounds_rect.position.y, map_bounds_rect.position.y + map_bounds_rect.size.y)

	# 4) Sprite animation only if NOT attacking
	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.animation = "run" if is_running else "walk"
		$AnimatedSprite2D.flip_h = dir.x < 0
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

func shoot_fireball() -> void:
	var proj = projectile_scene.instantiate() as Area2D
	proj.global_position = global_position + projectile_offset

	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - proj.global_position).normalized()

	proj.velocity = dir * proj.speed
	proj.rotation = dir.angle()

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

	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.health = health
	else:
		push_warning("HealthBar node not found! Skipping health UI update.")

	if health == 0:
		var parent = get_parent()
		if parent and parent.has_method("game_over"):
			parent.game_over()
		else:
			push_error("Parent node has no 'game_over' method!")
		return

	# Start 2 sec invincibility
	is_invincible = true
	$AnimatedSprite2D.modulate.a = 0.3
	await get_tree().create_timer(2.0).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
