extends Node3D

var is_active: bool = true
var is_homing: bool = false
var target: Node3D
var lerp_weight: float = 0.0
var lerp_duration: float = 1.0
var collect_distance: float = 1.0
@onready var mesh = $Jewel


func _physics_process(delta: float) -> void:
	if is_homing:
		lerp_weight += delta / lerp_duration
		mesh.global_position = lerp(
			mesh.global_position, 
			target.global_position, 
			lerp_weight
		)
	
		if mesh.global_position.distance_to(target.global_position) <= collect_distance:
			self.queue_free()


func collect(body: Node3D) -> void:
	if is_active:
		target = body
		is_homing = true
		is_active = false
