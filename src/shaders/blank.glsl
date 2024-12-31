@vs vs
out vec2 v_texcoord;

layout(binding=2) uniform vs_params {
    vec4 sprite_rect;  // x, y, w, h in UV coordinates (0-1 range)
    vec2 screen_size;
};

void main() {
    // Define vertices for a quad using a LUT
    const vec2 positions[6] = vec2[6](
        vec2(0.0,  64.0),  // First triangle: bottom-left, bottom-right, top-left
        vec2(64.0, 64.0),
        vec2(0.0,  0.0),
        vec2(64.0, 64.0),  // Second triangle: bottom-right, top-right, top-left
        vec2(64.0, 0.0),
        vec2(0.0,  0.0)
    );

    const vec2 uvs[6] = vec2[6](
        vec2(0.0, 1.0),  // First triangle
        vec2(1.0, 1.0),
        vec2(0.0, 0.0),
        vec2(1.0, 1.0),  // Second triangle
        vec2(1.0, 0.0),
        vec2(0.0, 0.0)
    );
    
    // Convert pixel coordinates to clip space (-1 to 1)
    vec2 pos = positions[gl_VertexIndex];
    vec2 clip_pos = (pos / screen_size) * 2.0 - 1.0;

    // Flip Y coordinate because pixel coordinates are top-down
    clip_pos.y = -clip_pos.y;
    
    // Transform UV to sample from the correct part of the spritesheet
    v_texcoord = vec2(
        sprite_rect.x + (uvs[gl_VertexIndex].x * sprite_rect.z),
        sprite_rect.y + (uvs[gl_VertexIndex].y * sprite_rect.w)
    );
    
    gl_Position = vec4(clip_pos, 0.0, 1.0);
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