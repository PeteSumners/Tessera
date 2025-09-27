extends CharacterBody3D
class_name PhysicsObject 

const world_gravity = 9.8 # in m/s^2
var gravity = 0 # in m/s^2
var mass = 1.0 # in kg
var floor_friction_decel = 1.0 # in m/s^2

var do_physics = false # only do physics if specifically requested (default to no physics)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not do_physics: return
	velocity += Vector3.DOWN * gravity * delta # predict velocity
	position += (velocity * delta) # predict position
	move_and_slide() # to move/collide with, and slide across the environment
	apply_friction(delta)

# applies relevant friction
func apply_friction(delta):
	# helper method: can be used to do non-physics movement
	if not is_on_floor(): return
	if velocity.length_squared() > .01: velocity = Vector3.ZERO # special case: low speed
	velocity -= velocity.normalized()*floor_friction_decel*delta


# apply an impulse (change in momentum) to the Physics object
func apply_impulse(impulse):
	if not do_physics: return # no momentum change if static object
	velocity += impulse/mass
