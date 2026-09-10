#version 150

// [활카스] ogresourcepack 의 SPD(플레이어 리그) 셰이더에 1.21.8vfx 의 빌보드 분기를 얹은 것.
// SPD 경로는 한 줄도 바꾸지 않았다. 아래 "VFX" 표시가 붙은 부분만 추가다.
//
// 정점 단계에서는 이게 VFX 판인지 알 수 없다(서명은 프래그먼트가 읽는다). 그래서
// "VFX 라면 쓰게 될 값" 을 모든 정점에 대해 계산해 두고, 아닌 판은 프래그먼트가 버린다.
// 빌보드만은 기하를 바꾸는 일이라 되돌릴 수 없으므로 염색색 키(vfx_bbActive)로 정점에서 결정한다.
// 키가 안 맞으면 FIXED 라 gl_Position 은 원래 식과 같다.

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <globals.glsl>
#moj_import <projection.glsl>
#moj_import <vfx.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord1;
out vec2 texCoord2;

out vec4 overlayColor;
out vec4 shadeColor;
out vec4 lightMapColor;
out float alphaOffset;

// --- VFX ---
// 판 안에서의 위치를 되살리기 위한 대각선 두 코너. 보간돼야 하므로 flat 금지.
out vec3 vfxCornerA;
out vec3 vfxCornerB;
// 사각형 안에서 변하지 않는 값들. flat 으로 보내 보간 오차를 없앤다.
flat out vec2  vfxArc;
flat out vec2  vfxCrop;
flat out vec3  vfxTintColor;
flat out float vfxAlpha;
flat out int   vfxVariant;

#define SPACING 1024.0
#define MAXRANGE (0.5 * SPACING)
#define SKINRES 64
#define FACERES 8

const vec4[] subuvs = vec4[](
    vec4(4.0,  0.0,  8.0,  4.0 ), // 4x4x12
    vec4(8.0,  0.0,  12.0, 4.0 ),
    vec4(0.0,  4.0,  4.0,  16.0),
    vec4(4.0,  4.0,  8.0,  16.0),
    vec4(8.0,  4.0,  12.0, 16.0),
    vec4(12.0, 4.0,  16.0, 16.0),
    vec4(4.0,  0.0,  7.0,  4.0 ), // 4x3x12
    vec4(7.0,  0.0,  10.0, 4.0 ),
    vec4(0.0,  4.0,  4.0,  16.0),
    vec4(4.0,  4.0,  7.0,  16.0),
    vec4(7.0,  4.0,  11.0, 16.0),
    vec4(11.0, 4.0,  14.0, 16.0),
    vec4(4.0,  0.0,  12.0, 4.0 ), // 4x8x12
    vec4(12.0,  0.0, 20.0, 4.0 ),
    vec4(0.0,  4.0,  4.0,  16.0),
    vec4(4.0,  4.0,  12.0, 16.0),
    vec4(12.0, 4.0,  16.0, 16.0),
    vec4(16.0, 4.0,  24.0, 16.0)
);

const vec2[] origins = vec2[](
    vec2(40.0, 16.0), // right arm
    vec2(40.0, 32.0),
    vec2(32.0, 48.0), // left arm
    vec2(48.0, 48.0),
    vec2(16.0, 16.0), // torso
    vec2(16.0, 32.0),
    vec2(0.0,  16.0), // right leg
    vec2(0.0,  32.0),
    vec2(16.0, 48.0), // left leg
    vec2(0.0,  48.0)
);

const int[] faceremap = int[](0, 0, 1, 1, 2, 3, 4, 5);


#moj_import <lib/waypoint/waypoint_utils.glsl>


mat3 rotateX(float angle){
    float s=sin(angle);
    float c=cos(angle);
    return mat3(1.,0.,0.,0.,c,s,0.,-s,c);
}
mat3 rotateY(float angle){
    float s=sin(angle);
    float c=cos(angle);
    return mat3(c,0.,-s,0.,1.,0.,s,0.,c);
}
float getDistance(mat4 modelViewMat, vec3 pos) {
    float distXZ = length((modelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
    float distY = length((modelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
    return max(distXZ, distY);
}


void main() {
    vec3 pos = Position;

    vec4 col=Color;
    alphaOffset=0.;
    //ppart=0.;
    vec2 uv0=UV0;
    vertexColor = minecraft_mix_light(Light0_Direction,Light1_Direction,Normal,col);

    lightMapColor=texelFetch(Sampler2,UV2/16,0);
    overlayColor=vec4(1.);

    shadeColor=col;

    // --- VFX: 어느 분기로 가든 프래그먼트가 읽을 값을 채워 둔다 ---
    // 코너 0 과 2 가 두 삼각형의 공유 대각선이라 어느 삼각형에서 보든 둘 다 살아 있다.
    int vfxCornerId = gl_VertexID % 4;
    vfxCornerA = vec3(0.0);
    vfxCornerB = vec3(0.0);
    if (vfxCornerId == 0) vfxCornerA = vec3(UV0, 1.0);
    if (vfxCornerId == 2) vfxCornerB = vec3(UV0, 1.0);
    int vfxBits   = vfx_bits(Color);
    vfxVariant    = vfx_variant(vfxBits);
    vfxTintColor  = vfx_tint(vfxBits);
    vfxAlpha      = vfx_opacity(UV2);
    float vfxNow  = GameTime * 24000.0;
    float vfxDt   = mod(vfxNow - vfx_start(vfxBits) + VFX_PERIOD, VFX_PERIOD);
    vfxArc  = vfx_band(vfxDt / VFX_SWEEP_ARC,  VFX_ARC_TAIL);
    vfxCrop = vfx_band(vfxDt / VFX_SWEEP_CROP, VFX_CROP_TAIL);

    ivec2 dim = textureSize(Sampler0, 0);

    if (ProjMat[2][3] == 0.0 || dim.x != 64 || dim.y != 64) { // short circuit if cannot be player
        sphericalVertexDistance = fog_spherical_distance(Position);
        cylindricalVertexDistance = fog_cylindrical_distance(Position);
        texCoord0 = UV0;
        texCoord1 = UV1;
        texCoord2 = UV2;


        if (make_waypoint()) {
            return;
        }

        // --- VFX 빌보드. 키가 안 맞으면 FIXED 이고, FIXED 는 ModelViewMat * pos 그대로라
        //     여기 오는 모든 다른 판의 결과가 원래 식과 한 치도 다르지 않다.
        int vfxMode = vfx_bbActive(vfxBits) ? vfx_billboard(vfxBits) : VFX_BB_FIXED;
        gl_Position = ProjMat * vfx_place(vfxMode, vfxVariant, pos, Normal, vfxCornerId, vfxNow);
    }
    else {
        vec3 wpos = Position; //수정
        vec2 UVout = UV0;
        vec2 UVout2 = vec2(0.0);
        int partId = -int((wpos.y - MAXRANGE) / SPACING);

        if (partId == 0) { // higher precision position if no translation is needed
            gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
        }
        else {
            vec4 samp1 = texture(Sampler0, vec2(54.0 / 64.0, 20.0 / 64.0));
            vec4 samp2 = texture(Sampler0, vec2(55.0 / 64.0, 20.0 / 64.0));
            bool slim = samp1.a == 0.0 || (((samp1.r + samp1.g + samp1.b) == 0.0) && ((samp2.r + samp2.g + samp2.b) == 0.0) && samp1.a == 1.0 && samp2.a == 1.0);
            int outerLayer = (gl_VertexID / 24) % 2;
            int vertexId = gl_VertexID % 4;
            int faceId = (gl_VertexID % 24) / 4;
            ivec2 faceIdTmp = ivec2(round(UV0 * SKINRES));
            if ((faceId != 1 && vertexId >= 2) || (faceId == 1 && vertexId <= 1)) {
                faceIdTmp.y -= FACERES;
            }
            if (vertexId == 0 || vertexId == 3) {
                faceIdTmp.x -= FACERES;
            }
            faceIdTmp /= FACERES;
            faceId = (faceIdTmp.x % 4) + 4 * faceIdTmp.y;
            faceId = faceremap[faceId];
            int subuvIndex = faceId;

            wpos.y += SPACING * partId;
            gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0); //수정

            UVout = origins[2 * (partId - 1) + outerLayer];
            UVout2 = origins[2 * (partId - 1)];

            if (slim && (partId == 1 || partId == 2)) {
                subuvIndex += 6;
            }
            else if (partId == 3) {
                subuvIndex += 12;
            }

            vec4 subuv = subuvs[subuvIndex];

            vec2 offset = vec2(0.0);
            if (faceId == 1) {
                if (vertexId == 0) {
                    offset += subuv.zw;
                }
                else if (vertexId == 1) {
                    offset += subuv.xw;
                }
                else if (vertexId == 2) {
                    offset += subuv.xy;
                }
                else {
                    offset += subuv.zy;
                }
            }
            else {
                if (vertexId == 0) {
                    offset += subuv.zy;
                }
                else if (vertexId == 1) {
                    offset += subuv.xy;
                }
                else if (vertexId == 2) {
                    offset += subuv.xw;
                }
                else {
                    offset += subuv.zw;
                }
            }

            UVout += offset;
            UVout2 += offset;
            UVout /= float(SKINRES);
            UVout2 /= float(SKINRES);
        }

        sphericalVertexDistance = fog_spherical_distance(wpos);
        cylindricalVertexDistance = fog_cylindrical_distance(wpos);
        texCoord0 = UVout;
        texCoord1 = UVout2;
    }

}
