@header const m = @import("../math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding=0) uniform vs_params {
    float draw_mode;
    float time;
    mat4 mvp;
};

in vec4 position;
in vec3 normal;
in vec2 texcoord;
in vec4 color0;

out vec4 color;

void main() {
    gl_Position = mvp * position;
    if (draw_mode == 0.0) {
        // Original normal-based color
        vec4 normalColor = vec4((normal + 1.0) * 0.5, 1.0);
        
        // Time-varying color
        vec4 dynamicColor = vec4(
            abs(sin(time)),        // Red component
            abs(cos(time * 1.3)),  // Green component
            abs(sin(time * 0.7)),  // Blue component
            1.0
        );
        
        // Mix the two colors (0.5 means equal blend)
        color = mix(normalColor, dynamicColor, 0.5);
    }
    else if (draw_mode == 1.0) {
        color = vec4(texcoord, 0.0, 1.0);
    }
    else {
        color = color0;
    }
}
@end

@fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program shapes vs fs