#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>

uniform sampler2D InSampler;
layout(std140) uniform SuperstarConfig {
    float Motion;
    float Speed;
};
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;

// Exact horizontal spans and top/bottom heights measured in the original 800x450 PNG.
const vec4 BARS[30]=vec4[](
    vec4(0.0,22.0,59.0,61.0),
    vec4(26.0,49.0,85.0,30.0),
    vec4(53.0,75.0,42.0,45.0),
    vec4(80.0,103.0,51.0,99.0),
    vec4(107.0,129.0,59.0,61.0),
    vec4(133.0,156.0,94.0,23.0),
    vec4(161.0,183.0,42.0,38.0),
    vec4(188.0,210.0,25.0,53.0),
    vec4(215.0,237.0,8.0,91.0),
    vec4(241.0,264.0,59.0,68.0),
    vec4(268.0,291.0,42.0,60.0),
    vec4(295.0,318.0,94.0,98.0),
    vec4(322.0,345.0,102.0,53.0),
    vec4(349.0,372.0,51.0,23.0),
    vec4(376.0,398.0,34.0,68.0),
    vec4(404.0,426.0,59.0,61.0),
    vec4(430.0,453.0,85.0,30.0),
    vec4(457.0,480.0,42.0,45.0),
    vec4(484.0,507.0,51.0,99.0),
    vec4(511.0,534.0,59.0,61.0),
    vec4(538.0,560.0,94.0,23.0),
    vec4(565.0,587.0,42.0,38.0),
    vec4(592.0,614.0,25.0,53.0),
    vec4(618.0,641.0,8.0,91.0),
    vec4(645.0,668.0,59.0,68.0),
    vec4(672.0,695.0,42.0,60.0),
    vec4(699.0,722.0,94.0,98.0),
    vec4(726.0,749.0,102.0,53.0),
    vec4(753.0,776.0,51.0,23.0),
    vec4(780.0,800.0,34.0,68.0));

// Uncut colour ramps, reconstructed from the original opaque bar interiors.
vec3 barGradient(float depth, bool bottom) {
    if (!bottom) {
        vec3 cyan = vec3(10.0, 236.0, 244.0);
        vec3 teal = vec3(60.0, 192.0, 220.0);
        vec3 violet = vec3(112.0, 142.0, 194.0);
        vec3 purple = vec3(164.0, 88.0, 166.0);
        if (depth < 36.0) return mix(cyan, teal, clamp(depth / 36.0, 0.0, 1.0)) / 255.0;
        if (depth < 68.0) return mix(teal, violet, (depth - 36.0) / 32.0) / 255.0;
        return mix(violet, purple, clamp((depth - 68.0) / 34.0, 0.0, 1.0)) / 255.0;
    }
    vec3 cyan = vec3(3.0, 243.0, 248.0);
    vec3 teal = vec3(72.0, 188.0, 219.0);
    vec3 violet = vec3(139.0, 121.0, 182.0);
    vec3 magenta = vec3(196.0, 55.0, 147.0);
    vec3 pink = vec3(211.0, 37.0, 138.0);
    if (depth < 36.0) return mix(cyan, teal, clamp((depth - 16.0) / 20.0, 0.0, 1.0)) / 255.0;
    if (depth < 52.0) return mix(teal, violet, (depth - 36.0) / 16.0) / 255.0;
    if (depth < 68.0) return mix(violet, magenta, (depth - 52.0) / 16.0) / 255.0;
    return mix(magenta, pink, clamp((depth - 68.0) / 8.0, 0.0, 1.0)) / 255.0;
}

void main() {
    vec4 scene = texture(InSampler, texCoord);
    vec2 uv = vec2(texCoord.x, 1.0 - texCoord.y);
    bool bottom = uv.y > 0.5;
    float edge = (bottom ? 1.0 - uv.y : uv.y) * 450.0;
    float x = uv.x * 800.0;
    float aaX = max(fwidth(x) * 0.5, 0.001);
    float aaY = max(fwidth(edge) * 0.5, 0.001);
    if (edge >= 104.0) { fragColor = scene; return; }
    int bar = -1;
    for (int i = 0; i < 30; ++i) {
        if (x >= BARS[i].x - aaX && x < BARS[i].y + aaX) { bar = i; break; }
    }
    if (bar < 0) { fragColor = scene; return; }
    float originalHeight = bottom ? BARS[bar].w : BARS[bar].z;
    float index = float(bar);
    float phase = index * 1.73 + (bottom ? 2.37 : 0.0);
    float seconds = GameTime * 1200.0 * Speed;
    float wave = 0.64 * sin(seconds * (3.3 + 0.35 * sin(index * 1.11)) + phase)
               + 0.36 * sin(seconds * 5.1 - phase * 0.71);
    float height = clamp(originalHeight + 15.0 * clamp(Motion, 0.0, 1.0) * wave, 6.0, 103.0);

    // 1. Animate the uncut gradient rectangle. Only its height and ramp are scaled.
    vec3 colour = barGradient(edge * originalHeight / height, bottom);
    float rectangle = 1.0 - smoothstep(height - aaY, height + aaY, edge);

    // 2. Punch out a stationary screen-space grid LAST. Never use the scaled depth here.
    float pitch = bottom ? 7.5 : 8.5;
    float row = max(0.0, floor((edge - 7.5) / pitch + 0.5));
    float distanceToCut = abs(edge - (7.5 + row * pitch));
    float rows = smoothstep(0.65 - aaY, 0.65 + aaY, distanceToCut);
    float columns = smoothstep(BARS[bar].x - aaX, BARS[bar].x + aaX, x)
                  * (1.0 - smoothstep(BARS[bar].y - aaX, BARS[bar].y + aaX, x));
    float alpha = (191.0 / 255.0) * rectangle * columns * rows;
    fragColor = vec4(mix(scene.rgb, colour, alpha), scene.a);
}
