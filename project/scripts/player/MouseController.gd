extends CharacterBody3D
class_name MouseController
## Third-person 3D controller for the tiny mouse with crouch/crawl, sprint noise, and 2D billboard facing.

signal state_text_changed(state_text: String)

@export_group("Movement")
@export var walk_speed: float = 2.4
@export var sprint_speed: float = 4.2
@export var crouch_speed: float = 1.6
@export var acceleration: float = 16.0
@export var jump_velocity: float = 4.6
@export var gravity: float = 12.5

@export_group("Noise")
@export var sprint_noise_interval: float = 0.35
@export var sprint_noise_radius: float = 4.5

@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var floor_shadow_ray: RayCast3D = $FloorShadowRay
@onready var blob_shadow: Sprite3D = $BlobShadow
@onready var billboard_sprite: Billboard4Dir = $BillboardSprite
@onready var camera_rig: CameraRig = $CameraRig

var is_crouching: bool = false
var _noise_timer: float = 0.0
var _last_state_text: String = ""


func _ready() -> void:
	_apply_crouch_state(false)


func _physics_process(delta: float) -> void:
	_handle_crouch()
	_handle_movement(delta)
	_update_blob_shadow()
	_emit_state_text()


func _handle_crouch() -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch:
		if not is_crouching:
			_apply_crouch_state(true)
	elif is_crouching:
		# Only stand up if there is no low ceiling above (e.g. under a cabinet)
		ceiling_check.force_raycast_update()
		if not ceiling_check.is_colliding():
			_apply_crouch_state(false)


func _apply_crouch_state(crouching: bool) -> void:
	is_crouching = crouching
	standing_collision.disabled = crouching
	crouching_collision.disabled = not crouching

	if crouching:
		billboard_sprite.scale = Vector3(1.0, 0.65, 1.0)
		billboard_sprite.position.y = 0.11
		camera_rig.set_crouch_offset(true)
	else:
		billboard_sprite.scale = Vector3.ONE
		billboard_sprite.position.y = 0.17
		camera_rig.set_crouch_offset(false)


func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_yaw := camera_rig.get_yaw()
	var cam_basis := Basis(Vector3.UP, cam_yaw)
	var move_dir := (cam_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var is_sprinting := Input.is_action_pressed("sprint") and not is_crouching and move_dir.length_squared() > 0.01
	var target_speed := crouch_speed if is_crouching else (sprint_speed if is_sprinting else walk_speed)

	if move_dir.length_squared() > 0.001:
		velocity.x = move_toward(velocity.x, move_dir.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * target_speed, acceleration * delta)
		billboard_sprite.facing_angle_rad = atan2(move_dir.x, move_dir.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	move_and_slide()

	if is_sprinting and is_on_floor():
		_noise_timer += delta
		if _noise_timer >= sprint_noise_interval:
			_noise_timer = 0.0
			var sound_bus := get_node_or_null("/root/SoundEventBus")
			if sound_bus:
				sound_bus.emit_sound(global_position, sprint_noise_radius, 0.8, "mouse_sprint")
	else:
		_noise_timer = 0.0


func _update_blob_shadow() -> void:
	floor_shadow_ray.force_raycast_update()
	if floor_shadow_ray.is_colliding():
		blob_shadow.visible = true
		var hit_point := floor_shadow_ray.get_collision_point()
		blob_shadow.global_position = hit_point + Vector3(0.0, 0.006, 0.0)
		var height_above := maxf(global_position.y - hit_point.y, 0.0)
		var s := clampf(1.0 - height_above * 0.35, 0.45, 1.0)
		blob_shadow.scale = Vector3(s, s, s)
	else:
		blob_shadow.visible = false


func _emit_state_text() -> void:
	var state := "Đứng"
	if not is_on_floor():
		state = "Đang nhảy"
	elif is_crouching:
		ceiling_check.force_raycast_update()
		state = "Chui gầm" if ceiling_check.is_colliding() else "Cúi người"
	elif Input.is_action_pressed("sprint") and Vector2(velocity.x, velocity.z).length() > walk_speed + 0.2:
		state = "Chạy nhanh (Ồn)"
	elif Vector2(velocity.x, velocity.z).length() > 0.2:
		state = "Đi bộ"

	if state != _last_state_text:
		_last_state_text = state
		state_text_changed.emit(state)
