shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled;

uniform sampler2D pixel_texture : filter_nearest;

void fragment() {
    // Sample pixel color from texture
    vec4 pixel = texture(pixel_texture, UV);

    // Apply pixel color with transparency
    ALBEDO = pixel.rgb;
    ALPHA = pixel.a;
}