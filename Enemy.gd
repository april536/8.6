extends Node
class_name Enemy

@export var max_hp: float = 10000.0
var hp: float

# 在 Inspector 里拖拽赋值（指向 Enemy 的子节点）
@export var health_bar_path: NodePath
@export var hp_label_path: NodePath
@export var hp_input_path: NodePath

@onready var health_bar: ProgressBar = get_node(health_bar_path) as ProgressBar
@onready var hp_label: Label = get_node(hp_label_path) as Label
@onready var hp_input: LineEdit = get_node(hp_input_path) as LineEdit


func _ready() -> void:
	# init hp
	hp = max_hp
	_refresh_hp_ui()

	# 监听输入框回车提交
	if hp_input:
		hp_input.text_submitted.connect(_on_hp_input_submitted)


# 你的原有扣血逻辑（保持一致）
func apply_damage(dmg: float) -> void:
	if hp <= 0.0:
		return

	hp = maxf(0.0, hp - dmg)
	_refresh_hp_ui()

	# 可选：死了以后做点事
	# if hp <= 0.0:
	#     print("Enemy down")


# ✅ 外部/输入框调用：直接设置当前 enemy 的血量（同时改 max_hp）
func set_enemy_health(value: float) -> void:
	value = maxf(1.0, value) # 避免 0 或负数
	max_hp = value
	hp = max_hp
	_refresh_hp_ui()


# 输入框回车触发：把输入数字应用到敌人血量
func _on_hp_input_submitted(text: String) -> void:
	var s := text.strip_edges()
	if s.is_empty():
		return

	if not _is_number(s):
		print("Invalid number: ", s)
		return

	var new_hp := s.to_float()
	if new_hp <= 0.0:
		print("HP must be > 0")
		return

	set_enemy_health(new_hp)
	hp_input.clear()


# 刷新血条 + 文字
func _refresh_hp_ui() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(hp), int(max_hp)]


# 简单数字校验：允许 123 / 12.5 / .5 / 0.25
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
