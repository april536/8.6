extends Button

@export var base_damage = 30.0
@export var rpm = 300.0
@export var mag_size = 30
@export var reload_time = 3.05
@export var crit_chance = 0.05
@onready var label = $Label

func _ready() -> void:
	label.text = "RPM: %d | DMG: %d | Mag: %d | DPS: %.2f" % [rpm, base_damage, mag_size, get_dps()]
	

func get_dps() -> float:
	var shots_per_sec = rpm / 60.0
	var fire_duration = mag_size / shots_per_sec
	var total_dmg = base_damage * mag_size * (1.0 + crit_chance)
	var cycle_time = fire_duration + reload_time
	return total_dmg / cycle_time
