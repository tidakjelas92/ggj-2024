class_name SmoothFollow3D
extends Node
## Fix the jittery movement caused by physics and graphics not updating in sync by
## lerp-ing the [member _target] towards where the [member _source] object should be.[br]

@export var _source: Node3D
@export var _lerp_speed: float = 1
var _target: Node3D


func _ready() -> void:
	_target = get_parent() as Node3D
	assert(_target != null, "Must be a child of type Node3D")


func _process(delta: float) -> void:
	if _target == null || _source == null:
		return

	var t: float = clampf(delta * _lerp_speed, 0, 1)
	_target.global_transform = _target.global_transform.interpolate_with(
		_source.global_transform, t
	)
