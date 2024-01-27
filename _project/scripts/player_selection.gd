class_name PlayerSelection
extends Node

enum State { DISCONNECTED, CONNECTED, SELECTING, READY }

var character_index: int = 0
var state: State = State.DISCONNECTED
var character_node: Node3D
