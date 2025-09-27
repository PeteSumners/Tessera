shader_type sky;
render_mode use_debanding;

uniform vec3 sun_position = vec3(0.0, 1.0, 0.0);
uniform vec4 sky_top_color : source_color = vec4(0.3, 0.5, 0.95, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.6, 0.8, 0.95, 1.0);
uniform float sun_size = 0.2;
uniform float sun_blur = 0.01;

void sky() {
	float atmosphere_height = 50.0;
	float sun_power = 20.0;

	// Get our direction
	vec3 dir = EYEDIR;

	// Sun
	float sun_dot = dot(normalize(sun_position), dir);
	float sun_factor = smoothstep(1.0 - sun_size - sun_blur, 1.0 - sun_size + sun_blur, sun_dot);
	vec3 sun = vec3(1.0, 0.95, 0.8) * sun_factor * sun_power;

	// Sky gradient
	float sky_gradient = 1.0 - (normalize(dir).y * 0.5 + 0.5);
	sky_gradient = pow(sky_gradient, 0.5);
	vec3 sky = mix(sky_top_color.rgb, sky_horizon_color.rgb, sky_gradient);

	// Combine
	COLOR = sky + sun;
}