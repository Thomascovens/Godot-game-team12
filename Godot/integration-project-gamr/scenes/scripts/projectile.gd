extends Area2D
class_name Projectile

@export var speed: float = 500.0
var velocity: Vector2 = Vector2.ZERO
var impacted := false

func _ready() -> void:
	$VisibilityNotifier2D.screen_exited.connect(Callable(self, "queue_free"))
	body_entered.connect(Callable(self, "_on_body_entered"))
	$AnimatedSprite2D.animation_finished.connect(Callable(self, "_on_animation_finished"))

func _physics_process(delta: float) -> void:
	if not impacted:
		position += velocity * delta

func _on_body_entered(body: Node) -> void:
	if impacted:
		return
	if body.is_in_group("Mobs"):
		# so mob can take damage or die
		if body.has_method("take_damage"):
			body.take_damage(30)   
		elif body.has_method("die"):
			body.die()
		else:
			body.queue_free()       # fallback

		var main = get_tree().get_current_scene()
		main.increment_score()

		call_deferred("_trigger_impact")


func _trigger_impact() -> void:
	impacted = true
	velocity = Vector2.ZERO
	# disable collision shape after physics step
	$CollisionShape2D.set_deferred("disabled", true)
	# ensure the impact animation does NOT loop
	$AnimatedSprite2D.sprite_frames.set_animation_loop("fireball_on_impact", false)
	$AnimatedSprite2D.play("fireball_on_impact")

# Godot 4's AnimatedSprite2D.animation_finished emits NO args
func _on_animation_finished() -> void:
	# once the impact clip ends, destroy us
	queue_free()
	

func _on_screen_exited() -> void:
	queue_free()
