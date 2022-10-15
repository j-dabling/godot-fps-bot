extends KinematicBody


var debug = false # Change to 'true' if you want to see messages output to the
# console that explain some of the process of Carl's logic.

### Node References ###
onready var head = get_node("Head")
onready var los = get_node("Head/Line_of_Sight")

### Movement vars ###
export var walk_speed = 15
export var acceleration = 0.2
export var gravity = 75
export var reach_tolerance = 2
var velocity = Vector3.ZERO

### Behavior Vars ###
enum {idle, advance, combat, retreat, cover} # Each of the behavior states.
#     0     1        2       3        4
# The status, or desirability, of each behavior state.
export var status = [0.0, 0.0, 0.0, 0.0, 0.0]
# Weights that will influence the status as they are calculated.
export var weights = [0.1, 0.1, 0.1, 10, 0.1]
var active_state : int = idle

var proximity = []
var fov = []
var objectives = []
var active_objective = Vector3.ZERO


func _process(delta) -> void:
# Run every frame of the game.
# Evaluates surroundings and weighs the state machine accordingly.
	_check_proximity()
	var closest_body = _check_fov()
	_check_objective()

	# Determines the active state from the current status and weights.
	var heaviest_state = -1
	for current_state in range(0,4):
		if status[current_state] > heaviest_state:
			heaviest_state = status[current_state]
			active_state = current_state
	
	if debug:
		print("Current active state is: ", active_state)

	match active_state:
		advance:
			if !_has_reached_position(active_objective):
				var advance_vector = _face_towards(active_objective)
				move(delta, advance_vector) 
		combat:
			_face_towards(closest_body.transform.origin)
			move(delta)
		retreat:
			# Future implimentations may involve additional logic to face
			# the enemy and move backwards, or full turn and run.
			if len(proximity) > 0:
				var retreat_vector = _face_towards(proximity[0].transform.origin)
				move(delta, -(retreat_vector))
		cover:
			pass
		_: # The default state is to idle.
			move(delta)


func _face_towards(focus: Vector3) -> Vector3:
# Will orient the body and head to face towards 'focus'.
# Returns the resulting direction vector.
	var direction = self.transform.origin.direction_to(focus)
	head.look_at(focus, Vector3.UP)
	return direction


func _check_proximity() -> KinematicBody:
# Check every body object in proximity list, updates state machine status
# according to their distance and quantity.
# Returns: The closest body in proximity.
	var closest_dist: float = 1000
	var closest_body: KinematicBody
	var proximity_sum: float = 0
	for body in proximity:
		var distance = self.translation.distance_to(body.transform.origin)
		proximity_sum += distance
		if distance < closest_dist:
			closest_body = body
			closest_dist = distance
	status[retreat] = proximity_sum * weights[retreat]
	return closest_body


func _check_fov() -> KinematicBody:
# Goes over every body in 'fov' and influences the combat state status.
# Returns the closest body in FOV.
	status[combat] = len(fov)
	var closest_body = null
	var closest_dist = 1000
	for body in fov:
		var body_dist = self.translation.distance_to(body.translation)
		status[combat] += abs(body_dist - weights[combat])
		if body_dist < closest_dist:
			closest_body = body
			closest_dist = body_dist
	if los.is_colliding():
		print("Carl's raycast is colliding with something!")
	return closest_body


func _check_objective() -> void:
# Checks the objectives list and selects the latest entered element as 'active'.
# If 'active_objective' is greater than 'reach_tolerance', then the 'advance'
# state increases to signal to go closer.
	if len(objectives) > 0:
		active_objective = objectives.pop_back()
		if active_objective:
			var objective_dist = self.translation.distance_to(active_objective)
			if objective_dist > 5:
				status[advance] = (objective_dist/100) * weights[advance]


func _has_reached_position(pos) -> bool:
# Checks if the current position is close enough to 'pos' to have arrived there.
# Returns true if it has reached, false otherwise.
	return self.transform.origin.distance_to(pos) <= reach_tolerance


func move(delta: float, direction:= Vector3.ZERO) -> void:
# Given 'delta' (framerate), and 'direction' (Vector3),
# will apply gravity and motion to 'velocity' and move around
# the environment.
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x += direction.x * acceleration
		velocity.z += direction.z * acceleration
	else:
		if velocity.length() > acceleration:
			velocity -= velocity.normalized() * acceleration
		else:
			velocity = Vector3.ZERO
	
	velocity.y -= gravity * delta
	velocity = move_and_slide(velocity)


func _on_Proximity_body_entered(body) -> void:
# Adds bodies that enter into Proximity area to 'proximity' list.
	if body.is_in_group("player") or body.is_in_group("bot"):
		if body != self:
			proximity.append(body)


func _on_Proximity_body_exited(body) -> void:
# Removes bodies from 'proximity' that have left the Proximity area.
	if body.is_in_group("player") or body.is_in_group("bot"):
		proximity.erase(body)


func _on_Field_of_View_body_entered(body) -> void:
# Adds any body entered into 'Field_of_View' into the 'fov' list.
	if body.is_in_group("player") or body.is_in_group("bot"):
		if body != self:
			fov.append(body)


func _on_Field_of_View_body_exited(body) -> void:
# Removes bodies from 'fov' that have left 'Field_of_View'.
# If the body that left was the current focus, or 'active_objective', it will
# add the last seen position of it to 'objectives'.
	if body.is_in_group("player") or body.is_in_group("bot"):
		print("Thing has left my sight!")
		if body == _check_fov() && active_state == combat:
			objectives.append(active_objective)
			if debug:
				print("Last known position: ", active_objective)
		fov.erase(body)

