@vs vs
layout(binding=0) uniform vs_params {
    vec2 screen_size;
};

in vec2 position;
in vec2 texcoord;
in int texture_index;

out vec2 v_texcoord;
flat out int v_texture_index;

void main() {
    // Convert pixel coordinates to clip space
    vec2 clip_pos = (position / screen_size) * 2.0 - 1.0;
    clip_pos.y = -clip_pos.y;
    
    v_texcoord = texcoord;
    v_texture_index = texture_index;
    gl_Position = vec4(clip_pos, 0.0, 1.0);
}
@end

@fs fs
layout(binding=0) uniform texture2D tile_texture;
layout(binding=1) uniform texture2D player_texture;
layout(binding=2) uniform texture2D dungeon_texture;
layout(binding=0) uniform sampler sprite_sampler;

in vec2 v_texcoord;
flat in int v_texture_index;

out vec4 frag_color;

void main() {
    vec4 color;
    switch(v_texture_index) {
        case 0: color = texture(sampler2D(tile_texture, sprite_sampler), v_texcoord); break;
        case 1: color = texture(sampler2D(player_texture, sprite_sampler), v_texcoord); break;
        case 2: color = texture(sampler2D(dungeon_texture, sprite_sampler), v_texcoord); break;
        default: color = vec4(1.0, 0.0, 0.0, 1.0);
    }

    frag_color = color;
}
@end

@program blank vs fs