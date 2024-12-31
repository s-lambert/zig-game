@vs vs
in vec4 position;

void main() {
    const vec2 positions[3] = vec2[3](
        vec2(-1.0, -1.0),  // Index 0
        vec2( 3.0, -1.0),  // Index 1
        vec2(-1.0,  3.0)   // Index 2
    );

    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
}
@end

@fs fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0, 0.0, 0.0, 1.0);
}
@end

@program blank vs fs