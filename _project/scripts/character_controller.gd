class_name CharacterController
extends RigidBody3D

signal die

@export var _model: Node3D
@export var _speed: float = 5
@export var _weapon_detection_area: Area3D
@export var _weapon_detection_shape: CollisionShape3D
@export var _animation_tree: AnimationTree
@export var _weapon_slot: Slot

var take_damage: Callable

var _movement_vec: Vector3
var _pickupable_weapons: Array[PickupableWeapon]
var _highlighted_pickupable: PickupableWeapon
var _weapon: Weapon


func _ready() -> void:
	_model.top_level = true
	_weapon_detection_area.body_entered.connect(_on_body_enter_detection)
	_weapon_detection_area.body_exited.connect(_on_body_exit_detection)


func _physics_process(delta: float) -> void:
	var force: Vector3 = _movement_vec * delta * _speed
	apply_central_force(force)

	if global_position.y <= -15:
		die.emit()
		return

	_highlight_shortest_pickupable()


func destroy_weapon() -> void:
	if _weapon == null:
		return

	_weapon.queue_free()
	_weapon = null


func has_pickupable() -> bool:
	return _highlighted_pickupable != null


func pickup() -> void:
	var id: StringName = _highlighted_pickupable.id
	var weapon_resource: WeaponResource = Data.weapon_library.get_weapon_with_id(id)
	var weapon: Weapon = weapon_resource.prefab.instantiate() as Weapon
	weapon.light_damage = weapon_resource.light_damage
	weapon.heavy_damage = weapon_resource.heavy_damage
	weapon.current_durability = weapon_resource.durability
	weapon.durability_depleted.connect(destroy_weapon)
	weapon.get_owner_node = func() -> Node3D: return self
	_weapon_slot.put(weapon)
	_weapon = weapon

	_highlighted_pickupable.queue_free()


## [param vec] expects to already be rotated according to the camera
func set_movement_vec(vec: Vector3) -> void:
	_movement_vec = vec


func trigger_light_attack() -> void:
	if _weapon == null:
		return

	_weapon.current_damage_type = Weapon.Damage.LIGHT
	_animation_tree.set("parameters/attack_state/transition_request", "light")
	_animation_tree.set("parameters/o_attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func trigger_heavy_attack() -> void:
	if _weapon == null:
		return

	_weapon.current_damage_type = Weapon.Damage.HEAVY
	_animation_tree.set("parameters/attack_state/transition_request", "heavy")
	_animation_tree.set("parameters/o_attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _highlight_shortest_pickupable() -> void:
	if _weapon != null:
		return

	if _pickupable_weapons.size() <= 0:
		return

	var shortest: int = -1
	var distance: float = pow(_weapon_detection_shape.shape.radius + 1, 2)
	for i in range(_pickupable_weapons.size()):
		var pickupable_weapon: PickupableWeapon = _pickupable_weapons[i]
		var dist: float = global_position.distance_squared_to(pickupable_weapon.global_position)
		if dist < distance:
			shortest = i
			distance = dist

	if _highlighted_pickupable != null:
		_highlighted_pickupable.set_highlight(false)

	_highlighted_pickupable = _pickupable_weapons[shortest]
	_highlighted_pickupable.set_highlight(true)


func _on_body_enter_detection(body: Node3D) -> void:
	if !(body is PickupableWeapon):
		return

	var pickupable_weapon: PickupableWeapon = body as PickupableWeapon
	_pickupable_weapons.append(pickupable_weapon)


func _on_body_exit_detection(body: Node3D) -> void:
	if !(body is PickupableWeapon):
		return

	var pickupable: PickupableWeapon = body as PickupableWeapon
	pickupable.set_highlight(false)
	_pickupable_weapons.erase(pickupable)


func _activate_weapon_hurtbox() -> void:
	if _weapon == null:
		return

	_weapon.activate_hurtbox()


func _deactivate_weapon_hurtbox() -> void:
	if _weapon == null:
		return

	_weapon.deactivate_hurtbox()
