extends Node

# applies the modulo operator to each component of the given vector3
static func vector3_modulo(vec3, mod):
	return Vector3(fmod(vec3.x, mod), fmod(vec3.y, mod), fmod(vec3.z, mod))
