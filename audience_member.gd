extends Spatial

export var seated = true
export var error = 0.5
export var performance_threshold = 0.6
export var social_threshold = 0.6
export var performance_quality = 0.5
export var judgement_error = 0.1
export var value = 0.0
export var neighbor_weight = 0.5
export var funnel_weight = 0.5
export var probability_spontaneous_standing = 0.10
export var probability_spontaneous_sitting = 0.05
var social_pressure = 0.0
var lock = false
var has_mouse = false


func _ready():
	# determine if we are standing initially
	judgement_error = rand_range(-0.5, 0.5)
	value = performance_quality+judgement_error
	if value > performance_threshold:
		seated = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if has_mouse:
		return

	if seated:
		unglow()
	else:
		glow(Color(0.0, 0.0, 1.0))


func _on_StaticBody_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
	var color = Color(1.0, 0.0, 0.0)
	if event is InputEventMouseButton:
		if event.pressed:
			color = Color(0.0, 1.0, 0.0)
			seated = false
			value = 1.0
			lock = true
	
	glow(color)

func _on_StaticBody_mouse_entered():
	glow(Color(1.0, 0.0, 0.0))
	has_mouse = true
	print(value)

func _on_StaticBody_mouse_exited():
	unglow()
	has_mouse = false

func unglow():
	$MeshInstance.material_override = null
	$OmniLight.light_color = Color(0.0, 0.0, 0.0, 0.2)
	$OmniLight.light_energy = 0.0

func glow(color):
	var newMaterial = SpatialMaterial.new()
	newMaterial.albedo_color = Color(color.r, color.g, color.b, 0.2)
	$MeshInstance.material_override = newMaterial
	$OmniLight.light_color = color
	$OmniLight.light_energy = 1.0
	
