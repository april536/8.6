extends Button
class_name WeaponButton

signal deal_damage(damage: float)

@export var base_damage: float = 60.0
@export var rpm: float = 10.0
@export var mag_size: int = 10
@export var reload_time: float = 2.1
@export var crit_chance: float = 0.55
@export var max_queue: int = 2 # 冷却期间最多缓冲几次点击

@onready var label: Label = $Label

var _shots_left: int
var _is_holding := false
var _is_reloading := false

var _fire_timer: Timer        # 作为“冷却/下一发允许”的计时器
var _reload_timer: Timer

var _queued_shots: int = 0    # 冷却期间的点击缓冲

func _ready() -> void:
	randomize()
	_shots_left = mag_size

	_fire_timer = Timer.new()
	_fire_timer.one_shot = true
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_on_fire_ready)

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

	if _is_reloading:
		return

	if _shots_left <= 0:
		_start_reload()
		return

	# 冷却结束：立刻打一发并进入冷却
	if _fire_timer.is_stopped():
		_fire_one_and_start_cooldown()
	else:
		# 冷却中：把这次单点缓冲起来，等冷却到了再打（不会超速）
		_queued_shots = min(_queued_shots + 1, max_queue)

func _on_button_up() -> void:
	_is_holding = false
	# 关键：不要 stop _fire_timer
	# 也不要清空 _queued_shots（否则单点缓冲就没了）

func _on_mouse_exited() -> void:
	_is_holding = false
	# 同样不要 stop _fire_timer

func _on_fire_ready() -> void:
	# 冷却到点后：
	# 1) 还在按住 -> 连射继续
	# 2) 没按住但有排队点击 -> 也打一发（实现“单点也遵循 fire rate”）
	if _is_reloading:
		return

	if _shots_left <= 0:
		_start_reload()
		return

	var should_fire := _is_holding or _queued_shots > 0
	if not should_fire:
		return

	if _queued_shots > 0:
		_queued_shots -= 1

	_fire_one_and_start_cooldown()

func _fire_one_and_start_cooldown() -> void:
	if _is_reloading:
		return

	if _shots_left <= 0:
		_start_reload()
		return

	# 开火
	_shots_left -= 1
	deal_damage.emit(_roll_damage_one_shot())
	_update_weapon_label()

	# 打空自动换弹
	if _shots_left <= 0:
		_start_reload()
		return

	# 进入冷却：严格按 RPM
	_fire_timer.wait_time = _shot_interval()
	_fire_timer.start()

func _start_reload() -> void:
	if _is_reloading:
		return
	_is_reloading = true

	# 可选：换弹时清空缓冲，避免“欠账”
	_queued_shots = 0

	_reload_timer.wait_time = reload_time
	_reload_timer.start()
	_update_weapon_label()

func _finish_reload() -> void:
	_is_reloading = false
	_shots_left = mag_size
	_update_weapon_label()

	# 换完弹：如果还在按住，且当前不在冷却，就立刻打一发进入冷却
	if _is_holding and _fire_timer.is_stopped():
		_fire_one_and_start_cooldown()

func _shot_interval() -> float:
	if rpm <= 0.0:
		return 9999.0
	return 60.0 / rpm

func _roll_damage_one_shot() -> float:
	var is_crit := randf() < crit_chance
	return base_damage * (2.0 if is_crit else 1.0)

func _update_weapon_label() -> void:
	var state := ""
	if _is_reloading:
		state = " | Reloading..."
	else:
		state = " | Ammo: %d/%d" % [_shots_left, mag_size]

	label.text = "RPM: %.0f | DMG: %.0f | Mag: %d%s" % [rpm, base_damage, mag_size, state]
