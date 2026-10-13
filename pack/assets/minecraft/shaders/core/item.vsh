#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:light.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in ivec2 UV1;
layout(location = 4) in ivec2 UV2;
#ifdef GLINT_SPECIAL
layout(location = 5) in vec2 UV3;
#endif
layout(location = 6) in vec3 Normal;

#ifndef OIT_ALPHA_ONLY
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
#endif
layout(location = 2) out vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 3) out vec4 lightMapColor;
layout(location = 4) out vec4 overlayColor;
#endif

layout(location = 5) out vec2 texCoord0;
#ifdef GLINT
layout(location = 6) out vec2 texCoordGlint;
#endif

uniform sampler2D Sampler0;
vec4 hwal_light(){
#ifndef OIT_ALPHA_ONLY
 return sample_lightmap(Sampler2, UV2);
#else
 return vec4(1.0);
#endif
}

// [활카스] ogresourcepack 의 SPD(플레이어 리그) 셰이더에 1.21.8vfx 의 빌보드 분기를 얹은 것.
// SPD 경로는 한 줄도 바꾸지 않았다. 아래 "VFX" 표시가 붙은 부분만 추가다.
//
// 정점 단계에서는 이게 VFX 판인지 알 수 없다(서명은 프래그먼트가 읽는다). 그래서
// "VFX 라면 쓰게 될 값" 을 모든 정점에 대해 계산해 두고, 아닌 판은 프래그먼트가 버린다.
// 빌보드만은 기하를 바꾸는 일이라 되돌릴 수 없으므로 염색색 키(vfx_bbActive)로 정점에서 결정한다.
// 키가 안 맞으면 FIXED 라 gl_Position 은 원래 식과 같다.

#include <minecraft:vfx.glsl>



layout(location = 8) out float hwal_sphericalVertexDistance;
layout(location = 9) out float hwal_cylindricalVertexDistance;
layout(location = 10) out vec4 hwal_vertexColor;
layout(location = 11) out vec2 hwal_texCoord0;
layout(location = 12) out vec2 hwal_texCoord1;
layout(location = 13) out vec2 hwal_texCoord2;

layout(location = 14) out vec4 hwal_overlayColor;
layout(location = 15) out vec4 hwal_shadeColor;
layout(location = 16) out vec4 hwal_lightMapColor;
layout(location = 17) out float hwal_alphaOffset;

// --- VFX ---
// 판 안에서의 위치를 되살리기 위한 대각선 두 코너. 보간돼야 하므로 flat 금지.
layout(location = 18) out vec3 hwal_vfxCornerA;
layout(location = 19) out vec3 hwal_vfxCornerB;
// 사각형 안에서 변하지 않는 값들. flat 으로 보내 보간 오차를 없앤다.
layout(location = 20) flat out vec2 hwal_vfxArc;
layout(location = 21) flat out vec2 hwal_vfxCrop;
layout(location = 22) flat out vec3 hwal_vfxTintColor;
layout(location = 26) flat out int hwal_vfxBillboardKey;
layout(location = 27) out vec2 hwal_vfxPlane;
layout(location = 23) flat out float hwal_vfxAlpha;
layout(location = 24) flat out int hwal_vfxVariant;

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



bool is_waypoint(sampler2D tex, ivec2 pixel) {
    return ivec4(texelFetch(tex, pixel, 0) * 255.5) == ivec4(157, 211, 147, 99);
}

vec4 build_waypoint(inout vec2 texCoord, ivec2 texSize, vec2 size, vec3 position, vec2 faceCoords, mat4 projMat, mat4 modelViewMat) {
    vec2 screenBounds = vec2(1.0, 1.0) - size * 0.7;

    ivec2 sprite = ivec2(0,0);
    vec4 center = modelViewMat * vec4(position - vec3(faceCoords, 0.0), 1.0);
    vec4 clipPos = projMat * center;
    vec2 screenPos = clipPos.xy / clipPos.w;

    // 26.3 uses reversed depth; clip W still distinguishes front from back.
    if(clipPos.w <= 0.0 || abs(screenPos.x) > screenBounds.x || abs(screenPos.y) > screenBounds.y) {
        if(center.z >= 0.0) screenPos *= -1.0;

        vec2 t = screenBounds / abs(screenPos);
        screenPos.xy *= min(t.x, t.y);
        sprite = ivec2(ivec2(2, -2) * screenPos);
    }

    vec2 uv = faceCoords + 0.5;
    uv.y = 1.0 - uv.y;
    uv = 66.0 + 60.0 * uv + 64.0 * sprite; //한칸이 64 전체는 192
    texCoord = texCoord + uv / vec2(texSize);

    // Keep the HUD marker at the near plane in the 26.3 depth convention.
    return vec4(screenPos.xy + size * faceCoords, 1.0, 1.0);
}

// Called in 'rendertype_item_entity_translucent_cull.vsh' - ONLY function that should be used; above is utilities.
bool make_waypoint() {
    ivec2 texSize = textureSize(Sampler0, 0);
    ivec2 pixel = ivec2(UV0 * texSize);

    if(is_waypoint(Sampler0, pixel)) {
        // Corner identity comes from the interior of the signature texel, not draw order.
        vec2 faceCoords = sign(fract(UV0 * vec2(texSize)) - 0.5) * vec2(1.0, -1.0);
        hwal_texCoord0 = vec2(pixel) / vec2(texSize);
        vec2 scaleFactor = clamp(max((100.0 - length(Position)), 0.0) / 100.0, 0.75, 1.0) * vec2(0.15); //vec2(이거 수정하면 사이즈)

        if (length(Position) < 16.0) {
            // Preserve near hiding without undefined division by zero in UVs.
            gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
            return true;
        }

        gl_Position = build_waypoint(
            hwal_texCoord0, 
            texSize, 
            scaleFactor / vec2(ScreenSize.x / ScreenSize.y, 1.0), 
            Position, 0.5 * faceCoords, 
            ProjMat, 
            ModelViewMat
        );

        // Render flat
        hwal_sphericalVertexDistance = 0.0;
        hwal_cylindricalVertexDistance = 0.0;
        hwal_vertexColor = vec4(1.0);

        return true;
    }

    return false;
}



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


void hwal_legacy() {
    vec3 pos = Position;

    vec4 col=Color;
    hwal_alphaOffset=0.;
    //ppart=0.;
    vec2 uv0=UV0;
    hwal_vertexColor = minecraft_mix_light(Light0_Direction,Light1_Direction,Normal,col);

    hwal_lightMapColor=hwal_light();
    hwal_overlayColor=vec4(1.);

    hwal_shadeColor=col;

    // --- VFX: 어느 분기로 가든 프래그먼트가 읽을 값을 채워 둔다 ---
    // 코너 0 과 2 가 두 삼각형의 공유 대각선이라 어느 삼각형에서 보든 둘 다 살아 있다.
    int vfxCornerId = gl_VertexIndex % 4;
    hwal_vfxPlane = vfx_cornerSign(vfxCornerId);
    hwal_vfxCornerA = vec3(0.0);
    hwal_vfxCornerB = vec3(0.0);
    if (vfxCornerId == 0) hwal_vfxCornerA = vec3(UV0, 1.0);
    if (vfxCornerId == 2) hwal_vfxCornerB = vec3(UV0, 1.0);
    int vfxBits   = vfx_bits(Color);
    hwal_vfxBillboardKey = vfx_bbActive(vfxBits) ? 1 : 0;
    hwal_vfxVariant    = vfx_variant(vfxBits);
    hwal_vfxTintColor  = vfx_tint(vfxBits);
    hwal_vfxAlpha      = vfx_opacity(UV2);
    float vfxNow  = GameTime * 24000.0;
    float vfxDt   = mod(vfxNow - vfx_start(vfxBits) + VFX_PERIOD, VFX_PERIOD);
    hwal_vfxArc  = vfx_band(vfxDt / VFX_SWEEP_ARC,  VFX_ARC_TAIL);
    hwal_vfxCrop = vfx_band(vfxDt / VFX_SWEEP_CROP, VFX_CROP_TAIL);

    ivec2 dim = textureSize(Sampler0, 0);

    if (ProjMat[2][3] == 0.0 || dim.x != 64 || dim.y != 64) { // short circuit if cannot be player
        hwal_sphericalVertexDistance = fog_spherical_distance(Position);
        hwal_cylindricalVertexDistance = fog_cylindrical_distance(Position);
        hwal_texCoord0 = UV0;
        hwal_texCoord1 = vec2(UV1);
        hwal_texCoord2 = vec2(UV2);


        if (make_waypoint()) {
            return;
        }

        // --- VFX 빌보드. 키가 안 맞으면 FIXED 이고, FIXED 는 ModelViewMat * pos 그대로라
        //     여기 오는 모든 다른 판의 결과가 원래 식과 한 치도 다르지 않다.
        int vfxMode = vfx_bbActive(vfxBits) ? vfx_billboard(vfxBits) : VFX_BB_FIXED;
        gl_Position = ProjMat * vfx_place(vfxMode, hwal_vfxVariant, pos, Normal, vfxCornerId, vfxNow);
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
            int outerLayer = (gl_VertexIndex / 24) % 2;
            int vertexId = gl_VertexIndex % 4;
            int faceId = (gl_VertexIndex % 24) / 4;
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

        hwal_sphericalVertexDistance = fog_spherical_distance(wpos);
        hwal_cylindricalVertexDistance = fog_cylindrical_distance(wpos);
        hwal_texCoord0 = UVout;
        hwal_texCoord1 = UVout2;
    }

}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    #ifndef OIT_ALPHA_ONLY
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    #endif
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    #ifndef OIT_ALPHA_ONLY
    lightMapColor = sample_lightmap(Sampler2, UV2);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    #endif

    texCoord0 = UV0;
    #ifdef GLINT
    #ifdef GLINT_SPECIAL
    texCoordGlint = (TextureMat * vec4(UV3, 0.0, 1.0)).xy;
    #else
    texCoordGlint = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
    #endif
    #endif

 hwal_legacy();
 texCoord0=hwal_texCoord0;
}
