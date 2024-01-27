class_name GameScene
extends Node

signal exit

@export var _pcam: PhantomCamera3D
@export var _players_parent: Node
@export var _respawn_points: Array[Node3D]
var max_lives: int
var respawn_time: float

var _players: Array[Player]


func _ready() -> void:
	var player_0: PlayerInput = Controller.get_player_input(0).get_ref()
	player_0.confirm.connect(_exit)


func _process(delta: float) -> void:
	for i in range(_players.size()):
		var player: Player = _players[i]
		match player.state:
			Player.State.RESPAWNING:
				player.current_respawn_time -= delta
				if player.current_respawn_time <= 0:
					_spawn_player_character(i)
					player.current_respawn_time = respawn_time
					player.state = Player.State.PLAYING
			_:
				continue


func initialize(player_selections: Dictionary) -> void:
	print(player_selections)
	var player_count: int = player_selections.size()
	_players.resize(player_count)

	for key in player_selections.keys():
		var player: Player = Player.new()
		_players_parent.add_child(player)

		var erase_follow_closure: Callable = func() -> void: _unregister_camera_follow(key)
		player.lives = max_lives
		player.die.connect(erase_follow_closure)
		player.character_id = player_selections[key]

		_players[key] = player

		var move_closure: Callable = func(vec: Vector2) -> void: _move_player(key, vec)
		var look_closure: Callable = func(vec: Vector2) -> void: _look_player(key, vec)

		var player_input: PlayerInput = Controller.get_player_input(key).get_ref()
		player_input.move.connect(move_closure)
		player_input.look.connect(look_closure)


func _exit() -> void:
	exit.emit()


func _get_player(id: int) -> Player:
	assert(id >= 0 && id < _players.size(), "Id %d is out of bounds!" % id)
	return _players[id]


func _move_player(id: int, vec: Vector2) -> void:
	var player: Player = _get_player(id)
	if player == null:
		return

	if player.character == null:
		return

	var vec3: Vector3 = Vector3(vec.x, 0, -vec.y)
	var rotated_vec: Vector3 = vec3.rotated(Vector3.UP, _pcam.global_rotation.y)
	player.move_character(rotated_vec)


func _look_player(id: int, vec: Vector2) -> void:
	var player: Player = _get_player(id)
	if player == null:
		return

	if player.character == null:
		return

	if vec == Vector2.ZERO:
		return

	var rad: float = atan2(vec.y, vec.x)
	rad += _pcam.global_rotation.y
	rad += PI * 0.5
	player.look_character(rad)


func _spawn_player_character(id: int) -> void:
	var player: Player = _get_player(id)
	var character_resource: CharacterResource = (
		Data.character_library.get_character_resource_with_id(player.character_id).get_ref()
	)
	var character: CharacterController = (
		character_resource.character_prefab.instantiate() as CharacterController
	)
	add_child(character)

	character.global_position = _respawn_points[id].global_position
	character.global_rotation = _respawn_points[id].global_rotation

	_pcam.append_follow_group_node(character)
	player.set_character(character)
	player.force_multiplier = 1


func _unregister_camera_follow(id: int) -> void:
	var player: Player = _get_player(id)
	_pcam.erase_follow_group_node(player.character)
