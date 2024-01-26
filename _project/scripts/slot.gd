class_name Slot
extends Node3D

var _obj: Node3D


func is_occupied() -> bool:
	return _obj != null


## Get the object in the slot without altering anything
func peek() -> Node3D:
	return _obj


## Put a [param obj] inside the slot and occupy the space.[br]
## Also resets the [param obj] position and rotation
func put(obj: Node3D) -> void:
	assert(obj != null, "The object that you attempted to put is null.")
	assert(_obj == null, "Slot is occupied but attempted to put %s to it." % obj.name)

	var last_parent = obj.get_parent()
	if last_parent:
		last_parent.remove_child(obj)

	add_child(obj)
	_obj = obj

	_obj.position = Vector3.ZERO
	_obj.rotation = Vector3.ZERO


## Be careful that this does not queue free the object
func reset() -> void:
	_obj = null


## [param new_parent] if not null, will automatically parent obj to this
func take(new_parent: Node3D = null) -> Node3D:
	assert(_obj != null, "Slot is empty but attempted to take the object")

	var obj = _obj
	_obj = null
	remove_child(obj)

	if new_parent != null:
		new_parent.add_child(obj)

	return obj
