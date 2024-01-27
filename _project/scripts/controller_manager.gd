class_name ControllerManager
extends Node

# signal joy_connection_change

var max_players: int:
	get:
		return _max_players
	set(value):
		assert(value > 0, "Attempted to assign %d to max players." % value)
		_max_players = value
		_initialize_player_inputs(_max_players)

var _player_inputs: Array[PlayerInput]
var _max_players: int


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_change)


func _physics_process(_delta: float) -> void:
	var active_joypads: Array[int] = Input.get_connected_joypads()

	var update_size: int = mini(active_joypads.size(), max_players)
	for i in range(update_size):
		var joypad_id: int = active_joypads[i]

		var horizontal: float = Input.get_axis("left%d" % joypad_id, "right%d" % joypad_id)
		var vertical: float = Input.get_axis("down%d" % joypad_id, "up%d" % joypad_id)
		var movement: Vector2 = Vector2(horizontal, vertical)
		_player_inputs[joypad_id].move.emit(movement)

		if Input.is_action_just_released("confirm%d" % joypad_id):
			_player_inputs[joypad_id].confirm.emit()

		if Input.is_action_just_released("start%d" % joypad_id):
			_player_inputs[joypad_id].start.emit()

		if Input.is_action_just_released("dleft%d" % joypad_id):
			_player_inputs[joypad_id].d_left.emit()

		if Input.is_action_just_released("dright%d" % joypad_id):
			_player_inputs[joypad_id].d_right.emit()

		if Input.is_action_just_released("dup%d" % joypad_id):
			_player_inputs[joypad_id].d_up.emit()

		if Input.is_action_just_released("ddown%d" % joypad_id):
			_player_inputs[joypad_id].d_down.emit()


func get_player_input(id: int) -> WeakRef:
	assert(id >= 0 && id < max_players, "Id %d is out of bounds!" % id)
	return weakref(_player_inputs[id])


func _initialize_player_inputs(players: int) -> void:
	_player_inputs.resize(players)
	for i in range(players):
		_player_inputs[i] = PlayerInput.new()


func _on_joy_connection_change(device: int, connected: bool) -> void:
	if device >= _max_players:
		return

	if connected:
		_player_inputs[device].connected.emit()
	else:
		_player_inputs[device].disconnected.emit()
