class_name GameScene
extends Node

signal exit

@export var _pcam: PhantomCamera3D
@export var _players_parent: Node

var _players: Array[Player]


func _ready() -> void:
	var player_0: PlayerInput = Controller.get_player_input(0).get_ref()
	player_0.confirm.connect(_exit)


func initialize(player_selections: Dictionary) -> void:
	print(player_selections)
	var player_count: int = player_selections.size()
	_players.resize(player_count)

	for key in player_selections.keys():
		var player: Player = Player.new()
		_players_parent.add_child(player)

		var character_id: StringName = player_selections[key]
		var character_resource: CharacterResource = (
			Data.character_library.get_character_resource_with_id(character_id).get_ref()
		)
		var character: CharacterController = (
			character_resource.character_prefab.instantiate() as CharacterController
		)
		add_child(character)
		_pcam.append_follow_group_node(character)

		var erase_follow_closure: Callable = func() -> void: _pcam.erase_follow_group_node(
			character
		)

		player.force_multiplier = 1
		player.set_character(character)
		player.die.connect(erase_follow_closure)

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
