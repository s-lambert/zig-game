@header const m = @import("../math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding=0) uniform vs_params {
    mat4 projection;    // 2D orthographic projection
};

in vec2 position;      // 2D position
in vec2 texcoord;      // Texture coordinates
in vec2 sprite_pos;    // Per-instance sprite position
in vec2 sprite_scale;  // Per-instance sprite scale

out vec2 v_texcoord;

void main() {
    vec2 pos = position * sprite_scale + sprite_pos;

    gl_Position = projection * vec4(pos, 0.0, 1.0);

    v_texcoord = texcoord;
}
@end

@fs fs
layout(binding=1) uniform fs_params {
    vec4 sprite_rect;
};
layout(binding=2) uniform texture2D sprite_tex;
layout(binding=3) uniform sampler sprite_smp;

in vec2 v_texcoord;

out vec4 frag_color;

void main() {
    vec2 final_uv = sprite_rect.xy + (v_texcoord * sprite_rect.zw);

    frag_color = texture(sampler2D(sprite_tex, sprite_smp), final_uv);
}
@end

@program sprites vs fs