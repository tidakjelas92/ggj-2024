class_name CharacterSelectionScene
extends Node

signal start

@export var _character_library: Array[CharacterResource]
@export var _position_root: Node3D
@export var _slots_parent: Node3D
@export var _player_selections_parent: Node
## Range between characters in world coords
@export var _step: float = 1
var _player_slots: Array[Slot]
var _player_selections: Array[PlayerSelection]


func initialize(max_players: int) -> void:
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


func _start_game() -> void:
	start.emit()


func _get_player(id: int) -> PlayerSelection:
	assert(id >= 0 && id < _player_selections.size(), "id %d is out of bounds!" % id)
	return _player_selections[id]


func _get_character_resource(id: int) -> CharacterResource:
	assert(id >= 0 && id <= _player_selections.size(), "id %d is out of bounds!" % id)
	return _character_library[id]


func _on_player_disconnect(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state == PlayerSelection.State.DISCONNECTED:
		return

	print("player %d is disconnected" % id)
	player.state = PlayerSelection.State.DISCONNECTED
	_despawn_player_character(id)
	player.character_index = 0


func _on_player_connect(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state == PlayerSelection.State.CONNECTED:
		return

	print("player %d is connected" % id)
	player.state = PlayerSelection.State.CONNECTED


func _on_confirm(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	match player.state:
		PlayerSelection.State.SELECTING:
			print("player %d is ready" % id)
			player.state = PlayerSelection.State.READY
		PlayerSelection.State.READY:
			print("player %d is selecting" % id)
			player.state = PlayerSelection.State.SELECTING
		_:
			return


func _on_start(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state == PlayerSelection.State.SELECTING:
		return

	if player.state == PlayerSelection.State.READY:
		return

	print("player %d is selecting" % id)
	player.state = PlayerSelection.State.SELECTING
	_spawn_player_character(id)


func _next_character(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state != PlayerSelection.State.SELECTING:
		return

	_despawn_player_character(id)

	var char_index: int = player.character_index + 1
	if char_index >= _character_library.size():
		char_index = 0

	player.character_index = char_index
	_spawn_player_character(id)


func _previous_character(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	if player.state != PlayerSelection.State.SELECTING:
		return

	_despawn_player_character(id)

	var char_index: int = player.character_index - 1
	if char_index < 0:
		char_index = _character_library.size() - 1

	player.character_index = char_index
	_spawn_player_character(id)


func _spawn_player_character(id: int) -> void:
	var player: PlayerSelection = _get_player(id)
	var character_resource: CharacterResource = _get_character_resource(player.character_index)
	var character: Node3D = character_resource.prefab.instantiate() as Node3D

	var slot: Slot = _player_slots[id]
	slot.put(character)

	player.character_node = character


func _despawn_player_character(id: int) -> void:
	var slot: Slot = _player_slots[id]
	if !slot.is_occupied():
		return

	var character: Node3D = slot.take()
	character.queue_free()
