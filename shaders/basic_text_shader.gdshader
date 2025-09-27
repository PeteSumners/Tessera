shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform sampler2D color_texture : source_color, filter_nearest;

void fragment() {
    // Sample character from atlas
    vec4 char_tex = texture(albedo_texture, UV);
    // Sample color from color atlas
    vec4 color_tex = texture(color_texture, UV2);

    // Combine character and color
    ALBEDO = char_tex.rgb * color_tex.rgb;
    ALPHA = char_tex.a;
}