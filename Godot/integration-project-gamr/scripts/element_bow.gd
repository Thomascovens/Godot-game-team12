extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed := 180
@export var run_speed := 300
@export var max_health: int = 100
@export var projectile_scene: PackedScene = preload("res://scenes/Characters/projectiles/arrow.tscn")
@export var projectile_offset: Vector2 = Vector2(0, -30)

var health: int
var is_attacking := false
var is_invincible := false
var map_bounds_rect: Rect2

func _ready():
	health = max_health
	if not $AnimatedSprite2D.animation_finished.is_connected(Callable(self, "_on_animation_finished")):
		$AnimatedSprite2D.animation_finished.connect(Callable(self, "_on_animation_finished"))
	if not $AnimatedSprite2D.frame_changed.is_connected(Callable(self, "_on_frame_changed")):
		$AnimatedSprite2D.frame_changed.connect(Callable(self, "_on_frame_changed"))

func _process(delta):
	handle_input(delta)
	handle_animation()

func handle_input(_delta):
	if is_attacking:
		return

	var dir := Vector2.ZERO
	if Input.is_action_pressed("walk_right"): dir.x += 1
	if Input.is_action_pressed("walk_left"):  dir.x -= 1
	if Input.is_action_pressed("walk_down"):  dir.y += 1
	if Input.is_action_pressed("walk_up"):    dir.y -= 1

	var is_running := Input.is_action_pressed("run")
	velocity = Vector2.ZERO
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		var speed = run_speed if is_running else walk_speed
		velocity = dir * speed

	# Instead of move_and_slide, use move_and_collide
	var collision := move_and_collide(velocity * _delta)
	if collision:
		var body := collision.get_collider() as RigidBody2D
		if body:
			var push_force = velocity.normalized() * 1000
			body.apply_central_force(push_force)



		
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

func fire_arrow():
	var arrow = projectile_scene.instantiate()
	var aim_direction = (get_global_mouse_position() - global_position).normalized()
	
	# positie van de pijl
	var offset = projectile_offset
	if $AnimatedSprite2D.flip_h:
		offset.x *= -1

	arrow.global_position = global_position + offset
	arrow.velocity = aim_direction * arrow.speed
	arrow.rotation = aim_direction.angle()

	get_tree().get_current_scene().add_child(arrow)

func _on_animation_finished():
	match $AnimatedSprite2D.animation:
		"attack":
			is_attacking = false
		"death":
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
	show()
	$CollisionShape2D.disabled = true
	set_deferred("global_position", pos)
	await get_tree().process_frame
	$CollisionShape2D.disabled = false


	
func _on_frame_changed():
	if $AnimatedSprite2D.animation == "attack":
		var impact_frame = 3  # pas aan op basis van je animatie
		if $AnimatedSprite2D.frame == impact_frame:
			fire_arrow()
			
func die():
	is_invincible = true
	is_attacking = false
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	$AnimatedSprite2D.sprite_frames.set_animation_loop("death", false)
	$AnimatedSprite2D.play("death")
