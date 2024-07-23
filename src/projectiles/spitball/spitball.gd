extends CharacterBody3D

var dir = Vector3()
@onready var timer = $Timer

@export var rotation_speed = 1.0
@export var gravity = 10.0
@onready var mesh = $Mesh
var source: Node3D


func _ready():
	var tween = get_tree().create_tween()
	self.scale = Vector3.ZERO
	tween.tween_property(self, "scale", Vector3(1.3, 1.3, 1.6), 0.2)
	tween.tween_property(self, "scale", Vector3.ONE, 2 * (timer.wait_time / 3) - 0.2)
	tween.tween_property(self, "scale", Vector3.ZERO, timer.time_left)
	


func _process(delta: float) -> void:
	position -= transform.basis.z * 30 * delta
	var lifetime_ratio = remap(timer.time_left, timer.wait_time, 0, 0, 1)
	var cubic_gravity = (lifetime_ratio * lifetime_ratio * lifetime_ratio) * -gravity
	position.y += cubic_gravity * delta
	mesh.rotation.y += delta * rotation_speed


func _on_collision_area_body_entered(body: Node3D) -> void:
	if body == source:
		return
	if body.is_in_group("interactible"):
		body.interact(-transform.basis.z * 7)
	queue_free()
