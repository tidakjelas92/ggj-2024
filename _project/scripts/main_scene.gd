class_name MainScene
extends Node

@export var _character_selection_prefab: PackedScene
@export var _game_prefab: PackedScene
@export var _max_players: int = 4

var _active_scene: Node


func _ready() -> void:
	Controller.max_players = _max_players
	_load_character_selection_scene()


func _load_character_selection_scene() -> void:
	if _active_scene != null:
		_active_scene.queue_free()

	var character_selection_scene: CharacterSelectionScene = (
		_character_selection_prefab.instantiate() as CharacterSelectionScene
	)
	add_child(character_selection_scene)
	character_selection_scene.initialize(Controller.max_players)
	character_selection_scene.start.connect(_load_game_scene)
	_active_scene = character_selection_scene


func _load_game_scene() -> void:
	if _active_scene != null:
		_active_scene.queue_free()

	var game_scene = _game_prefab.instantiate()
	add_child(game_scene)
	game_scene.exit.connect(_load_character_selection_scene)
	_active_scene = game_scene
