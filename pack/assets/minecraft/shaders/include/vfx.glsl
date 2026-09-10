#version 150

// ============================================================================
//  VFX core-shader framework          Minecraft 1.21.8  (pack_format 64, G3)
// ============================================================================
//
//  [활카스 사본] 1.21.8vfx 의 vfx.glsl 을 감시자 궁(지켜보는 눈)용으로 가져온 것.
//  ogresourcepack 의 SPD 셰이더와 한 파일에서 공존해야 하므로 두 가지를 더 걸었다.
//    - 빌보드는 염색색의 시작틱 필드가 VFX_BB_KEY 이고 틴트가 흰색일 때만 켠다.
//      활카스엔 염색 아이템이 많아, 아무 색이나 빌보드로 오해하면 다른 모델이 깨진다.
//    - VIEWPOINT 판의 기본 반변을 1.125 로 두어 variant 2 가 지름 4.5 (궁 최종 크기) 가 되게 했다.
//  원본 프로젝트(C:/단타/1.21.8vfx)의 도구·주석 규칙은 그대로다.
//
//  판 하나에 원시 기능을 겹쳐서 건다.
//
//    투명도   서버가 값을 밀어 넣는다. 어떤 효과든 항상 쓸 수 있다
//    틴트     그림 색에 곱한다. 어떤 효과든 항상 쓸 수 있다
//    각도     0~360도 중 지나간 구간만 남긴다.  한 번 던지면 알아서 돈다
//    크롭     한 축 방향으로 자라났다 지워진다. 찌부되지 않고 잘린다
//    빌보드   정점을 다시 배치해 판을 카메라 쪽으로 돌린다
//
//  각도와 크롭은 같은 판에 같이 걸 수 없다 (효과 종류가 하나다).
//  투명도와 틴트는 종류와 무관하게 언제나 걸린다.
//  빌보드는 그 셋 어디에나 겹쳐 걸 수 있다 (기하만 건드리므로).
//
// ---------------------------------------------------------------------------
//  매직값 등록부  --  고칠 때는 반드시 여기부터 고친다
//  (vfx.sk 의 options, tools/sign_texture.py 와 짝이다. 하나만 고치면 어긋난다)
// ---------------------------------------------------------------------------
//
//  통로 네 개
//    텍스처 네 모서리   이게 VFX 인지, 그리고 효과 종류  (프래그먼트만 읽을 수 있다)
//    염색색 24비트      시작 틱 / 빌보드 모드 / variant / 틴트
//    brightness (UV2)   투명도 8비트
//    Normal             빌보드 축. 엔티티 변환이 먹은 월드 공간 방향
//
//  염색색 비트 배치 (r 이 상위 바이트)
//     [23:17]  7비트  시작 틱        0 ~ VFX_PERIOD-1
//     [16:14]  3비트  빌보드 모드    VFX_BB_*
//     [13:12]  2비트  variant       뜻이 상황마다 다르다 (아래)
//     [11: 8]  4비트  틴트 R
//     [ 7: 4]  4비트  틴트 G
//     [ 3: 0]  4비트  틴트 B
//
//  variant 의 뜻
//     빌보드 모드가 FIXED 일 때   효과 종류별 -- 크롭이면 방향 0~3, 원호면 bit0 = 반전
//     빌보드 모드가 그 외일 때    판 크기 배율 0.5 / 1 / 2 / 4
//
//  왜 효과 종류를 셰이더가 아니라 텍스처에 싣나:
//    종류는 그림의 성질이다. 원호 그림은 언제나 원호다.
//    다만 텍스처는 프래그먼트만 읽을 수 있다 (스프라이트 사각형이 필요한데
//    그건 정점이 흘려보낸 코너를 보간해야 나오므로). 그래서 기하를 바꾸는
//    빌보드 모드는 텍스처가 아니라 반드시 염색색에 있어야 한다.
//
//  왜 스케일에 싣지 않나:
//    디스플레이 엔티티의 transformation 은 CPU 에서 정점 좌표에 미리 구워진다.
//    셰이더의 ModelViewMat 은 카메라 변환뿐이라 엔티티 스케일이 들어 있지 않고,
//    Position 도 모델 공간이 아니라 카메라 상대 월드 좌표다.
//    -> 스케일도 모델 좌표도 셰이더에서 읽을 수 없다.
//
//    카메라가 원점이라는 건 오히려 이득이다. 시선 벡터가 그냥 -Position 이다.
// ============================================================================

// 0  끈다
// 1  서명이 통과한 판을 마젠타 단색으로 (마스크 계산을 전부 건너뛴다)
// 2  서명 통과는 마젠타, 통과 못 한 판은 시안
// 3  Normal 을 색으로 (축 통로가 실제로 월드 회전을 물고 오는지 확인)
//      판을 놓고 플레이어가 돌았을 때 색이 안 변하면 -> 축 통로가 안 되는 것
// 4  코너 번호를 색으로 (gl_VertexID % 4 매핑 확인)
//      0 빨강  1 초록  2 파랑  3 노랑.  각 화면 모서리에 그 색이 몰린다
#define VFX_DEBUG 0


// ---------------------------------------------------------------------------
//  서명 -- 텍스처 네 모서리의 픽셀
// ---------------------------------------------------------------------------
// 염색색은 다른 아이템도 가질 수 있는 값이라 확률 싸움을 벗어날 수 없다.
// 텍스처는 다르다. 이 색 조합은 우리 그림에만 있으므로 거짓 양성이 0 이다.
// (바닐라 텍스처 3392장 850만 픽셀에 SIG_A 색은 단 한 번도 나오지 않는다.)
//
// 왜 하나가 아니라 네 모서리인가:
//   쿼드는 삼각형 두 개(0,1,2 / 2,3,0)로 쪼개진다.
//   - flat varying 은 provoking vertex(마지막 정점) 값만 가져가므로
//     삼각형마다 다른 정점을 본다 -> 한 곳에만 값을 두면 절반만 맞는다
//   - 꼭짓점 1 이나 3 에 값을 두면 그 정점이 없는 삼각형은 0 으로 보간된다
//   네 곳 모두에 두면 어느 정점이든 어느 대각선이든 같은 답이 나온다.
//
// 알파는 1/255 다. VFX_ALPHA_CUT 보다 작아 화면에는 절대 안 나온다.
#define VFX_SIG_A   ivec3(75, 125, 226)
#define VFX_SIG_B_G 47
#define VFX_SIG_B_B 81

#define VFX_TYPE_NONE 0    // 투명도와 틴트만
#define VFX_TYPE_ARC  1    // 각도 마스크
#define VFX_TYPE_CROP 2    // 크롭 마스크
#define VFX_TYPE_MAX  2

// 샘플러를 인자로 안 받는다 -- 이 헤더는 정점 셰이더도 포함하는데
// Sampler0 은 프래그먼트에만 있다. 읽어 온 텍셀만 넘겨받는다.
ivec3 vfx_byte3(vec4 texel) {
    return ivec3(floor(texel.rgb * 255.0 + 0.5));
}

// 서명이 맞으면 효과 종류를, 아니면 -1 을 돌려준다.
int vfx_readType(vec4 texelA, vec4 texelB) {
    if (vfx_byte3(texelA) != VFX_SIG_A) return -1;
    ivec3 b = vfx_byte3(texelB);
    if (b.g != VFX_SIG_B_G || b.b != VFX_SIG_B_B) return -1;
    if (b.r > VFX_TYPE_MAX) return -1;           // 모르는 종류는 거부한다
    return b.r;
}


// ---------------------------------------------------------------------------
//  염색색 24비트 풀기
// ---------------------------------------------------------------------------
// 부동소수라 그냥 비교하면 어긋난다. 반드시 정수로 반올림해서 다룬다.
int vfx_bits(vec4 dye) {
    return (int(floor(dye.r * 255.0 + 0.5)) << 16)
         | (int(floor(dye.g * 255.0 + 0.5)) <<  8)
         |  int(floor(dye.b * 255.0 + 0.5));
}

float vfx_start(int bits)     { return float((bits >> 17) & 127); }
int   vfx_billboard(int bits) { return (bits >> 14) & 7; }
int   vfx_variant(int bits)   { return (bits >> 12) & 3; }

// [활카스] 빌보드 허용 키. 시작틱 필드(7비트) == 이 값이고 틴트 12비트가 전부 1(흰색)일 때만
// 빌보드를 건다. 염색색만으로는 다른 아이템과 구분이 안 되기 때문이다. 우연히 맞을 확률 ~1/50만.
// 그래서 이 사본에서는 빌보드 판에 시작틱(각도/크롭 애니메이션)과 틴트를 같이 쓸 수 없다.
#define VFX_BB_KEY 85
bool vfx_bbActive(int bits) {
    return int(vfx_start(bits)) == VFX_BB_KEY && (bits & 4095) == 4095;
}

// 4-4-4. 판 전체에 곱하는 평평한 값이라 양자화해도 밴딩이 생기지 않는다.
// 정밀도는 "원하는 색을 집을 수 있나" 에만 영향을 준다. 4096색이면 충분하다.
vec3 vfx_tint(int bits) {
    return vec3(float((bits >> 8) & 15),
                float((bits >> 4) & 15),
                float( bits       & 15)) / 15.0;
}


// ---------------------------------------------------------------------------
//  시간
// ---------------------------------------------------------------------------
#define VFX_PI  3.14159265359
#define VFX_TAU 6.28318530718

// 시작 틱은 7비트에 담아야 하므로 이 값으로 나눈 나머지만 온다.
// 24000(하루 틱)의 약수여야 날짜가 넘어가는 순간에도 안 튄다. 120 = 6초.
// 효과의 수명은 반드시 이 값보다 짧아야 한다.
#define VFX_PERIOD 120.0

// 재생 길이 (틱). 종류마다 고정이다. vfx.sk 의 수명 값과 짝을 맞출 것.
#define VFX_SWEEP_ARC  10.0
#define VFX_SWEEP_CROP  8.0

// 가속 곡선. 1.0 이면 등속, 크면 처음이 빠르고 끝이 느리다.
#define VFX_EASE 2.5

float vfx_ease(float p) {
    return 1.0 - pow(1.0 - clamp(p, 0.0, 1.0), VFX_EASE);
}

// 진행률 p 를 [꼬리, 머리] 구간으로 바꾼다. 각도와 크롭이 같은 함수를 쓴다.
// 꼬리는 머리보다 lag 만큼 늦게 출발할 뿐 같은 속도라, p = 1+lag 에서
// 머리를 따라잡아 구간 길이가 0 이 되며 저절로 사라진다.
// ease 는 원시 진행률에 한 번만 먹인다. 두 번 먹이면 꼬리가 어긋난다.
vec2 vfx_band(float p, float lag) {
    return vec2(vfx_ease(clamp(p - lag, 0.0, 1.0)),
                vfx_ease(clamp(p,       0.0, 1.0)));
}


// ---------------------------------------------------------------------------
//  투명도  --  어떤 종류에도 항상 걸린다
// ---------------------------------------------------------------------------
// UV2 는 (블록광, 하늘광) 이 각각 0..240, 16 단위로 온다. 16 으로 나누면 0..15.
// 두 니블을 붙여 0..255 로 읽는다. VFX 판은 fullbright 라 조명값이 필요 없어
// 이 통로가 통째로 비어 있다. 그래서 여기는 투명도 전용으로 못 박는다 --
// 다른 걸 싣기 시작하면 투명도를 못 쓰는 효과가 생긴다.
float vfx_opacity(ivec2 uv2) {
    ivec2 n = uv2 / 16;
    return clamp(float(n.x * 16 + n.y) / 255.0, 0.0, 1.0);
}


// ---------------------------------------------------------------------------
//  빌보드
// ---------------------------------------------------------------------------
// 바닐라 디스플레이 엔티티가 주는 건 fixed / vertical(Y축) / horizontal / center
// 네 가지뿐이고 축을 고를 수 없다. 빌보드는 결국 정점을 다시 놓는 일이라
// 정점 셰이더에서 하면 종류를 마음대로 만들 수 있다.
//
// 필요한 재료
//   피벗   판의 중심. 정점은 자기 위치만 알고 이웃 정점을 못 본다.
//          -> 서버가 판을 아주 작게(VFX_BB_COLLAPSE) 스폰해 네 정점을 겹쳐 놓는다.
//             그러면 어느 정점이든 Position 이 곧 피벗이다. 크기는 여기서 부풀린다.
//             0 이 아니라 1e-3 인 이유: 완전히 0 이면 법선 행렬이 특이해져
//             Normal 이 쓰레기값이 된다.
//   축     Normal. 서버가 판의 법선이 원하는 축이 되게 놓으면 공짜로 온다.
//          바이트 정규화라 약 1도 정밀도 -- 빌보드 축에는 차고 넘친다.
//   시선   카메라 상대 좌표계라 카메라가 원점이다. 그냥 -피벗.
//   코너   gl_VertexID % 4.
//
// 함정
//   - CPU 프러스텀 컬링은 셰이더가 옮긴 걸 모른다. 서버가 반드시
//     setDisplayWidth / setDisplayHeight 로 바운딩 박스를 실제 크기만큼 키워야 한다.
//   - 반투명 정렬도 CPU 가 엔티티 위치로 한다. 여러 장이 겹치면 순서가 어긋날 수 있다.
//   - 와인딩. 이 렌더타입은 뒷면을 자른다. 코너 부호가 원본과 반대면 통째로 안 보인다.

#define VFX_BB_FIXED     0   // 안 함. 지금까지의 동작 그대로
#define VFX_BB_AXIS      1   // 임의 축 원통. 축(Normal)은 절대 안 움직인다
#define VFX_BB_SCREEN    2   // 근평면 평행. 화면 어디서든 같은 방향
#define VFX_BB_VIEWPOINT 3   // 법선이 카메라 위치를 향함 (바닐라 center 와 같은 종류)
#define VFX_BB_GROUND    4   // XZ 평면에 눕고, 그 안에서 카메라 쪽으로 돎
#define VFX_BB_SCRSIZE   5   // 근평면 평행 + 거리와 무관하게 화면상 크기 고정
#define VFX_BB_SPIN      6   // 근평면 평행 + 화면 안에서 회전 (GameTime)
#define VFX_BB_STRETCH   7   // 임의 축 원통 + 축 방향으로 늘어남

// 판을 얼마나 작게 스폰하는가 (블록). vfx.sk 와 같아야 한다.
#define VFX_BB_COLLAPSE 0.001

// 빌보드 판의 반변 크기 (블록). 모드마다 다르다.
// 서버의 스케일은 빌보드 모드에서 안 먹는다 -- 판을 통째로 다시 만들기 때문이다.
// 대신 variant 0~3 이 배율 0.5 / 1 / 2 / 4 를 건다.
vec2 vfx_bbHalf(int mode, int variant) {
    vec2 h = vec2(1.0, 1.0);
    if      (mode == VFX_BB_AXIS)    h = vec2(0.6, 2.0);   // 축을 따라 긴 판
    else if (mode == VFX_BB_STRETCH) h = vec2(0.4, 3.0);
    else if (mode == VFX_BB_GROUND)  h = vec2(1.5, 1.5);
    else if (mode == VFX_BB_VIEWPOINT) h = vec2(1.125, 1.125); // [활카스] variant 2 -> 반변 2.25 = 지름 4.5
    else if (mode == VFX_BB_SCRSIZE) h = vec2(0.03, 0.03); // 깊이에 곱해지므로 작게
    return h * exp2(float(variant) - 1.0);                 // 0.5  1  2  4
}

// 화면 안에서 도는 속도 (초당 회전수). VFX_BB_SPIN 전용.
#define VFX_BB_SPIN_RATE 0.35

// gl_VertexID % 4  ->  판 안에서의 코너 부호.
//
// 0 과 2 가 두 삼각형의 공유 대각선인 것은 확인됐다. 둘레를 도는 순서라는 것도
// 거기서 따라 나온다. 남은 건 어느 모서리에서 시작해 어느 방향으로 도느냐뿐이다.
// VFX_DEBUG 4 로 코너별 단색을 칠해 보고 어긋나면 이 표를 고친다.
// 부호가 반대면 그림이 뒤집히거나, 와인딩이 뒤집혀 판이 통째로 사라진다.
vec2 vfx_cornerSign(int c) {
    if (c == 0) return vec2(-1.0, -1.0);
    if (c == 1) return vec2( 1.0, -1.0);
    if (c == 2) return vec2( 1.0,  1.0);
    return vec2(-1.0,  1.0);
}

// 새 정점 위치를 뷰 공간으로 돌려준다. ProjMat 은 여기서 쓰지 않는다 --
// 이 헤더는 프래그먼트 셰이더도 포함하는데 거기엔 projection.glsl 이 없다.
vec4 vfx_place(int mode, int variant, vec3 pivot, vec3 nrm, int corner, float now) {
    if (mode == VFX_BB_FIXED) {
        return ModelViewMat * vec4(pivot, 1.0);
    }

    vec2 c = vfx_cornerSign(corner);
    vec2 h = vfx_bbHalf(mode, variant);

    // --- 뷰 공간에서 바로 붙이는 것들. 회전 계산이 아예 없어 제일 싸다 ---
    if (mode == VFX_BB_SCREEN || mode == VFX_BB_SCRSIZE || mode == VFX_BB_SPIN) {
        vec4 pv = ModelViewMat * vec4(pivot, 1.0);
        vec2 o = c * h;

        if (mode == VFX_BB_SCRSIZE) {
            // 깊이에 비례시키면 원근이 상쇄돼 화면상 크기가 고정된다.
            o *= max(-pv.z, 0.05);
        } else if (mode == VFX_BB_SPIN) {
            float a = now * VFX_BB_SPIN_RATE * VFX_TAU / 20.0;   // 틱 -> 초 -> 회전
            float s = sin(a), k = cos(a);
            o = vec2(o.x * k - o.y * s, o.x * s + o.y * k);
        }
        return pv + vec4(o, 0.0, 0.0);
    }

    // --- 월드에서 축을 잡는 것들 ---
    // 카메라가 원점이므로 시선은 그냥 -피벗이다.
    vec3 toCam = normalize(-pivot);
    vec3 right;
    vec3 up;

    if (mode == VFX_BB_GROUND) {
        // 판이 XZ 에 눕는다. 그림의 위쪽이 카메라 쪽 수평 방향을 가리킨다.
        vec3 flat_ = vec3(toCam.x, 0.0, toCam.z);
        float l = length(flat_);
        up    = (l < 1e-4) ? vec3(0.0, 0.0, 1.0) : flat_ / l;   // 바로 위에서 볼 때 폴백
        right = cross(up, vec3(0.0, 1.0, 0.0));
    } else if (mode == VFX_BB_VIEWPOINT) {
        // 법선이 카메라 위치를 향한다. 구형 물체에 맞는 종류다.
        vec3 n = toCam;
        vec3 ref = (abs(n.y) < 0.99) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
        right = normalize(cross(ref, n));
        up    = cross(n, right);
    } else {
        // AXIS / STRETCH -- 축은 절대 안 움직이고, 판이 그 축을 중심으로 돈다.
        vec3 axis = normalize(nrm);
        vec3 r = cross(axis, toCam);
        float l = length(r);
        if (l < 1e-3) {
            // 축과 시선이 거의 나란하다 -> 판이 선으로 보이는 특이점.
            // 아무 수직 벡터나 잡아 최소한 터지지는 않게 한다.
            vec3 any = (abs(axis.y) < 0.9) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
            right = normalize(cross(axis, any));
        } else {
            right = r / l;
        }
        up = axis;
    }

    vec3 world = pivot + right * (c.x * h.x) + up * (c.y * h.y);
    return ModelViewMat * vec4(world, 1.0);
}


// ---------------------------------------------------------------------------
//  각도        variant  bit0 = 회전 방향을 뒤집는다  (빌보드가 FIXED 일 때만)
// ---------------------------------------------------------------------------
// 판 안에서 원의 중심. (0.5, 0.5) 면 한가운데.
#define VFX_ARC_PIVOT vec2(0.5, 0.5)

// 각도 0 이 어느 방향인가. 한 바퀴가 1.0.
//   0.0 = +u(오른쪽),  0.25 = +v(그림 아래),  0.5 = -u,  0.75 = -v(그림 위)
#define VFX_ARC_ZERO 0.75

// 꼬리가 머리보다 얼마나 뒤에 오나. 재생 길이 대비 비율.
// 크면 지나간 자리가 오래 남고, 작으면 가는 칼자국처럼 스쳐 간다.
#define VFX_ARC_TAIL 0.45

// 앞뒤 끝을 부드럽게. 한 바퀴 대비 비율. 0.012 면 약 4도.
#define VFX_ARC_SOFT 0.012

// 판 안의 위치(0..1)를 "한 바퀴 중 몇 번째"(0..1) 로 바꾼다.
float vfx_turn(vec2 local, int variant) {
    vec2 d = local - VFX_ARC_PIVOT;
    float dir = ((variant & 1) != 0) ? -1.0 : 1.0;
    float a = atan(d.y, d.x) / VFX_TAU;          // -0.5 .. 0.5
    return fract(a * dir - VFX_ARC_ZERO + 1.0);
}

// [tail, head] 구간만 남기는 마스크.
float vfx_arcMask(float turn, float tail, float head) {
    float len = clamp(head - tail, 0.0, 1.0);
    if (len <= 0.0) return 0.0;
    if (len >= 0.999) return 1.0;                // 한 바퀴 다 찼으면 이음매를 파지 않는다

    // 꼬리를 원점으로 옮기고 fract 를 씌우면 0/1 이음매가 저절로 처리된다.
    // 350도~10도 처럼 0 을 가로지르는 구간도 분기 없이 맞는다.
    float fromTail = fract(turn - tail);
    return smoothstep(0.0, VFX_ARC_SOFT, fromTail)
         * (1.0 - smoothstep(len - VFX_ARC_SOFT, len + VFX_ARC_SOFT, fromTail));
}


// ---------------------------------------------------------------------------
//  크롭        variant  bit0 = 방향 뒤집기, bit1 = 축을 x 로  (빌보드가 FIXED 일 때만)
// ---------------------------------------------------------------------------
// 기하도 UV 도 건드리지 않는다. 판은 늘 최대 크기 그대로 두고, 남길 구간
// 바깥의 알파만 0 으로 만든다. 늘이거나 줄이는 동작이 없으니 눌릴 것도 없다.
//
//   variant 0  그림 아래 -> 위      1  위 -> 아래
//           2  그림 왼쪽 -> 오른쪽  3  오른쪽 -> 왼쪽
//
// 꼬리가 머리보다 얼마나 뒤에 오나. 재생 길이 대비 비율.
//   1.0     머리가 끝에 닿는 순간 꼬리가 출발한다 (멈춤 없음)
//   1.35    다 자란 채로 잠깐 버틴 뒤 지워지기 시작한다
//   2.0 이상  사실상 지워지지 않는다 (수명이 먼저 끝난다)
// 전체 재생 시간은 VFX_SWEEP_CROP x (1 + 이 값) 이다.
#define VFX_CROP_TAIL 1.35

// 잘린 가장자리를 부드럽게. 판 크기 대비 비율. 0.0 이면 칼같이 자른다.
#define VFX_CROP_SOFT 0.0

// 판 안의 위치를 "시작 모서리에서 얼마나 떨어졌나"(0..1) 로 바꾼다.
// local.y 는 그림 위가 0, 아래가 1 이다.
float vfx_cropAxis(vec2 local, int variant) {
    float d = ((variant & 2) != 0) ? local.x : (1.0 - local.y);
    return ((variant & 1) != 0) ? (1.0 - d) : d;
}

// [tail, head] 구간만 남긴다.
// 전처리기 #if 는 정수만 다루므로 실수 비교는 평범한 if 로 쓴다
// (상수라 컴파일러가 접어 버리므로 비용은 같다).
float vfx_cropMask(float d, float tail, float head) {
    if (VFX_CROP_SOFT <= 0.0) {
        return step(tail, d) * step(d, head);
    }
    return smoothstep(tail - VFX_CROP_SOFT, tail + VFX_CROP_SOFT, d)
         * (1.0 - smoothstep(head - VFX_CROP_SOFT, head + VFX_CROP_SOFT, d));
}


// ---------------------------------------------------------------------------
//  판 안에서의 위치 복원
// ---------------------------------------------------------------------------
// 프래그먼트는 아틀라스 UV 만 안다. 스프라이트가 아틀라스 어디에 얼마만 하게
// 붙었는지는 모른다. 그래서 정점에서 대각선 두 코너의 UV 를 흘려보내고,
// 프래그먼트가 그걸로 스프라이트 사각형을 되살린다.
//
// 원리: 네 코너 중 하나에서만 값을 넣고 나머지는 0 으로 두면, 보간된 값은
// "그 코너의 값 x 그 코너의 무게" 가 된다. z 에 1.0 을 같이 실어 두었다가
// xy 를 z 로 나누면 무게가 약분되어 원래 값이 나온다.
//
// 코너 0 과 2 를 쓰는 건 우연이 아니다. 그 둘이 두 삼각형이 공유하는 대각선이다.

vec2 vfx_corner(vec3 c) {
    return c.xy / max(c.z, 1e-6);
}

vec4 vfx_spriteRect(vec3 cornerA, vec3 cornerB) {
    vec2 a = vfx_corner(cornerA);
    vec2 b = vfx_corner(cornerB);
    return vec4(min(a, b), max(a, b));           // (lo.x, lo.y, hi.x, hi.y)
}

vec2 vfx_toLocal(vec2 atlasUV, vec4 rect) {
    return (atlasUV - rect.xy) / max(rect.zw - rect.xy, vec2(1e-6));
}


// ---------------------------------------------------------------------------
//  잡다한 것
// ---------------------------------------------------------------------------
// VFX 그림은 알파가 낮고 부드럽다. 바닐라의 0.1 컷이면 가장자리가 통째로 잘린다.
// 서명 픽셀의 알파 1/255 = 0.0039 보다는 커야 서명이 화면에 안 나온다.
#define VFX_ALPHA_CUT 0.004

// VFX_DEBUG 4 에서 코너 번호를 구분하는 색.
vec3 vfx_cornerColor(int c) {
    if (c == 0) return vec3(1.0, 0.0, 0.0);
    if (c == 1) return vec3(0.0, 1.0, 0.0);
    if (c == 2) return vec3(0.0, 0.0, 1.0);
    return vec3(1.0, 1.0, 0.0);
}
