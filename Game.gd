extends Node
class_name Game

@export var enemy_path: NodePath
@export var weapons_container_path: NodePath

@onready var enemy: Enemy = get_node_or_null(enemy_path) as Enemy
@onready var weapons_container: Node = get_node_or_null(weapons_container_path)

var _weapon_buttons: Array[WeaponButton] = []
var _active_weapon: WeaponButton = null

func _ready() -> void:
	_cache_and_connect_weapon_buttons()

	if enemy and not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)

func _cache_and_connect_weapon_buttons() -> void:
	_weapon_buttons.clear()
	if weapons_container == null:
		push_error("weapons_container_path is invalid.")
		return

	_collect_weapon_buttons_recursive(weapons_container)

	for btn in _weapon_buttons:
		if not btn.deal_damage.is_connected(_on_weapon_deal_damage):
			btn.deal_damage.connect(_on_weapon_deal_damage)

		if not btn.pressed.is_connected(_on_weapon_pressed):
			btn.pressed.connect(_on_weapon_pressed.bind(btn))

func _collect_weapon_buttons_recursive(node: Node) -> void:
	for c in node.get_children():
		if c is WeaponButton:
			_weapon_buttons.append(c as WeaponButton)
		_collect_weapon_buttons_recursive(c)

func _on_weapon_pressed(btn: WeaponButton) -> void:
	for b in _weapon_buttons:
		if b and b != btn:
			b.stop_auto_fire()

	if enemy:
		enemy.reset_to_max_health()

	_active_weapon = btn

func _on_weapon_deal_damage(dmg: float) -> void:
	if enemy == null:
		return
	if enemy.hp <= 0.0:
		_stop_all_weapons()
		return

	enemy.apply_damage(dmg)

	if enemy.hp <= 0.0:
		_stop_all_weapons()

func _on_enemy_died() -> void:
	_stop_all_weapons()

func _stop_all_weapons() -> void:
	for btn in _weapon_buttons:
		if btn:
			btn.stop_auto_fire()
