class_name WeaponLibrary
extends Resource

@export var weapons: Dictionary


func get_weapon_with_id(id: StringName) -> WeaponResource:
	for key in weapons.keys():
		if key.id == id:
			return key

	assert(false, "Weapon with id %s is not found" % id)
	return null
