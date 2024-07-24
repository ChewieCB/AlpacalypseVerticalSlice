extends CharacterBody3D

signal coin_collected

@export_subgroup("Components")
@export var view: Node3D

@export_subgroup("Properties")
@export var movement_speed = 350
@export var jump_strength = 7
@export var sensitivity = 0.5

var movement_velocity: Vector3
var rotation_direction: float
var gravity = 0

var previously_floored = false

var jump_single = true
var jump_double = true

var coins = 0

#@onready var particles_trail = $ParticlesTrail
#@onready var sound_footsteps = $SoundFootsteps
@onready var model = $Llama
@onready var skeleton = $Llama/rig/Skeleton3D
@onready var skeleton_index_neck_look = skeleton.find_bone("ORG-spine.006")
@onready var skeleton_index_head_look = skeleton.find_bone("ORG-head")
@onready var neck_rest = skeleton.get_bone_rest(skeleton_index_neck_look)
@onready var camera_pivot_h = $CameraHPivot
@onready var camera_pivot_v = $CameraHPivot/CameraVPivot
@onready var camera = $CameraHPivot/CameraVPivot/SpringArm3D/Camera3D
@onready var animation = $Llama/AnimationPlayer
@onready var anim_tree = $Llama/AnimationTree
@onready var anim_jump_state = anim_tree["parameters/JumpState/playback"]
#@onready var anim_state_machine = anim_tree["parameters/playback"]
@onready var kick_collider = $Llama/KickArea
@onready var spitball_scene = preload("res://src/projectiles/spitball/SpitBall.tscn")
@onready var projectile_spawn = $Llama/rig/Skeleton3D/ProjectileSpawnAttachment/ProjectileSpawn
@onready var spit_cooldown = $SpitCooldownTimer

@onready var aiming_ui = $UI/AimingUI

# Functions

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_tree.active = true
	anim_tree.set("parameters/Transition/current_state", "idle")

func _input(event):
	if event is InputEventMouseMotion:
		camera_pivot_h.rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		camera_pivot_v.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		camera_pivot_v.rotation.x = clamp(camera_pivot_v.rotation.x, deg_to_rad(-75), deg_to_rad(45))


func _physics_process(delta):
	
	# Handle functions
	
	handle_controls(delta)
	handle_gravity(delta)
	handle_effects()
	
	if Input.is_action_pressed("aim"):
		aiming_ui.visible = true
		# Crane neck and aim spitball towards camera aim postion
		var bone_pose: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton_index_neck_look)
		var rest_pose = skeleton.get_bone_global_pose_no_override(skeleton_index_neck_look)
		
		var mouse_position_2d = get_viewport().get_mouse_position()
		var dropPlane  = Plane(Vector3(0, 0, 1), 10)
		var mouse_position_3d = camera.project_ray_origin(mouse_position_2d)
		
		# TODO - clamp the neck rotation
		# We know the direction the mesh is pointing, we set an angular limit and 
		# determine clamped bounds by rotating the mesh direction by this angular limit
		
		bone_pose = bone_pose.looking_at(mouse_position_3d, Vector3.UP)
		skeleton.set_bone_global_pose_override(
			skeleton_index_neck_look, 
			skeleton.global_transform.affine_inverse() * bone_pose,
			1.0,
			true
		)
	elif Input.is_action_just_released("aim"):
		skeleton.clear_bones_global_pose_override()
		aiming_ui.visible = false
	
	if anim_tree.get("parameters/kick/active"):
		skeleton.clear_bones_global_pose_override()
		aiming_ui.visible = false
		
	if Input.is_action_just_pressed("spit"):
		if not anim_tree.get("parameters/spit/active"):
			anim_tree.set("parameters/spit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	elif Input.is_action_just_pressed("kick"):
		if not anim_tree.get("parameters/kick/active"):
			anim_tree.set("parameters/kick/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	# Movement

	var applied_velocity: Vector3
	
	if movement_velocity:
		applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	else:
		applied_velocity.x = move_toward(applied_velocity.x, 0, movement_speed)
		applied_velocity.y = move_toward(applied_velocity.y, 0, movement_speed)
	applied_velocity.y = -gravity
	
	velocity = applied_velocity
	move_and_slide()
	var n = ($Llama/FrontRay.get_collision_normal() + $Llama/BackRay.get_collision_normal()) / 2.0
	var xform = align_with_y(model.global_transform, n)
	model.global_transform = model.global_transform.interpolate_with(xform, 12 * delta)
	
	# Falling/respawning
	
	if position.y < -10:
		get_tree().reload_current_scene()
	
	# Animation for scale (jumping and landing)
	
	model.scale = model.scale.lerp(Vector3(1, 1, 1), delta * 10)
	
	# Animation when landing
	
	if is_on_floor() and gravity > 2 and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		anim_jump_state.travel("JumpEnd")
		#Audio.play("res://sounds/land.ogg")
	
	previously_floored = is_on_floor()

# Handle animation(s)

func handle_effects():
	pass
	
	#particles_trail.emitting = false
	#sound_footsteps.stream_paused = true
	#
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			anim_tree.set("parameters/Transition/transition_request", "walk")
			#particles_trail.emitting = true
			#sound_footsteps.stream_paused = false
		else:
			anim_tree.set("parameters/Transition/transition_request", "idle")
	else:
		anim_tree.set("parameters/Transition/transition_request", "jump")
		anim_jump_state.travel("JumpAir")

# Handle movement input

func handle_controls(delta):
	
	# Movement
	
	var input := Vector2.ZERO
	input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	direction = direction.rotated(Vector3.UP, camera_pivot_h.rotation.y).normalized()
	movement_velocity = direction * movement_speed * delta
	
	if input != Vector2.ZERO:
		#direction = -camera_pivot_h.global_transform.basis.z
		model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), delta * 12)
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	# Jumping
	
	if Input.is_action_just_pressed("jump"):
		
		#if jump_single or jump_double:
			#Audio.play("res://sounds/jump.ogg")
		
		if jump_double:
			
			gravity = -jump_strength
			
			jump_double = false
			model.scale = Vector3(0.5, 1.5, 0.5)
			
		if jump_single: 
			jump()

# Handle gravity

func handle_gravity(delta):
	
	gravity += 25 * delta
	
	if gravity > 0 and is_on_floor():
		
		jump_single = true
		gravity = 0


func align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

# Jumping

func jump():
	
	gravity = -jump_strength
	
	model.scale = Vector3(0.5, 1.5, 0.5)
	
	jump_single = false;
	jump_double = true;


func kick():
	var bodies = kick_collider.get_overlapping_bodies()
	if bodies: 
		for body in bodies:
			if body.collision_layer == 1:
				pass
				# TODO - wall kick
			else:
				body.interact(model.global_transform.basis.z * 10)


func spit():
	var spitball = spitball_scene.instantiate()
	spitball.source = self
	
	get_tree().get_root().add_child(spitball)
	
	spitball.global_transform.origin = projectile_spawn.global_transform.origin
	spitball.basis.z = -model.basis.z
	
	if Input.is_action_pressed("aim"):
		spitball.global_transform = projectile_spawn.global_transform
		var position2D = get_viewport().get_mouse_position()
		var dropPlane  = Plane(Vector3(0, 0, 1), 10)
		var from = camera.project_ray_origin(position2D)
		var to = from + camera.project_ray_normal(position2D) * 100
		to.y += $CameraHPivot/CameraVPivot/SpringArm3D.global_transform.origin.y
		spitball.look_at(to)

# Collecting coins

func collect_coin():
	
	coins += 1
	
	coin_collected.emit(coins)


func _on_collectible_pickup_range_body_entered(body: Node3D) -> void:
	body.collect(self)
