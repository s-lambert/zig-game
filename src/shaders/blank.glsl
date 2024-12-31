@vs vs
out vec2 v_texcoord;

layout(binding=2) uniform vs_params {
    vec4 sprite_rect;  // x, y, w, h in UV coordinates (0-1 range)
};

void main() {
    const vec2 positions[3] = vec2[3](
        vec2(-1.0, -1.0),
        vec2( 3.0, -1.0),
        vec2(-1.0,  3.0)
    );

    vec2 base_uv = positions[gl_VertexIndex] * 0.5 + 0.5;
    
    v_texcoord = vec2(
        sprite_rect.x + (base_uv.x * sprite_rect.z),
        sprite_rect.y + (base_uv.y * sprite_rect.w)
    );
    
    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
}
@end

@fs fs
layout(binding=0) uniform texture2D sprite_texture;
layout(binding=1) uniform sampler sprite_sampler;

in vec2 v_texcoord;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(sprite_texture, sprite_sampler), v_texcoord);
}
@end

@program blank vs fs