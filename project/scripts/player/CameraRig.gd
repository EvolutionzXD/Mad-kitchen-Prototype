extends Node3D
class_name CameraRig
## Third-person camera orbit with SpringArm collision and automatic occlusion fading.

@export var mouse_sensitivity: float = 0.0025
@export var min_pitch_deg: float = -55.0
@export var max_pitch_deg: float = 35.0
@export var standing_height: float = 0.24
@export var crouch_height: float = 0.14
@export var occlusion_transparency: float = 0.65

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _yaw: float = 0.0
var _pitch: float = -0.35
var _target_height: float = 0.24
var _faded_geometries: Array[GeometryInstance3D] = []


func _ready() -> void:
	top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_target_height = standing_height


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(
			_pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
	elif event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var parent_node := get_parent() as Node3D
	if parent_node == null:
		return

	var target_pos := parent_node.global_position + Vector3(0.0, _target_height, 0.0)
	global_position = global_position.lerp(target_pos, minf(18.0 * delta, 1.0))
	rotation = Vector3(_pitch, _yaw, 0.0)

	_update_occlusion_fade(target_pos)


func set_crouch_offset(crouching: bool) -> void:
	_target_height = crouch_height if crouching else standing_height


func get_yaw() -> float:
	return _yaw


func _update_occlusion_fade(target_pos: Vector3) -> void:
	# Restore previously faded meshes
	for geo in _faded_geometries:
		if is_instance_valid(geo):
			geo.transparency = 0.0
	_faded_geometries.clear()

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, target_pos, 1)
	query.collide_with_areas = false

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider: Object = hit.get("collider")
	if collider is GeometryInstance3D:
		var geo := collider as GeometryInstance3D
		geo.transparency = occlusion_transparency
		_faded_geometries.append(geo)
	elif collider is Node:
		for child in (collider as Node).get_children():
			if child is GeometryInstance3D:
				var geo := child as GeometryInstance3D
				geo.transparency = occlusion_transparency
				_faded_geometries.append(geo)
