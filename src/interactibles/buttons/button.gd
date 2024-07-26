extends StaticBody3D

@export var target: Node3D
@export var is_vertical: bool = false:
	set(value):
		is_vertical = value
		$"button-round/button-round/WorldColliderVertical/CollisionShape3D".disabled = !is_vertical

@onready var anim_player = $"button-round/AnimationPlayer"


func _ready():
	add_to_group("interactible")


func interact(_vel: Vector3 = Vector3.ZERO):
	if is_vertical:
		return
	anim_player.play("toggle")
	target.toggle()


func _on_vertical_collider_body_entered(body: Node3D) -> void:
	if is_vertical:
		anim_player.play("toggle")
		target.toggle()
