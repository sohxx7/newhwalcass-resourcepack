#version 330
#extension GL_ARB_separate_shader_objects : require
#include <hwalcass:status_hud.glsl>

uniform sampler2D InSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    // 상태이상 HUD 카드는 이 효과에 물들지 않게 원래 색 그대로 (include/status_hud.glsl)
    if (statusHudKeep(InSampler, texCoord, fragColor)) return;
    fragColor = texture(InSampler, vec2(1.0) - texCoord);
}
