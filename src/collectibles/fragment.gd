extends RigidBody3D
class_name Fragment

@export var lifetime: float = 1.0
var elapsed_time: float = 0.0


func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time > lifetime:
		queue_free()


func init_from_mesh(source: MeshInstance3D):
	global_transform = source.global_transform
	
	var mesh_inst: MeshInstance3D = source.duplicate()
	mesh_inst.transform = Transform3D.IDENTITY
	add_child(mesh_inst)
	
	$CollisionShape3D.shape = source.mesh.create_convex_shape()
