extends ProgressBar

@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

# whenever you assign to `health`, _set_health() will run
var health: int = 0 : set = _set_health

#func _ready() -> void:

func init_health(_health: int) -> void:
	health = _health
	max_value = _health
	value = _health
	damage_bar.max_value = _health
	damage_bar.value = _health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	# update the main bar immediately…
	value = health

	if health <= 0:
		queue_free()

	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health

func _on_timer_timeout() -> void:
	# when the timer fires, snap the damage bar to the new health
	damage_bar.value = health
