@tool
extends Node3D
class_name Jewel

var is_active: bool = true
var is_homing: bool = false
var target: Node3D
var lerp_weight: float = 0.0
var lerp_duration: float = 1.0
var collect_distance: float = 1.0
var rotation_speed: float = 2.0
var mesh: MeshInstance3D

enum GEM_COLOURS {BLACK, BLUE, GREEN, ORANGE, PEARL, PINK, RED, SKY, VIOLET, YELLOW}
enum GEM_SHAPES {DIAMOND, TRAPEZIUM, BROOCH, TRIANGLE, ROUND, CHUNK, SQUARE}
var base_texture_path = "res://assets/collectibles/gems/TEXTURES/GLTF/%s/GEMS_baseColor.png"
var gem_textures = []
var gem_meshes = []
@export_enum(
	"BLACK", "BLUE", "GREEN", "ORANGE", "PEARL", "PINK", "RED", "SKY", "VIOLET", "YELLOW"
	) var gem_color_str: String = "RED":
		set(value):
			gem_color_str = value
			if mesh:
				var material = gem_textures[GEM_COLOURS.keys().find(gem_color_str)]
				mesh.mesh.surface_set_material(0, material)
@export_enum(
	"DIAMOND", "TRAPEZIUM", "BROOCH", "TRIANGLE", "ROUND", "CHUNK", "SQUARE"
	) var gem_shape_str: String = "DIAMOND":
		set(value):
			gem_shape_str = value
			
			if mesh:
				mesh.queue_free()
			
			if gem_meshes:
				mesh = gem_meshes[GEM_SHAPES.keys().find(gem_shape_str)].instantiate()
				add_child(mesh)
				gem_color_str = gem_color_str
			


func _ready():
	mesh = $Mesh
	gem_textures = _load_files("res://src/collectibles/jewel/meshes/materials/")
	gem_meshes = _load_files("res://src/collectibles/jewel/meshes/")
	gem_color_str = GEM_COLOURS.keys()[randi() % GEM_COLOURS.size()]
	gem_shape_str = GEM_SHAPES.keys()[randi() % GEM_SHAPES.size()]


func _physics_process(delta: float) -> void:
	mesh.rotate_y(rotation_speed * delta)
	
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


func _load_files(dir: String) -> Array:
	var output = []
	for file_name in DirAccess.get_files_at(dir):
		if (file_name.get_extension() == "import"):
			file_name = file_name.replace('.import', '')
		output.append(ResourceLoader.load(dir + file_name)) 
	return output
