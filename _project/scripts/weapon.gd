class_name Weapon
extends Area3D

signal durability_depleted
signal on_activate_hurtbox

enum Damage { LIGHT, HEAVY }

@export var _collision_shape: CollisionShape3D
@export var _audio_stream_player: AudioStreamPlayer
var light_damage: float
var heavy_damage: float
var current_damage_type: Damage
var get_owner_node: Callable
var current_durability: float


func _ready() -> void:
	body_entered.connect(_on_hitbox_enter)


func _process(delta: float) -> void:
	current_durability -= delta
	if current_durability <= 0:
		durability_depleted.emit()


func activate_hurtbox() -> void:
	_collision_shape.disabled = false
	on_activate_hurtbox.emit()


func deactivate_hurtbox() -> void:
	_collision_shape.disabled = true


func _on_hitbox_enter(body: Node3D) -> void:
	if !(body is CharacterController):
		return

	var owner_node: Node3D = get_owner_node.call()
	if owner_node == body:
		return

	var character: CharacterController = body as CharacterController
	var direction: Vector3 = body.global_position - owner_node.global_position
	direction = direction.normalized()
	direction.y = 1
	direction = direction.normalized()

	match current_damage_type:
		Damage.LIGHT:
			character.take_damage.call(light_damage, direction)
		Damage.HEAVY:
			character.take_damage.call(heavy_damage, direction)

	_audio_stream_player.play()
