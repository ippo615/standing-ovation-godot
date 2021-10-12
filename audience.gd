extends Spatial

onready var audience_member = load("res://audience_member.tscn")

export var members_wide = 10
export var members_tall = 10


var members = []

# https://lewiscoleblog.com/standing-ovation

# Called when the node enters the scene tree for the first time.
func _ready():
	# We're setting a random seed so we can have deterministic behaviour
	# and can compare things more easily.
	seed(12345)

	# Generate all the people
	for y in range(members_tall):
		var row = []
		for x in range(members_wide):
			# var member = CSGBox.new()
			# member.translate(Vector3(x*2,y*2,0))
			# member.scale = Vector3(0.5, 0.5, 0.5)
			var member = audience_member.instance()
			member.translate(Vector3(x*2,y*2,0))
			row.append(member)
			add_child(member)
		members.append(row)


func get_object_under_mouse():
	# NOTE: We are currently not using this, I just left it as an example
	var RAY_LENGTH = 100
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = $Camera.project_ray_origin(mouse_pos)
	var ray_to = ray_from + $Camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var space_state = get_world().direct_space_state
	var selection = space_state.intersect_ray(ray_from, ray_to)
	return selection


func get_neighbor_pressure(x,y):
	return get_section_pressure([
		Vector2(x-1, y),
		Vector2(x+1, y),
	])


func get_section_pressure(points):
	# Remove any points that fall out of bounds of the array
	var persons = []
	for point in points:
		if point.x < 0: continue
		if point.y < 0: continue
		if point.x >= members_wide: continue
		if point.y >= members_tall: continue
		persons.append(members[point.y][point.x])
	
	# If there are no people...
	# Perhaps we should use a different number
	if len(persons) < 1:
		return 0.0
	
	# Compute the average of all the persons
	var total = 0.0
	for person in persons:
		total += person.value
	
	return total / len(persons)


func get_funnel_pressure(x,y):
	# Neighbors are left/right (aka x); so people in front are y
	var total = 0.0
	var normalization_factor = 0.0
	for yi in range(y-1, 0, -1):

		# The funnel get wider as you move away from the current row
		var delta = y-yi
		var points = [ Vector2(x, yi) ]
		for xi in range(1, delta):
			points.append(Vector2(x-1*xi, yi))
			points.append(Vector2(x+1*xi, yi))

		# We want the influence to decrease with the square of the distance
		# to the current row (ie like gravity).
		var square_factor = 1.0 / (delta*delta)
		total += square_factor * get_section_pressure(points)
		
		normalization_factor += 1.0 / ((delta+1)*(delta+1))

	# Normalize so that everything is in the range 0-1
	if normalization_factor:
		total = total / normalization_factor
	
	return total


func get_total_pressure(x,y):
	var member = members[y][x]
	var pressure = 0.0
	pressure += get_funnel_pressure(x,y) * member.funnel_weight
	pressure += get_neighbor_pressure(x,y) * member.neighbor_weight
	return pressure


func do_time_step():
	# Compute all the new values
	var pressures = []
	for y in range(members_tall):
		var row = []
		for x in range(members_wide):
			row.append(get_total_pressure(x,y))
		pressures.append(row)

	# Update all the members
	for y in range(members_tall):
		for x in range(members_wide):
			var person = members[y][x]
			
			if person.lock:
				continue
			
			# Apply social pressure
			var stand_score = pressures[y][x]
			var sit_score = 1-pressures[y][x]
			person.social_pressure = pressures[y][x]
			if stand_score > person.social_threshold:
				person.seated = false
				person.value = 1.0
				# print('Pressure to stand')
			elif sit_score > person.social_threshold:
				person.seated = true
				person.value = 0.0
				# print('Pressure to sit')
			
			# Apply spontaneous sit/stand, only if not pressured
			else:
				var spontaneous_score = rand_range(0.0, 1.0)
				if person.seated:
					if person.probability_spontaneous_standing > spontaneous_score:
						person.seated = false
						person.value = 1.0
						# print('Random stand')
				if not person.seated:
					if person.probability_spontaneous_sitting > spontaneous_score:
						person.seated = true
						person.value = 0.0
						# print('Random sit')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _physics_process(_delta):
	var hover_member = get_object_under_mouse()
	if hover_member:
		pass
		# hover_member.collider.find_parent('AudienceMember').get_node('MeshInstance').shader_param.albedo = Color(0, 1.0, 0.0)
		# print(hover_member)


func _on_Timer_timeout():
	do_time_step()
