extends Control
class_name Dice3D
## 3D 骰子：SubViewport 中渲染 BoxMesh，6 面贴 1-6 点数。
## - 投骰：高速旋转 ~1.5 秒，最终面朝向相机为 result。

signal rolled(value: int)

const SPIN_DURATION := 1.6
const FINAL_TWEEN := 0.4

var viewport: SubViewport
var camera: Camera3D
var mesh: MeshInstance3D
var _is_rolling: bool = false

# 每个面对应的"使该面朝向 +Z"的旋转（弧度）
const FACE_ROTATIONS := {
	1: Vector3(0, 0, 0),                 # +Z
	6: Vector3(0, PI, 0),                # -Z
	2: Vector3(0, -PI / 2, 0),           # +X
	5: Vector3(0, PI / 2, 0),            # -X
	3: Vector3(-PI / 2, 0, 0),           # +Y (top)
	4: Vector3(PI / 2, 0, 0),            # -Y (bottom)
}

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	clip_contents = true

	# SubViewport 容器
	var vc := SubViewportContainer.new()
	vc.stretch = true
	vc.set_anchors_preset(Control.PRESET_FULL_RECT)
	vc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vc)

	viewport = SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vc.add_child(viewport)

	# 灯光
	var light := DirectionalLight3D.new()
	light.transform = Transform3D().looking_at(Vector3(-0.4, -1, -0.6), Vector3.UP)
	light.light_energy = 1.4
	viewport.add_child(light)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.6
	env.background_mode = Environment.BG_CLEAR_COLOR
	amb.environment = env
	viewport.add_child(amb)

	# 相机
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 4)
	camera.fov = 38.0
	viewport.add_child(camera)

	# 骰子立方体（用 6 个独立 PlaneMesh 组合，每面单独贴材质）
	mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2, 2, 2)
	mesh.mesh = box
	# BoxMesh 只有 1 个 surface，无法给每面单独贴图 → 改用 ImmediateMesh
	# 这里改用 6 个 MeshInstance3D 子节点，分别贴对应面材质
	mesh.mesh = null
	for face_i in 6:
		var quad := PlaneMesh.new()
		quad.size = Vector2(2, 2)
		var inst := MeshInstance3D.new()
		inst.mesh = quad
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.WHITE
		mat.albedo_texture = _make_face_texture(_face_index_to_value(face_i))
		mat.roughness = 0.4
		inst.material_override = mat
		# PlaneMesh 默认在 XZ 平面、法线 +Y。下面把它转到对应方向
		inst.transform = _plane_transform_for_face(face_i)
		mesh.add_child(inst)
	# 初始姿态稍微倾斜
	mesh.rotation = Vector3(deg_to_rad(15), deg_to_rad(-25), 0)
	viewport.add_child(mesh)

func _plane_transform_for_face(face_i: int) -> Transform3D:
	# face_i: 0=+X 1=-X 2=+Y 3=-Y 4=+Z 5=-Z
	var t := Transform3D()
	match face_i:
		0:  # +X
			t = t.rotated(Vector3.FORWARD, -PI / 2).translated(Vector3(1, 0, 0))
		1:  # -X
			t = t.rotated(Vector3.FORWARD, PI / 2).translated(Vector3(-1, 0, 0))
		2:  # +Y (top)
			t = t.translated(Vector3(0, 1, 0))
		3:  # -Y (bottom)
			t = t.rotated(Vector3.RIGHT, PI).translated(Vector3(0, -1, 0))
		4:  # +Z (front, faces camera)
			t = t.rotated(Vector3.RIGHT, PI / 2).translated(Vector3(0, 0, 1))
		5:  # -Z
			t = t.rotated(Vector3.RIGHT, -PI / 2).translated(Vector3(0, 0, -1))
	return t

# BoxMesh 表面顺序：右(+X)/左(-X)/上(+Y)/下(-Y)/前(+Z)/后(-Z)
func _face_index_to_value(face_i: int) -> int:
	match face_i:
		0: return 2  # +X
		1: return 5  # -X
		2: return 3  # +Y
		3: return 4  # -Y
		4: return 1  # +Z (front)
		5: return 6  # -Z
	return 1

func _make_face_texture(value: int) -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.98, 0.98, 0.98))
	# 边缘
	for x in 128:
		img.set_pixel(x, 0, Color(0.85, 0.85, 0.85))
		img.set_pixel(x, 127, Color(0.85, 0.85, 0.85))
	for y in 128:
		img.set_pixel(0, y, Color(0.85, 0.85, 0.85))
		img.set_pixel(127, y, Color(0.85, 0.85, 0.85))
	# 圆点位置
	var positions: Array = _dot_positions(value)
	for p in positions:
		_draw_dot(img, p[0], p[1], 12, Color(0.85, 0.1, 0.1))
	return ImageTexture.create_from_image(img)

func _dot_positions(value: int) -> Array:
	var c := 64
	var l := 30
	var r := 98
	var t := 30
	var b := 98
	match value:
		1: return [[c, c]]
		2: return [[l, t], [r, b]]
		3: return [[l, t], [c, c], [r, b]]
		4: return [[l, t], [r, t], [l, b], [r, b]]
		5: return [[l, t], [r, t], [c, c], [l, b], [r, b]]
		6: return [[l, t], [r, t], [l, c], [r, c], [l, b], [r, b]]
	return []

func _draw_dot(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var x: int = cx + dx
				var y: int = cy + dy
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

func roll_to(value: int) -> void:
	if _is_rolling:
		return
	_is_rolling = true
	var spin_speed := Vector3(deg_to_rad(720), deg_to_rad(900), deg_to_rad(360))
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(SPIN_DURATION * 1000):
		var dt: float = get_process_delta_time()
		mesh.rotation += spin_speed * dt
		await get_tree().process_frame
	# 落定旋转：基础朝向 + 小角度抖动让点数面朝向相机（相机在 +Z）
	var target: Vector3 = FACE_ROTATIONS.get(value, Vector3.ZERO)
	target += Vector3(deg_to_rad(8), deg_to_rad(-10), 0)  # 视觉透视
	var tw := create_tween()
	tw.tween_property(mesh, "rotation", target, FINAL_TWEEN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	_is_rolling = false
	rolled.emit(value)
