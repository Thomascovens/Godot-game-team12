extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed := 200
@export var run_speed := 400
@export var max_health: int = 100
@export var projectile_scene: PackedScene = preload("res://scenes/Characters/projectiles/fireball.tscn")
@export var projectile_offset: Vector2 = Vector2(0, -30)

var health: int
var is_attacking: bool = false
var is_invincible: bool = false
var map_bounds_rect: Rect2

func _ready():
	health = max_health
	$AnimatedSprite2D.frame_changed.connect(Callable(self, "_on_frame_changed"))
	
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	
	var shape = get_node("../Mapbounds/Shape")
	if shape is CollisionShape2D and shape.shape is RectangleShape2D:
		var rect_shape = shape.shape as RectangleShape2D
		var center = shape.global_position
		var size = rect_shape.extents * 2
		map_bounds_rect = Rect2(center - rect_shape.extents, size)
	else:
		push_error("Mapbounds/Shape must be a RectangleShape2D!")

func _process(delta):
	handle_input(delta)
	handle_animation()

func handle_input(delta):
	if is_attacking:
		return

	var dir := Vector2.ZERO

	if Input.is_action_pressed("walk_right"): dir.x += 1
	if Input.is_action_pressed("walk_left"):  dir.x -= 1
	if Input.is_action_pressed("walk_down"):  dir.y += 1
	if Input.is_action_pressed("walk_up"):    dir.y -= 1

	var is_running := Input.is_action_pressed("run")

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		var speed = run_speed if is_running else walk_speed
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO

	position += velocity * delta

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		var aim_direction = (get_global_mouse_position() - global_position).normalized()
		$AnimatedSprite2D.flip_h = aim_direction.x < 0
		$AnimatedSprite2D.play("attack")


func handle_animation():
	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.animation = "run" if velocity.length() > walk_speed else "walk"
		$AnimatedSprite2D.flip_h = velocity.x < 0
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.animation = "idle"
	
	$AnimatedSprite2D.flip_h = velocity.x < 0
	$AnimatedSprite2D.flip_v = false
	$AnimatedSprite2D.play()

func shoot_fireball():
	var proj = projectile_scene.instantiate()
	var dir = (get_global_mouse_position() - global_position).normalized()

	# sprite flippen op basis van richtingsvector
	$AnimatedSprite2D.flip_h = dir.x < 0

	# positie van de pijl
	var offset = projectile_offset
	if $AnimatedSprite2D.flip_h:
		offset.x *= -1

	proj.global_position = global_position + offset
	proj.velocity = dir * proj.speed
	proj.rotation = dir.angle()

	get_tree().get_current_scene().add_child(proj)

func _on_frame_changed():
	match $AnimatedSprite2D.animation:
		"attack":
			var last = $AnimatedSprite2D.sprite_frames.get_frame_count("attack") - 1
			if $AnimatedSprite2D.frame == last:
				shoot_fireball()
				is_attacking = false
		"death":
			var last = $AnimatedSprite2D.sprite_frames.get_frame_count("death") - 1
			if $AnimatedSprite2D.frame == last:
				queue_free()

func _on_Hitbox_body_entered(body: Node):
	if is_invincible:
		return
	if body.is_in_group("Mobs"):
		take_damage(10)

func take_damage(amount: int):
	if is_invincible:
		return

	health = clamp(health - amount, 0, max_health)
	emit_signal("hit", health)

	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.health = health

	if health == 0:
		die()
		if get_parent().has_method("game_over"):
			get_parent().game_over()

	is_invincible = true
	$AnimatedSprite2D.modulate.a = 0.3
	await get_tree().create_timer(2.0).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0

func start(pos: Vector2):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	
func die():
	is_attacking = false
	is_invincible = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	$AnimatedSprite2D.sprite_frames.set_animation_loop("death", false)
	$AnimatedSprite2D.play("death")
