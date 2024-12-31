@vs vs
layout(binding=2) uniform vs_params {
    vec2 screen_size;
};

in vec2 position;
in vec2 texcoord;
out vec2 v_texcoord;

void main() {
    // Convert pixel coordinates to clip space
    vec2 clip_pos = (position / screen_size) * 2.0 - 1.0;
    clip_pos.y = -clip_pos.y;
    
    v_texcoord = texcoord;
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