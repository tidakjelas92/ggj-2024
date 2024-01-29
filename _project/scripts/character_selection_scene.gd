class_name CharacterSelectionScene
extends Node

signal start(Dictionary)

enum State { SELECTING, COUNTING, STARTING }

@export var _position_root: Node3D
@export var _slots_parent: Node3D
@export var _player_selections_parent: Node
@export var _player_ui: Array[Dictionary]
@export var _title_rect: Control
## Range between characters in world coords
@export var _step: float = 1
@export var _countdown: int = 5
@export var _sfx_audio_player: AudioStreamPlayer
@export var _select_sfx: AudioStream
@export var _confirm_sfx: AudioStream
var _state: State = State.SELECTING
var _player_slots: Array[Slot]
var _player_selections: Array[PlayerSelection]
var _min_players: int
var _current_countdown: float = 0


func _ready() -> void:
	_title_rect.visible = false


func _process(delta: float) -> void:
	match _state:
		State.SELECTING:
			if _is_ready_to_start():
				_current_countdown = _countdown
				_state = State.COUNTING
				_title_rect.scale = Vector2.ZERO
				_title_rect.visible = true

		State.COUNTING:
			if !_is_ready_to_start():
				_state = State.SELECTING
				_title_rect.visible = false
				return

			_current_countdown -= delta
			var percentage: float = 1 - _current_countdown / _countdown
			_title_rect.scale = Vector2(percentage, percentage)
			print("Countdown: %.2f" % _current_countdown)
			if _current_countdown <= 0:
				_state = State.STARTING

		State.STARTING:
			_start_game()


func initialize(min_players: int, max_players: int) -> void:
	_min_players = min_players
	var max_range: float = (max_players - 1) * _step
	_player_slots.resize(max_players)
	for i in range(max_players):
		var slot: Slot = Slot.new()
		_slots_parent.add_child(slot)

		var slot_position: Vector3 = _position_root.global_position
		slot_position.x += i * _step
		slot_position.x -= max_range / 2
		slot.global_position = slot_position

		_player_slots[i] = slot

	for i in range(max_players):
		var player_input: PlayerInput = Controller.get_player_input(i).get_ref()

		var on_disconnect_closure: Callable = func() -> void: _on_player_disconnect(i)
		var on_connect_closure: Callable = func() -> void: _on_player_connect(i)
		var on_start_closure: Callable = func() -> void: _on_start(i)
		var on_confirm_closure: Callable = func() -> void: _on_confirm(i)
		var on_previous_closure: Callable = func() -> void: _previous_character(i)
		var on_next_closure: Callable = func() -> void: _next_character(i)

		player_input.disconnected.connect(on_disconnect_closure)
		player_input.connected.connect(on_connect_closure)
		player_input.start.connect(on_start_closure)
		player_input.confirm.connect(on_confirm_closure)
		player_input.d_left.connect(on_previous_closure)
		player_input.d_right.connect(on_next_closure)

	_player_selections.resize(max_players)
	for i in range(max_players):
		var player: PlayerSelection = PlayerSelection.new()
		_player_selections_parent.add_child(player)
		_player_selections[i] = player

	for i in range(_player_ui.size()):
		get_node(_player_ui[i]["player_icon"]).visible = false
		get_node(_player_ui[i]["ready_icon"]).visible = false

	var connected_joypads: Array[int] = Input.get_connected_joypads()
	for i in range(connected_joypads.size()):
		_player_selections[connected_joypads[i]].state = PlayerSelection.State.CONNECTED


func _compile_player_selections() -> Dictionary:
	var result: Dictionary = {}
	for i in range(_player_selections.size()):
		var player: PlayerSelection = _player_selections[i]
		if player.state != PlayerSelection.State.READY:
			continue
		var character: CharacterResource = (
			Data.character_library.get_character_resource(player.character_index).get_ref()
		)
		result[i] = character.id

	return result


func _get_player(id: int) -> PlayerSelection:
	assert(id >= 0 && id < _player_selections.size(), "id %d is out of bounds!" % id)
	return _player_selections[id]


func _is_ready_to_start() -> bool:
	var ready_count: int = 0
	var total_count: int = 0
	for i in range(_player_selections.size()):
		var player: PlayerSelection = _player_selections[i]
		match player.state:
			PlayerSelection.State.DISCONNECTED:
				continue
			PlayerSelection.State.CONNECTED:
				continue
			PlayerSelection.State.SELECTING:
				total_count += 1
			PlayerSelection.State.READY:
				total_count += 1
				ready_count += 1

	if ready_count < _min_players:
		return false

	return ready_count == total_count


func _on_player_disconnect(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state == PlayerSelection.State.DISCONNECTED:
		return

	print("player %d is disconnected" % id)
	player.state = PlayerSelection.State.DISCONNECTED
	_despawn_player_character(id)
	player.character_index = 0
	get_node(_player_ui[id]["player_icon"]).visible = false
	get_node(_player_ui[id]["ready_icon"]).visible = false
	_title_rect.visible = false

	_state = State.SELECTING


func _on_player_connect(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state == PlayerSelection.State.CONNECTED:
		return

	print("player %d is connected" % id)
	player.state = PlayerSelection.State.CONNECTED
	_state = State.SELECTING


func _on_confirm(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	match player.state:
		PlayerSelection.State.SELECTING:
			print("player %d is ready" % id)
			player.state = PlayerSelection.State.READY
			get_node(_player_ui[id]["ready_icon"]).visible = true
			_sfx_audio_player.stream = _confirm_sfx
			_sfx_audio_player.play()
		PlayerSelection.State.READY:
			print("player %d is selecting" % id)
			player.state = PlayerSelection.State.SELECTING
			get_node(_player_ui[id]["ready_icon"]).visible = false
		_:
			return


func _on_start(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	match player.state:
		PlayerSelection.State.DISCONNECTED:
			return
		PlayerSelection.State.CONNECTED:
			print("player %d is selecting" % id)
			player.state = PlayerSelection.State.SELECTING

			get_node(_player_ui[id]["player_icon"]).visible = true
			_spawn_player_character(id)
		_:
			player.state = PlayerSelection.State.CONNECTED
			_despawn_player_character(id)
			player.character_index = 0
			get_node(_player_ui[id]["player_icon"]).visible = false
			get_node(_player_ui[id]["ready_icon"]).visible = false
			_state = State.SELECTING


func _next_character(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state != PlayerSelection.State.SELECTING:
		return

	_despawn_player_character(id)

	var char_index: int = player.character_index + 1
	if char_index >= Data.character_library.characters.size():
		char_index = 0

	player.character_index = char_index
	_spawn_player_character(id)
	_sfx_audio_player.stream = _select_sfx
	_sfx_audio_player.play()


func _previous_character(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state != PlayerSelection.State.SELECTING:
		return

	_despawn_player_character(id)

	var char_index: int = player.character_index - 1
	if char_index < 0:
		char_index = Data.character_library.characters.size() - 1

	player.character_index = char_index
	_spawn_player_character(id)

	_sfx_audio_player.stream = _select_sfx
	_sfx_audio_player.play()


func _spawn_player_character(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	var character_resource: CharacterResource = (
		Data.character_library.get_character_resource(player.character_index).get_ref()
	)
	var character: Node3D = character_resource.preview_prefab.instantiate() as Node3D

	var slot: Slot = _player_slots[id]
	slot.put(character)

	player.character_node = character


func _despawn_player_character(id: int) -> void:
	var slot: Slot = _player_slots[id]
	if !slot.is_occupied():
		return

	var character: Node3D = slot.take()
	character.queue_free()


func _start_game() -> void:
	print("Character selection start game")
	start.emit(_compile_player_selections())
