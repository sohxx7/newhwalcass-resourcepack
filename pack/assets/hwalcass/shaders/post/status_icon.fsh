#version 330
#extension GL_ARB_separate_shader_objects : require
#include <hwalcass:status_hud.glsl>

// 상태이상 HUD 카드 한 장. 효과 hwalcass:status/<종류> 하나당 이 패스가 한 번 돈다.
//
// 서버는 걸릴 때 posteffect add, 풀릴 때 remove 만 한다. 클라의 효과 목록은 add 한 순서를 유지하므로
// 패스도 그 순서로 돈다. 각 패스는 매 프레임
//   1) 오른쪽 위 줄에 이미 몇 장 그려졌는지 센다 (카드마다 박아 둔 서명 픽셀 2개로 판별)
//   2) 그려진 카드들을 한 칸씩 왼쪽으로 옮기고
//   3) 자기를 오른쪽 끝(칸 0)에 그린다
// → 가장 최근 것이 오른쪽 끝, 먼저 걸린 것일수록 왼쪽. 풀리면 다음 프레임부터 자동으로 빈칸이 메워진다.
// 옮기기는 정수 픽셀 texelFetch 복사라 서명이 그대로 따라간다. 배치·판별은 include/status_hud.glsl.

uniform sampler2D InSampler;
uniform sampler2D IconSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    StatusLayout L = statusLayout(textureSize(InSampler, 0));
    ivec2 t = statusTexel(InSampler, texCoord);
    vec4 scene = texelFetch(InSampler, t, 0);
    fragColor = scene;

    int k;
    ivec2 l;
    float cov;
    if (!statusLocate(L, t, k, l, cov)) return;

    if (k == 0) {
        vec4 c = texture(IconSampler, (vec2(l) + 0.5) / float(L.card));
        vec3 rgb = mix(scene.rgb, c.rgb, c.a);
        if (l == L.sig) rgb = STATUS_SIG0;
        if (l == L.sig + ivec2(1, 0)) rgb = STATUS_SIG1;
        fragColor = vec4(rgb, scene.a);
    } else if (k <= statusCount(InSampler, L)) {
        // 오른쪽 칸(k-1)의 같은 자리를 그대로 가져온다
        vec4 src = texelFetch(InSampler, t + ivec2(L.step, 0), 0);
        fragColor = vec4(mix(scene.rgb, src.rgb, cov), scene.a);
    }
}
