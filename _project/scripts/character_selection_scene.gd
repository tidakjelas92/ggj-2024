class_name CharacterSelectionScene
extends Node

signal start

@export var _position_root: Node3D
## Range between characters in world coords
@export var _step: float = 1
var _player_slots: Array[Slot]


func initialize(max_players: int) -> void:
	_player_slots.resize(max_players)
	for i in range(max_players):
		var slot: Slot = Slot.new()
		add_child(slot)
		_player_slots[i] = slot

	var player_0: PlayerInput = Controller.get_player_input(0).get_ref()
	player_0.confirm.connect(_start_game)


func _start_game() -> void:
	start.emit()
