@vs vs
in vec4 position;

void main() {
    gl_Position = vec4(position.xy, 0.0, 1.0);
}
@end

@fs fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0, 0.0, 0.0, 1.0);
}
@end

@program blank vs fs