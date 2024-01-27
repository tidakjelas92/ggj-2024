class_name PickupableWeapon
extends RigidBody3D

static var outline_material: Material = preload("res://_project/materials/outline.tres")

@export var _meshes: Array[GeometryInstance3D]
var id: StringName


func set_highlight(enabled: bool) -> void:
	for i in range(_meshes.size()):
		_meshes[i].material_overlay = outline_material if enabled else null
