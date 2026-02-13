extends Node
class_name Enemy

@export var max_hp: float = 10000.0
var hp: float

# UI 节点路径（在 Inspector 里拖拽赋值）
@export var health_bar_path: NodePath
@export var hp_label_path: NodePath

@onready var health_bar: ProgressBar = get_node(health_bar_path) as ProgressBar
@onready var hp_label: Label = get_node(hp_label_path) as Label

func _ready() -> void:
	hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = hp
	_update_hp_ui()

func apply_damage(dmg: float) -> void:
	if hp <= 0.0:
		return

	hp = maxf(0.0, hp - dmg)
	health_bar.value = hp
	_update_hp_ui()

	# 可选：死了以后做点事
	# if hp <= 0.0:
	#     print("Enemy down")

func _update_hp_ui() -> void:
	hp_label.text = "HP: %d / %d" % [int(hp), int(max_hp)]
