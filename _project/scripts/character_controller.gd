class_name CharacterController
extends RigidBody3D

@export var _model: Node3D
@export var _speed: float = 5

var _movement_vec: Vector3


func _ready() -> void:
	_model.top_level = true


func _physics_process(delta: float) -> void:
	var force: Vector3 = _movement_vec * delta * _speed
	apply_central_force(force)


## [param vec] expects to already be rotated according to the camera
func set_movement_vec(vec: Vector3) -> void:
	_movement_vec = vec
