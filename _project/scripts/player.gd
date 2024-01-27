class_name Player
extends Node

signal die
signal respawn

var force_multiplier: float
var character: CharacterController


func set_character(chara: CharacterController) -> void:
	character = chara
	character.die.connect(_on_die)


func move_character(vec: Vector3) -> void:
	character.set_movement_vec(vec)


func look_character(rad: float) -> void:
	character.global_rotation = Vector3(0, rad, 0)


func _on_die() -> void:
	character.queue_free()
	die.emit()
	force_multiplier = 1
