extends Area2D

@export var speed: float = 500.0
var velocity: Vector2 = Vector2.ZERO
var impacted := false

func _ready() -> void:
	# start de vlieg-animatie
	$AnimatedSprite2D.play("fly")

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
		if body.has_method("take_damage"):
			body.take_damage(30)
		elif body.has_method("die"):
			body.die()
		else:
			body.queue_free()

		var main = get_tree().get_current_scene()
		if main.has_method("increment_score"):
			main.increment_score()

		call_deferred("_trigger_impact")

func _trigger_impact() -> void:
	impacted = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	# impactanimatie instellen
	$AnimatedSprite2D.sprite_frames.set_animation_loop("impact", false)
	$AnimatedSprite2D.play("impact")

func _on_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "impact":
		queue_free()
