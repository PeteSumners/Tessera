extends Node3D

func _ready():
	var world_env = WorldEnvironment.new()
	add_child(world_env)

	var env = Environment.new()
	world_env.environment = env

	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.2, 0.4, 0.8)
	sky_material.sky_horizon_color = Color(0.8, 0.9, 1.0)
	sky_material.sky_curve = 0.5
	sky.sky_material = sky_material

	env.background_mode = Environment.BG_SKY
	env.sky = sky

	# Remove all ambient and environment lighting
	env.ambient_light_energy = 0.0
	env.ambient_light_color = Color(0, 0, 0, 1)
	env.ambient_light_sky_contribution = 0.0
	env.sdfgi_read_sky_light = false

	# Disable reflections
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED

	# Optional: disable fog and glow for a flat, unlit environment
	env.fog_enabled = false
	env.glow_enabled = false
