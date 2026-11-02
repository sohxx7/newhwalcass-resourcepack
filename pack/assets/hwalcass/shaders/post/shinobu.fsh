#version 330
#extension GL_ARB_separate_shader_objects : require
#include <hwalcass:status_hud.glsl>
#include <minecraft:globals.glsl>

uniform sampler2D InSampler;
uniform sampler2D OverlaySampler;
layout(std140) uniform ShinobuConfig {
    float Motion;
    float FrameRate;
};
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    // 상태이상 HUD 카드는 이 효과에 물들지 않게 원래 색 그대로 (include/status_hud.glsl)
    if (statusHudKeep(InSampler, texCoord, fragColor)) return;
    vec4 scene = texture(InSampler, texCoord);
    vec2 uv = vec2(texCoord.x, 1.0 - texCoord.y);
    // Two held drawings, with no crossfade: the original and an outward kick.
    float frame = mod(floor(GameTime * 1200.0 * FrameRate), 2.0);
    vec2 nextUV = 0.5 + (uv - 0.5) / 1.10;
    nextUV.x = 1.0 - nextUV.x;
    vec4 ink = texture(OverlaySampler, mix(uv, nextUV, frame * step(0.5, Motion)));
    fragColor = vec4(mix(scene.rgb, ink.rgb, ink.a), scene.a);
}
