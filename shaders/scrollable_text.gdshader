shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled;

uniform sampler2D content_texture : filter_nearest;
uniform float scroll_offset = 0.0;  // Normalized [0,1]
uniform float content_height_ratio = 1.0;  // content_height / viewport_height

void fragment() {
	// Apply scroll offset to V coordinate
	vec2 scrolled_uv = UV;
	scrolled_uv.y = scrolled_uv.y * content_height_ratio + scroll_offset;
	
	// Clamp to prevent sampling outside texture
	scrolled_uv.y = clamp(scrolled_uv.y, 0.0, 1.0);
	
	vec4 pixel = texture(content_texture, scrolled_uv);
	ALBEDO = pixel.rgb;
	ALPHA = pixel.a;
}