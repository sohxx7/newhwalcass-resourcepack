#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D InSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 scene = texture(InSampler, texCoord);
    // Keep the world upright. Muted dark red/green avoid full-screen neon glare.
    float luminance = dot(scene.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 darkRed = vec3(120.0, 44.0, 48.0) / 255.0;
    vec3 darkGreen = vec3(53.0, 105.0, 67.0) / 255.0;
    vec3 colour = luminance >= 0.45 ? darkGreen : darkRed;
    fragColor = vec4(colour, scene.a);
}
