extends Node
class_name Game

@export var enemy_path: NodePath
@export var weapons_container_path: NodePath  # 放所有武器按钮的父节点（UI里一个VBox之类）

@onready var enemy: Enemy = get_node(enemy_path) as Enemy
@onready var weapons_container: Node = get_node(weapons_container_path)

func _ready() -> void:
	# 自动把容器下所有 WeaponButton 连接到 enemy.apply_damage
	for child in weapons_container.get_children():
		if child is WeaponButton:
			var btn := child as WeaponButton
			if not btn.deal_damage.is_connected(_on_weapon_deal_damage):
				btn.deal_damage.connect(_on_weapon_deal_damage)

func _on_weapon_deal_damage(dmg: float) -> void:
	enemy.apply_damage(dmg)
