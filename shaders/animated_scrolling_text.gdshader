shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled;

uniform sampler2D text_layer : filter_nearest;
uniform sampler2D animation_layer : filter_nearest;
uniform float scroll_offset = 0.0;
uniform float content_height_ratio = 1.0;

void fragment() {
	// Scrolled UV for text layer
	vec2 scrolled_uv = UV;
	scrolled_uv.y = scrolled_uv.y * content_height_ratio + scroll_offset;
	scrolled_uv.y = clamp(scrolled_uv.y, 0.0, 1.0);
	
	// Sample both layers
	vec4 text_pixel = texture(text_layer, scrolled_uv);
	vec4 anim_pixel = texture(animation_layer, UV);  // No scroll on animations
	
	// Blend: animations over text
	vec4 final_color = text_pixel;
	final_color = mix(final_color, anim_pixel, anim_pixel.a);
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}