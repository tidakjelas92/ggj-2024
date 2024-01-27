class_name Player
extends Node

signal die
signal respawn

enum State { RESPAWNING, PLAYING, DEAD }

var force_multiplier: float
var lives: int = 5
var character_id: StringName
var character: CharacterController
var state: State
var current_respawn_time: float


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
	lives -= 1

	if lives <= 0:
		state = State.DEAD
	else:
		state = State.RESPAWNING
