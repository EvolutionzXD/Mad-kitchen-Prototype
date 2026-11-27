extends Sprite3D
class_name Billboard4Dir
## Updates Sprite3D frame (0=Front, 1=Right, 2=Back, 3=Left) based on camera view angle.

@export var target_body: Node3D
@export var facing_angle_rad: float = 0.0


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var owner_node := target_body if target_body != null else get_parent() as Node3D
	if owner_node == null:
		return

	# Vector from sprite toward camera on the XZ plane
	var to_cam := cam.global_position - owner_node.global_position
	to_cam.y = 0.0
	if to_cam.length_squared() < 0.0001:
		return
	to_cam = to_cam.normalized()

	var forward := Vector3(sin(facing_angle_rad), 0.0, cos(facing_angle_rad))
	var right := Vector3(forward.z, 0.0, -forward.x)

	var forward_dot := forward.dot(to_cam)
	var right_dot := right.dot(to_cam)

	if absf(forward_dot) >= absf(right_dot):
		frame = 0 if forward_dot > 0.0 else 2
	else:
		frame = 1 if right_dot > 0.0 else 3
