shader_type spatial;
render_mode blend_mix,depth_prepass_alpha,cull_back,unshaded;

uniform sampler2D texture_map : filter_nearest;
uniform float tiling_scale = 1.0;
uniform int texture_sheet_width = 6;
uniform int face_tile_index = 0;

void fragment() {
    // Tile the UVs (repeats every unit)
    vec2 tiled_uv = fract(UV * tiling_scale);

    // Atlas sub-tile size and offset
    float sub_width = 1.0 / float(texture_sheet_width);
    float offset = float(face_tile_index) * sub_width;

    // Sample from the selected tile
    vec2 atlas_uv = vec2(tiled_uv.x * sub_width + offset, tiled_uv.y);
    vec4 tex_color = texture(texture_map, atlas_uv);

    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
}