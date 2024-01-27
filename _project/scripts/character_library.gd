class_name CharacterLibrary
extends Resource

@export var characters: Array[CharacterResource]


func get_character_resource(id: int) -> WeakRef:
	assert(id >= 0 && id <= characters.size(), "id %d is out of bounds!" % id)
	return weakref(characters[id])


func get_character_resource_with_id(id: StringName) -> WeakRef:
	for i in range(characters.size()):
		var character_resource: CharacterResource = characters[i]
		if character_resource.id == id:
			return weakref(character_resource)

	assert(false, "Character with id %s was not found" % id)
	return null
