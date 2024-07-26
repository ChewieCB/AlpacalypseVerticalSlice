@tool
extends AnimatableBody3D

@onready var mesh = $Mesh

@onready var close_pos: Vector3 = Vector3.ZERO
@onready var open_pos: Vector3 = Vector3(0, 10, 0)
@export_enum("Open", "Closed") var state: String:
	set(value):
		state = value
		is_open = (state == "Open")
@export var time_taken: float = 1.0
@onready var is_open: bool = false:
	set(value):
		is_open = value

func toggle() -> void:
	is_open = !is_open
	var tween = get_tree().create_tween()
	tween.tween_property(
		self,
		"position:y",
		self.position.y + mesh.mesh.size.y if is_open else self.position.y - mesh.mesh.size.y,
		time_taken
	)
