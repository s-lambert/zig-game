@vs post_vs
in vec2 position;
in vec2 texcoord;

out vec2 uv;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    uv = texcoord;
}
@end

@fs post_fs
layout(binding=0) uniform texture2D offscreen_texture;
layout(binding=0) uniform sampler offscreen_sampler;

in vec2 uv;

out vec4 frag_color;

void main() {
    float aberration = 0.01; // Adjust this value to control the effect strength
    
    // Sample the texture with offset for each color channel
    vec4 red = texture(sampler2D(offscreen_texture, offscreen_sampler), vec2(uv.x + aberration, uv.y));
    vec4 green = texture(sampler2D(offscreen_texture, offscreen_sampler), uv);
    vec4 blue = texture(sampler2D(offscreen_texture, offscreen_sampler), vec2(uv.x - aberration, uv.y));
    
    frag_color = vec4(red.r, green.g, blue.b, 1.0);
}
@end

@program post post_vs post_fs