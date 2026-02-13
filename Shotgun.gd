extends Button
class_name Shotgun

signal deal_damage(damage: float)

@export var base_damage: float = 225.0
@export var rpm: float = 50.0
@export var mag_size: int = 5
@export var reload_time: float = 4.4
@export var crit_chance: float = 0.2

@onready var label: Label = $Label

var _shots_left: int
var _is_holding := false
var _is_reloading := false

var _fire_timer: Timer
var _reload_timer: Timer

func _ready() -> void:
	randomize()
	_shots_left = mag_size

	_fire_timer = Timer.new()
	_fire_timer.one_shot = true  # 关键：每发都“精确排下一发”
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_on_fire_tick)

	_reload_timer = Timer.new()
	_reload_timer.one_shot = true
	add_child(_reload_timer)
	_reload_timer.timeout.connect(_finish_reload)

	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_exited.connect(_on_mouse_exited)

	_update_weapon_label()

func _on_button_down() -> void:
	_is_holding = true
	_try_start_or_resume()

func _on_button_up() -> void:
	_is_holding = false
	_cancel_fire_timer()

func _on_mouse_exited() -> void:
	# 不想移出就停：删掉这两行即可
	_is_holding = false
	_cancel_fire_timer()

func _try_start_or_resume() -> void:
	if _is_reloading:
		return

	if _shots_left <= 0:
		_start_reload()
		return

	# 如果已经在“等下一发”，不要重复启动（避免超速）
	if not _fire_timer.is_stopped():
		return

	# 立刻打一发，然后严格按 RPM 安排下一发
	_fire_once_and_schedule_next()

func _on_fire_tick() -> void:
	# 到点了打一发（仍然保证间隔 = 60/rpm）
	_fire_once_and_schedule_next()

func _fire_once_and_schedule_next() -> void:
	if not _is_holding or _is_reloading:
		_cancel_fire_timer()
		return

	if _shots_left <= 0:
		_cancel_fire_timer()
		_start_reload()
		return

	# 开火
	_shots_left -= 1
	deal_damage.emit(_roll_damage_one_shot())
	_update_weapon_label()

	# 打空自动换弹
	if _shots_left <= 0:
		_cancel_fire_timer()
		_start_reload()
		return

	# 严格按 RPM 排下一发
	_fire_timer.wait_time = _shot_interval()
	_fire_timer.start()

func _start_reload() -> void:
	if _is_reloading:
		return
	_is_reloading = true
	_cancel_fire_timer()

	_reload_timer.wait_time = reload_time
	_reload_timer.start()
	_update_weapon_label()

func _finish_reload() -> void:
	_is_reloading = false
	_shots_left = mag_size
	_update_weapon_label()

	# 还在按住就继续（仍然严格 RPM）
	if _is_holding:
		_try_start_or_resume()

func _cancel_fire_timer() -> void:
	if _fire_timer and not _fire_timer.is_stopped():
		_fire_timer.stop()

func _shot_interval() -> float:
	# 每发间隔（秒）
	if rpm <= 0.0:
		return 9999.0
	return 60.0 / rpm

func _roll_damage_one_shot() -> float:
	# 简单暴击：2x
	var is_crit := randf() < crit_chance
	return base_damage * (2.0 if is_crit else 1.0)

func _update_weapon_label() -> void:
	var state := ""
	if _is_reloading:
		state = " | Reloading..."
	else:
		state = " | Ammo: %d/%d" % [_shots_left, mag_size]

	label.text = "RPM: %.0f | DMG: %.0f | Mag: %d%s" % [
		rpm, base_damage, mag_size, state
	]
