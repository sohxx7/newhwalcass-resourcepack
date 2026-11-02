#ifndef HWALCASS_STATUS_HUD_GLSL
#define HWALCASS_STATUS_HUD_GLSL

// 상태이상 HUD 공용 계산 (shaders/post/status_icon.fsh, 그리고 화면 전체를 바꾸는 다른 효과들)
// 카드 줄: 오른쪽 위, 칸 0 = 오른쪽 끝. 크기는 화면 높이 기준(1080p 에서 카드 52px).
// 그려진 카드는 위쪽 가운데의 서명 픽셀 2개로 알아본다.
// 다른 효과는 main 앞에서 statusHudKeep 을 불러, 이미 그려진 카드 픽셀은 원래 색 그대로 둔다
// (흑백·반전·왜곡이 카드를 바꾸면 서명이 깨져서 뒤에 붙는 상태이상이 카드 수를 못 센다).

const int STATUS_SLOTS = 6;
const vec3 STATUS_SIG0 = vec3(28.0, 30.0, 38.0) / 255.0;
const vec3 STATUS_SIG1 = vec3(30.0, 28.0, 38.0) / 255.0;

struct StatusLayout {
    ivec2 size;     // 화면 텍셀 수
    int card;       // 카드 한 변
    int step;       // 칸 간격 (카드 + 틈)
    int right;      // 화면 오른쪽 ~ 칸 0 카드 오른쪽
    int top;        // 화면 위 ~ 카드 위
    float radius;   // 모서리 반지름
    ivec2 sig;      // 카드 안 서명 위치 (왼쪽 위 원점)
};

int statusPx(float v, float unit) {
    return max(1, int(floor(v * unit + 0.5)));
}

StatusLayout statusLayout(ivec2 size) {
    float unit = float(size.y) / 1080.0;
    StatusLayout L;
    L.size = size;
    L.card = statusPx(52.0, unit);
    L.step = statusPx(58.0, unit);
    L.right = statusPx(16.0, unit);
    L.top = statusPx(15.0, unit);
    L.radius = 9.0 * unit;
    L.sig = ivec2(L.card / 2, statusPx(4.5, unit));
    return L;
}

// 둥근 사각형 안쪽 정도 (1 = 완전히 안, 0 = 밖). l = 카드 안 픽셀
float statusCoverage(StatusLayout L, ivec2 l) {
    vec2 p = vec2(l) + 0.5 - float(L.card) * 0.5;
    vec2 q = abs(p) - (float(L.card) * 0.5 - L.radius);
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - L.radius;
    return clamp(0.5 - d, 0.0, 1.0);
}

// 텍셀 t(아래쪽 원점)가 몇 번 칸 카드의 어느 픽셀인지. 카드 밖이면 false
bool statusLocate(StatusLayout L, ivec2 t, out int k, out ivec2 l, out float cov) {
    k = 0;
    l = ivec2(0);
    cov = 0.0;
    int row = L.size.y - 1 - t.y;
    if (row < L.top || row >= L.top + L.card) return false;
    int dx = (L.size.x - L.right - 1) - t.x;
    if (dx < 0 || dx >= L.step * STATUS_SLOTS) return false;
    k = dx / L.step;
    int inStep = dx - k * L.step;
    if (inStep >= L.card) return false;
    l = ivec2(L.card - 1 - inStep, row - L.top);
    cov = statusCoverage(L, l);
    return cov > 0.0;
}

bool statusSigAt(sampler2D s, ivec2 t, vec3 c) {
    return all(lessThan(abs(texelFetch(s, t, 0).rgb - c), vec3(0.5 / 255.0)));
}

// 칸 0 부터 연속으로 그려진 카드 수
int statusCount(sampler2D s, StatusLayout L) {
    int n = 0;
    for (int i = 0; i < STATUS_SLOTS; i++) {
        ivec2 t = ivec2(L.size.x - L.right - L.card - i * L.step + L.sig.x, L.size.y - 1 - (L.top + L.sig.y));
        if (!statusSigAt(s, t, STATUS_SIG0) || !statusSigAt(s, t + ivec2(1, 0), STATUS_SIG1)) break;
        n++;
    }
    return n;
}

ivec2 statusTexel(sampler2D s, vec2 uv) {
    ivec2 size = textureSize(s, 0);
    return min(ivec2(uv * vec2(size)), size - 1);
}

// 다른 효과용: uv 가 이미 그려진 카드 위면 원래 색을 color 에 넣고 true
bool statusHudKeep(sampler2D s, vec2 uv, out vec4 color) {
    color = vec4(0.0);
    StatusLayout L = statusLayout(textureSize(s, 0));
    ivec2 t = statusTexel(s, uv);
    int k;
    ivec2 l;
    float cov;
    if (!statusLocate(L, t, k, l, cov)) return false;
    if (k >= statusCount(s, L)) return false;
    color = texelFetch(s, t, 0);
    return true;
}

#endif
