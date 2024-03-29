class_name MainScene
extends Node

@export var _character_selection_prefab: PackedScene
@export var _game_prefab: PackedScene
@export var _max_players: int = 4
@export var _min_players: int = 2
@export var _max_lives: int = 5
@export var _respawn_time: float = 10
@export var _weapon_spawn_radius: float = 10
@export var _weapon_spawn_interval: float = 5

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
	character_selection_scene.initialize(_min_players, Controller.max_players)
	character_selection_scene.start.connect(_load_game_scene)
	_active_scene = character_selection_scene


func _load_game_scene(player_selections: Dictionary) -> void:
	if _active_scene != null:
		_active_scene.queue_free()

	var game_scene = _game_prefab.instantiate()
	add_child(game_scene)
	game_scene.exit.connect(_load_character_selection_scene)
	game_scene.max_lives = _max_lives
	game_scene.respawn_time = _respawn_time
	game_scene.weapon_spawn_radius = _weapon_spawn_radius
	game_scene.weapon_spawn_interval = _weapon_spawn_interval / player_selections.size()
	game_scene.initialize(_max_players, player_selections)
	_active_scene = game_scene
