class_name CharacterResource
extends Resource

@export var id: StringName
@export var nice_name: StringName
## Used for display at character selection
@export var preview_prefab: PackedScene
## Used for gameplay, must inherit from [CharacterController]
@export var character_prefab: PackedScene
