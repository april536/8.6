extends Node
class_name Enemy

signal died
signal hp_changed(hp: float, max_hp: float)

@export var max_hp: float = 10000.0
var hp: float

@export var health_bar_path: NodePath
@export var hp_label_path: NodePath
@export var hp_input_path: NodePath

@onready var health_bar: ProgressBar = get_node_or_null(health_bar_path) as ProgressBar
@onready var hp_label: Label = get_node_or_null(hp_label_path) as Label
@onready var hp_input: LineEdit = get_node_or_null(hp_input_path) as LineEdit

var _dead := false

func _ready() -> void:
	hp = max_hp
	_dead = false
	_refresh_hp_ui()

	if hp_input:
		hp_input.text_submitted.connect(_on_hp_input_submitted)

func apply_damage(dmg: float) -> void:
	if _dead:
		return

	hp = maxf(0.0, hp - dmg)
	_refresh_hp_ui()

	if hp <= 0.0:
		_die()

func set_enemy_health(value: float) -> void:
	value = maxf(0.0, value)
	max_hp = maxf(1.0, value) # 让 ProgressBar 不炸
	hp = value
	_dead = false
	_refresh_hp_ui()

	if hp <= 0.0:
		_die()

# ✅ Game.gd 需要的函数：回满血并复活
func reset_to_max_health() -> void:
	_dead = false
	hp = max_hp
	_refresh_hp_ui()

func _die() -> void:
	if _dead:
		return
	_dead = true
	hp = 0.0
	_refresh_hp_ui()
	died.emit()

func _on_hp_input_submitted(text: String) -> void:
	var s := text.strip_edges()
	if s.is_empty():
		return
	if not _is_number(s):
		print("Invalid number: ", s)
		return

	var new_hp := s.to_float()
	if new_hp < 0.0:
		print("HP must be >= 0")
		return

	set_enemy_health(new_hp)
	if hp_input:
		hp_input.clear()

func _refresh_hp_ui() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(hp), int(max_hp)]

	hp_changed.emit(hp, max_hp)

func _is_number(s: String) -> bool:
	var has_digit := false
	for i in s.length():
		var c := s[i]
		if c >= "0" and c <= "9":
			has_digit = true
			continue
		if c == ".":
			continue
		return false
	return has_digit
