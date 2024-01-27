class_name GameScene
extends Node

signal exit


func _ready() -> void:
	var player_0: PlayerInput = Controller.get_player_input(0).get_ref()
	player_0.confirm.connect(_exit)


func initialize(player_selections: Dictionary) -> void:
	print("game scene iniitalize!")
	print(player_selections)


func _exit() -> void:
	exit.emit()
