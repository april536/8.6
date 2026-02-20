extends Button
class_name WeaponButton

signal deal_damage(damage: float)
signal auto_fire_changed(is_on: bool)

@export var base_damage: float = 60.0
@export var rpm: float = 10.0
@export var mag_size: int = 10
@export var reload_time: float = 2.1
@export var crit_chance: float = 0.55

@onready var label: Label = get_node_or_null("Label") as Label

var _shots_left: int
var _is_reloading := false
var _auto_fire := false

var _fire_timer: Timer
var _reload_timer: Timer

func _ready() -> void:
	randomize()
	_shots_left = mag_size

	_fire_timer = Timer.new()
	_fire_timer.one_shot = true
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_on_fire_timer_timeout)

	_reload_timer = Timer.new()
	_reload_timer.one_shot = true
	add_child(_reload_timer)
	_reload_timer.timeout.connect(_finish_reload)

	pressed.connect(_toggle_auto_fire)

	_update_weapon_label()

func _toggle_auto_fire() -> void:
	_auto_fire = not _auto_fire
	auto_fire_changed.emit(_auto_fire)

	if _auto_fire:
		# 关键：延迟到本帧末尾，确保 Game 的 _on_weapon_pressed 先把血回满
		call_deferred("_try_fire_now_or_schedule")
	else:
		_stop_fire_timer()

	_update_weapon_label()

func stop_auto_fire() -> void:
	_auto_fire = false
	auto_fire_changed.emit(false)
	_stop_fire_timer()
	_update_weapon_label()

func _try_fire_now_or_schedule() -> void:
	if not _auto_fire:
		return
	if _is_reloading:
		return
	if _shots_left <= 0:
		_start_reload()
		return
	if _fire_timer.is_stopped():
		_fire_one_and_start_cooldown()

func _on_fire_timer_timeout() -> void:
	if not _auto_fire:
		return
	if _is_reloading:
		return
	if _shots_left <= 0:
		_start_reload()
		return
	_fire_one_and_start_cooldown()

func _fire_one_and_start_cooldown() -> void:
	if _is_reloading or not _auto_fire:
		return
	if _shots_left <= 0:
		_start_reload()
		return

	_shots_left -= 1
	deal_damage.emit(_roll_damage_one_shot())
	_update_weapon_label()

	if _shots_left <= 0:
		_start_reload()
		return

	_fire_timer.wait_time = _shot_interval()
	_fire_timer.start()

func _start_reload() -> void:
	if _is_reloading:
		return
	_is_reloading = true
	_stop_fire_timer()

	_reload_timer.wait_time = reload_time
	_reload_timer.start()
	_update_weapon_label()

func _finish_reload() -> void:
	_is_reloading = false
	_shots_left = mag_size
	_update_weapon_label()
	if _auto_fire:
		_try_fire_now_or_schedule()

func _stop_fire_timer() -> void:
	if not _fire_timer.is_stopped():
		_fire_timer.stop()

func _shot_interval() -> float:
	if rpm <= 0.0:
		return 9999.0
	return 60.0 / rpm

func _roll_damage_one_shot() -> float:
	var is_crit := randf() < crit_chance
	return base_damage * (2.0 if is_crit else 1.0)

func _update_weapon_label() -> void:
	if label == null:
		return

	var state := ""
	if _is_reloading:
		state = " | Reloading..."
	else:
		state = " | Ammo: %d/%d" % [_shots_left, mag_size]

	var firing := "ON" if _auto_fire else "OFF"
	label.text = "Auto: %s | RPM: %.0f | DMG: %.0f | Mag: %d%s" % [firing, rpm, base_damage, mag_size, state]
