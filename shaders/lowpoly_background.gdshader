shader_type sky;
render_mode use_debanding;

uniform vec4 color1 : source_color = vec4(0.2, 0.3, 0.5, 1.0);
uniform vec4 color2 : source_color = vec4(0.3, 0.4, 0.6, 1.0);
uniform vec4 color3 : source_color = vec4(0.4, 0.5, 0.7, 1.0);
uniform float scale = 8.0;
uniform float speed = 1.0;
uniform float time;

// Hash function for pseudo-random values
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 voronoi(vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);
    vec2 mg, mr;
    float md = 8.0;

    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(hash(n + g));
            o = 0.5 + 0.5 * sin(time * speed + 6.2831 * o);

            vec2 r = g + o - f;
            float d = dot(r, r);
            if(d < md) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }
    return vec2(md, hash(n + mg));
}

void sky() {
    // Get direction
    vec3 dir = normalize(EYEDIR);

    // Convert to panoramic UV coordinates
    vec2 uv = vec2(atan(dir.x, dir.z), acos(dir.y)) * scale;

    // Create cellular background
    vec2 v = voronoi(uv);
    float t = v.y;

    // Color gradient
    vec3 color;
    if(t < 0.33) {
        color = mix(color1.rgb, color2.rgb, t * 3.0);
    } else if(t < 0.66) {
        color = mix(color2.rgb, color3.rgb, (t - 0.33) * 3.0);
    } else {
        color = color3.rgb;
    }

    // Add cell edges
    float edge = 1.0 - smoothstep(0.0, 0.05, v.x);
    color = mix(color, vec3(1.0), edge * 0.3);

    // Add subtle animation
    float pulse = sin(time * speed) * 0.1;
    color = mix(color, color + 0.2, pulse);

    COLOR = color;
}