class_name Player
extends Node

var force_multiplier: float
var character: CharacterController


func move_character(vec: Vector3) -> void:
	character.set_movement_vec(vec)


func look_character(rad: float) -> void:
	character.global_rotation = Vector3(0, rad, 0)
