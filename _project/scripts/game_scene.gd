class_name GameScene
extends Node

signal exit


func _ready() -> void:
	var player_0: PlayerInput = Controller.get_player_input(0).get_ref()
	player_0.confirm.connect(_exit)


func _exit() -> void:
	exit.emit()
