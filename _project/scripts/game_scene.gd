class_name GameScene
extends Node

signal exit

enum State { STARTING, PLAYING, DONE }

@export var _pcam: PhantomCamera3D
@export var _players_parent: Node
@export var _respawn_points: Array[Node3D]
@export var _weapon_spawner_timer: Timer
@export var _game_controls_canvas: CanvasLayer
@export var _game_ui_canvas: CanvasLayer
@export var _end_game_controls_canvas: CanvasLayer
@export var _starting_canvas: CanvasLayer
@export var _starting_texture_rect: TextureRect
@export var _countdown_textures: Array[Texture2D]
@export var _player_ui: Array[Dictionary]
@export var _decision_icons: Dictionary
@export var _die_sfx: AudioStream
var max_lives: int
var respawn_time: float
var weapon_spawn_interval: float
var weapon_spawn_radius: float
var starting_time: float = 3

var _players: Array[Player]
var _state: State
var _current_starting_time: float
var _winner: int = -1
var _weapon_picker: RandomPicker


func _ready() -> void:
	_current_starting_time = starting_time
	_weapon_picker = RandomPicker.new()
	_weapon_spawner_timer.timeout.connect(_spawn_random_weapon)
	_game_controls_canvas.visible = false
	_game_ui_canvas.visible = false
	_end_game_controls_canvas.visible = false
	_starting_canvas.visible = false


func _process(delta: float) -> void:
	match _state:
		State.STARTING:
			_on_starting(delta)
		State.PLAYING:
			_on_playing(delta)
		State.DONE:
			_on_done()


func _physics_process(_delta: float) -> void:
	for i in range(_players.size()):
		var player: Player = _players[i]
		if player == null:
			continue

		var player_ui: Dictionary = _player_ui[i]

		get_node(player_ui["live_label"]).text = "x%d" % player.lives
		get_node(player_ui["multiplier_label"]).text = "%.2f%%" % (player.force_multiplier * 3)
		get_node(player_ui["decision_icon"]).texture = _decision_icons[player.end_game_decision]


func _on_starting(delta: float) -> void:
	_current_starting_time -= delta

	_starting_texture_rect.texture = _countdown_textures[floori(_current_starting_time)]

	if _current_starting_time <= 0:
		_state = State.PLAYING
		_weapon_spawner_timer.start()
		_game_controls_canvas.visible = true
		_game_ui_canvas.visible = true
		_end_game_controls_canvas.visible = false
		_starting_canvas.visible = false


func _on_playing(delta: float) -> void:
	var alive_players: int = 0
	var last_alive: int = -1

	for i in range(_players.size()):
		var player: Player = _players[i]
		if player == null:
			continue

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
		_game_controls_canvas.visible = false
		_game_ui_canvas.visible = true
		_end_game_controls_canvas.visible = true
		_starting_canvas.visible = false


func _on_done() -> void:
	var has_quit: bool = false
	for i in range(_players.size()):
		var player: Player = _players[i]
		if player == null:
			continue
		match player.end_game_decision:
			Player.EndGameDecision.UNDECIDED:
				return
			Player.EndGameDecision.QUIT:
				has_quit = true

	if has_quit:
		_exit()
	else:
		_reset_all()
		_start_game()


func initialize(max_players: int, player_selections: Dictionary) -> void:
	_players.resize(max_players)

	for i in range(_player_ui.size()):
		get_node(_player_ui[i]["bar"]).visible = false

	for key in player_selections.keys():
		var player: Player = Player.new()
		_players_parent.add_child(player)

		var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
		audio_player.stream = _die_sfx
		audio_player.volume_db = -10
		player.add_child(audio_player)
		player.audio_player = audio_player

		var erase_follow_closure: Callable = func() -> void: _unregister_camera_follow(key)
		player.lives = max_lives
		player.die.connect(erase_follow_closure)
		player.character_id = player_selections[key]

		_players[key] = player

		var move_closure: Callable = func(vec: Vector2) -> void: _move_player(key, vec)
		var look_closure: Callable = func(vec: Vector2) -> void: _look_player(key, vec)
		var decide_quit_closure: Callable = func() -> void: _decide_quit(key)
		var light_attack_closure: Callable = func() -> void: _light_attack(key)
		var heavy_attack_closure: Callable = func() -> void: _heavy_attack(key)
		var confirm_closure: Callable = func() -> void: _on_confirm(key)

		var player_input: PlayerInput = Controller.get_player_input(key).get_ref()
		player_input.move.connect(move_closure)
		player_input.look.connect(look_closure)
		player_input.confirm.connect(confirm_closure)
		player_input.cancel.connect(decide_quit_closure)
		player_input.attack_light.connect(light_attack_closure)
		player_input.attack_heavy.connect(heavy_attack_closure)

		get_node(_player_ui[key]["bar"]).visible = true

	_weapon_spawner_timer.wait_time = weapon_spawn_interval
	_weapon_picker.set_pool(Data.weapon_library.weapons)
	_start_game()


func _reset_all() -> void:
	for i in range(_players.size()):
		var player: Player = _players[i]
		if player.character != null:
			_pcam.erase_follow_group_node(player.character)
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
	_weapon_spawner_timer.stop()


func _get_player(id: int) -> Player:
	assert(id >= 0 && id < _players.size(), "Id %d is out of bounds!" % id)
	return _players[id]


func _move_player(id: int, vec: Vector2) -> void:
	if _state != State.PLAYING:
		return

	var player: Player = _get_player(id)
	if player == null:
		return

	if player.state != Player.State.PLAYING:
		return

	var vec3: Vector3 = Vector3(vec.x, 0, -vec.y)
	var rotated_vec: Vector3 = vec3.rotated(Vector3.UP, _pcam.global_rotation.y)
	player.move_character(rotated_vec)


func _look_player(id: int, vec: Vector2) -> void:
	if _state != State.PLAYING:
		return

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
	_starting_canvas.visible = true
	_game_ui_canvas.visible = false
	_game_controls_canvas.visible = true
	_end_game_controls_canvas.visible = false


func _spawn_random_weapon() -> void:
	var theta: float = randf_range(-PI, PI)
	var distance: float = randf_range(0, weapon_spawn_radius)
	var height: float = 10
	var spawn_position: Vector3 = Vector3(cos(theta) * distance, height, sin(theta) * distance)

	var weapon_resource: WeaponResource = _weapon_picker.pick()
	var pickupable_weapon: PickupableWeapon = (
		weapon_resource.pickupable_prefab.instantiate() as PickupableWeapon
	)
	pickupable_weapon.id = weapon_resource.id
	add_child(pickupable_weapon)
	pickupable_weapon.global_position = spawn_position


func _unregister_camera_follow(id: int) -> void:
	var player: Player = _get_player(id)
	_pcam.erase_follow_group_node(player.character)


func _on_confirm(id: int) -> void:
	match _state:
		State.STARTING:
			return
		State.PLAYING:
			var player: Player = _get_player(id)
			player.pickup()
		State.DONE:
			_decide_replay(id)


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
	if player.end_game_decision == Player.EndGameDecision.REPLAY:
		return

	player.end_game_decision = Player.EndGameDecision.REPLAY


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
