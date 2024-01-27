class_name GameScene
extends Node

signal exit

enum State { STARTING, PLAYING, DONE }

@export var _pcam: PhantomCamera3D
@export var _players_parent: Node
@export var _respawn_points: Array[Node3D]
var max_lives: int
var respawn_time: float
var starting_time: float = 3

var _players: Array[Player]
var _state: State
var _current_starting_time: float
var _winner: int = -1


func _ready() -> void:
	_current_starting_time = starting_time


func _process(delta: float) -> void:
	match _state:
		State.STARTING:
			_on_starting(delta)
		State.PLAYING:
			_on_playing(delta)
		State.DONE:
			_on_done()


func _on_starting(delta: float) -> void:
	_current_starting_time -= delta
	if _current_starting_time <= 0:
		_state = State.PLAYING


func _on_playing(delta: float) -> void:
	var alive_players: int = 0
	var last_alive: int = -1

	for i in range(_players.size()):
		var player: Player = _players[i]
		match player.state:
			Player.State.RESPAWNING:
				alive_players += 1
				player.current_respawn_time -= delta
				if player.current_respawn_time <= 0:
					_spawn_player_character(i)
					player.current_respawn_time = respawn_time
					player.state = Player.State.PLAYING
			Player.State.PLAYING:
				alive_players += 1
				last_alive = i
			Player.State.DEAD:
				continue

	if alive_players == 1:
		_state = State.DONE
		_winner = last_alive
		_finish_game()


func _on_done() -> void:
	var has_quit: bool = false
	for i in range(_players.size()):
		var player: Player = _players[i]
		match player.end_game_decision:
			Player.EndGameDecision.UNDECIDED:
				return
			Player.EndGameDecision.QUIT:
				has_quit = true
				break

	if has_quit:
		_exit()
	else:
		_reset_all()
		_start_game()


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
		var decide_replay_closure: Callable = func() -> void: _decide_replay(key)
		var decide_quit_closure: Callable = func() -> void: _decide_quit(key)
		var light_attack_closure: Callable = func() -> void: _light_attack(key)
		var heavy_attack_closure: Callable = func() -> void: _heavy_attack(key)

		var player_input: PlayerInput = Controller.get_player_input(key).get_ref()
		player_input.move.connect(move_closure)
		player_input.look.connect(look_closure)
		player_input.confirm.connect(decide_replay_closure)
		player_input.cancel.connect(decide_quit_closure)
		player_input.attack_light.connect(light_attack_closure)
		player_input.attack_heavy.connect(heavy_attack_closure)

	_start_game()


func _reset_all() -> void:
	for i in range(_players.size()):
		var player: Player = _players[i]
		if player.character != null:
			player.character.queue_free()
			player.character = null

		player.force_multiplier = 1
		player.lives = max_lives
		player.state = Player.State.RESPAWNING
		player.current_respawn_time = 0
		player.end_game_decision = Player.EndGameDecision.UNDECIDED


func _exit() -> void:
	exit.emit()


func _finish_game() -> void:
	assert(_winner != -1, "Winner has not been set!")


func _get_player(id: int) -> Player:
	assert(id >= 0 && id < _players.size(), "Id %d is out of bounds!" % id)
	return _players[id]


func _move_player(id: int, vec: Vector2) -> void:
	var player: Player = _get_player(id)
	if player == null:
		return

	if player.state != Player.State.PLAYING:
		return

	var vec3: Vector3 = Vector3(vec.x, 0, -vec.y)
	var rotated_vec: Vector3 = vec3.rotated(Vector3.UP, _pcam.global_rotation.y)
	player.move_character(rotated_vec)


func _look_player(id: int, vec: Vector2) -> void:
	var player: Player = _get_player(id)
	if player == null:
		return

	if player.state != Player.State.PLAYING:
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


func _start_game() -> void:
	_current_starting_time = starting_time
	_state = State.STARTING


func _unregister_camera_follow(id: int) -> void:
	var player: Player = _get_player(id)
	_pcam.erase_follow_group_node(player.character)


func _decide_quit(id: int) -> void:
	if _state != State.DONE:
		return

	var player: Player = _get_player(id)
	if player.end_game_decision == Player.EndGameDecision.QUIT:
		return

	player.end_game_decision = Player.EndGameDecision.QUIT


func _decide_replay(id: int) -> void:
	if _state != State.DONE:
		return

	var player: Player = _get_player(id)
	if player.end_game_decision == Player.EndGameDecision.QUIT:
		return

	player.end_game_decision = Player.EndGameDecision.QUIT


func _light_attack(id: int) -> void:
	if _state != State.PLAYING:
		return

	var player: Player = _get_player(id)
	if player.state != Player.State.PLAYING:
		return

	player.trigger_light_attack()


func _heavy_attack(id: int) -> void:
	if _state != State.PLAYING:
		return

	var player: Player = _get_player(id)
	if player.state != Player.State.PLAYING:
		return

	player.trigger_heavy_attack()
