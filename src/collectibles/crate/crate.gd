extends Node3D

@export_flags_3d_physics var fragment_collision_layer: int = 1
@export_flags_3d_physics var fragment_collision_mask: int = 1
@export var explosion_speed: float = 4.0
@export var min_frag_lifetime: float = 0.8
@export var max_frag_lifetime: float = 1.8

@onready var fragment_scene = preload("res://src/collectibles/Fragment.tscn")
@onready var gem_scene = preload("res://src/collectibles/jewel/jewel.tscn")

var shatter_origin: Vector3


func interact(vel: Vector3 = Vector3.ZERO):
	explode(vel)


func explode(vel: Vector3 = Vector3.ZERO):
	var parent = get_parent()
	shatter_origin = $ShatterOrigin.global_transform.origin
	queue_free()
	
	for child in $Fragments.get_children():
		if child is MeshInstance3D:
			var frag: Fragment = fragment_scene.instantiate()
			frag.init_from_mesh(child)
			#frag.collison_layer = fragment_collision_layer
			#frag.collison_mask = fragment_collision_mask
			parent.add_child(frag)
			
			if vel == Vector3.ZERO:
				vel = (frag.global_transform.origin - shatter_origin)
			
			frag.linear_velocity = vel * explosion_speed
			
			frag.lifetime = randf_range(min_frag_lifetime, max_frag_lifetime)
	
	spawn_gems()


func spawn_gems():
	var tween = get_tree().create_tween()
	
	var gem: Jewel = gem_scene.instantiate()
	# TODO - make this a signal and let the gem scenes or a collectibles manager handle this
	get_parent().add_child(gem)
	gem.global_transform.origin = shatter_origin
