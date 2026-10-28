#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>

uniform sampler2D InSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

// Sparse diagonal streaks with different phases, lengths and speeds.
// Coordinates are measured in screen heights, so rain keeps its shape at any aspect ratio.
float rainLayer(vec2 uv, float seconds, float density, float speed, float seed) {
    vec2 p = vec2(uv.x * ScreenSize.x / max(ScreenSize.y, 1.0), uv.y);
    p.x -= p.y * 0.13;
    float lane = floor(p.x * density);
    float random = hash21(vec2(lane, seed));
    float x = fract(p.x * density);
    float center = 0.18 + random * 0.64;
    float width = max(density / max(ScreenSize.y, 1.0) * 0.65, 0.008);
    float line = 1.0 - smoothstep(width * 0.25, width, abs(x - center));
    // Texture coordinates rise upward: a positive time phase makes the streak fall.
    float y = fract(p.y * 2.0 + seconds * speed * (0.7 + random * 0.6) + random * 19.0);
    float length = 0.07 + random * 0.13;
    float streak = smoothstep(0.0, 0.018, y) * (1.0 - smoothstep(0.025, length, y));
    return line * streak * smoothstep(0.25, 0.55, random);
}

void main() {
    vec4 scene = texture(InSampler, texCoord);
    float seconds = GameTime * 1200.0;
    float gray = dot(scene.rgb, vec3(0.2126, 0.7152, 0.0722));
    // Gentle print contrast and a little lifted black, retaining dark-scene visibility.
    gray = clamp((gray - 0.5) * 1.06 + 0.5, 0.0, 1.0) * 0.96 + 0.015;
    vec2 center = texCoord * 2.0 - 1.0;
    gray *= 1.0 - 0.075 * smoothstep(0.25, 1.7, dot(center, center));
    float frame = floor(seconds * 24.0);
    float grain = hash21(floor(gl_FragCoord.xy) + vec2(frame * 17.0, frame * 7.0)) - 0.5;
    gray += grain * 0.028;
    float rain = rainLayer(texCoord, seconds, 48.0, 1.3, 13.0) * 0.18;
    rain += rainLayer(texCoord, seconds, 28.0, 1.8, 71.0) * 0.24;
    // Keep a little rain in the centre, but let the action remain readable.
    rain *= mix(0.60, 1.0, smoothstep(0.10, 1.2, dot(center, center)));
    gray = mix(gray, 0.96, clamp(rain, 0.0, 0.32));
    fragColor = vec4(vec3(clamp(gray, 0.0, 1.0)), scene.a);
}
