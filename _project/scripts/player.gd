class_name Player
extends Node

signal die
signal respawn

enum State { RESPAWNING, PLAYING, DEAD }
enum EndGameDecision { UNDECIDED, REPLAY, QUIT }

var force_multiplier: float
var lives: int = 5
var character_id: StringName
var character: CharacterController
var state: State
var current_respawn_time: float
var end_game_decision: EndGameDecision


func set_character(chara: CharacterController) -> void:
	character = chara
	character.die.connect(_on_die)
	character.take_damage = _take_damage


func move_character(vec: Vector3) -> void:
	if character == null:
		return
	character.set_movement_vec(vec)


func look_character(rad: float) -> void:
	if character == null:
		return
	character.global_rotation = Vector3(0, rad, 0)


func pickup() -> void:
	if character == null:
		return

	if !character.has_pickupable():
		return

	character.pickup()


func trigger_light_attack() -> void:
	if character == null:
		return
	character.trigger_light_attack()


func trigger_heavy_attack() -> void:
	if character == null:
		return
	character.trigger_heavy_attack()


func _on_die() -> void:
	character.queue_free()
	die.emit()
	force_multiplier = 1
	lives -= 1

	if lives <= 0:
		state = State.DEAD
	else:
		state = State.RESPAWNING


func _take_damage(damage: float, direction: Vector3) -> void:
	force_multiplier += damage
	character.apply_central_impulse(force_multiplier * direction)
