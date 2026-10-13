#version 330
#extension GL_ARB_separate_shader_objects : require

#ifdef GLINT
#include <minecraft:globals.glsl>
#endif
#include <minecraft:globals.glsl>
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#endif
layout(location = 2) in vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 3) in vec4 lightMapColor;
layout(location = 4) in vec4 overlayColor;
#endif
layout(location = 5) in vec2 texCoord0;
#ifdef GLINT
layout(location = 6) in vec2 texCoordGlint;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif


// [활카스] ogresourcepack 의 SPD 프래그먼트에 1.21.8vfx 의 서명 관문을 얹은 것.
// 서명(스프라이트 네 모서리 픽셀)이 맞는 판만 VFX 경로로 가고, 나머지는 원래 코드 그대로다.

#include <minecraft:vfx.glsl>


layout(location = 8) in float hwal_sphericalVertexDistance;
layout(location = 9) in float hwal_cylindricalVertexDistance;
layout(location = 10) in vec4 hwal_vertexColor;
layout(location = 14) in vec4 hwal_overlayColor;
layout(location = 11) in vec2 hwal_texCoord0;
layout(location = 15) in vec4 hwal_shadeColor;
layout(location = 16) in vec4 hwal_lightMapColor;
layout(location = 17) in float hwal_alphaOffset;

// --- VFX ---
layout(location = 18) in vec3 hwal_vfxCornerA;
layout(location = 19) in vec3 hwal_vfxCornerB;
layout(location = 20) flat in vec2 hwal_vfxArc;
layout(location = 21) flat in vec2 hwal_vfxCrop;
layout(location = 22) flat in vec3 hwal_vfxTintColor;
layout(location = 26) flat in int hwal_vfxBillboardKey;
layout(location = 27) in vec2 hwal_vfxPlane;
layout(location = 23) flat in float hwal_vfxAlpha;
layout(location = 24) flat in int hwal_vfxVariant;

vec4 hwalColor;

vec4 brightColor(vec4 color) {
    float max = 1 / max(color.r,max(color.g,color.b));
    return color * vec4(max, max, max, 1);
}

void hwal_legacy(){
    // --- VFX 관문 ---
    // 정점이 흘려보낸 대각선 두 코너로 스프라이트 사각형을 되살리고, 첫/마지막 텍셀의 서명을 읽는다.
    // texelFetch 라 밉맵·선형보간에 안 뭉개진다. 범위 밖 fetch 는 정의돼 있지 않으므로 반드시 묶는다.
    vec4 vfxRect = vfx_spriteRect(hwal_vfxCornerA, hwal_vfxCornerB);
    vec2 vfxSampleUV = hwal_texCoord0;
    // HWAL_BILLBOARD263: item draws can begin at any vertex offset. Sparse
    // corner-0/2 varyings then no longer straddle both triangles. Reconstruct
    // the UV rectangle from the affine UV/plane mapping instead, using every
    // vertex. Canonical plane axes also remove the draw-offset-dependent roll.
    if (hwal_vfxBillboardKey == 1) {
        mat2 planeD = mat2(dFdx(hwal_vfxPlane), dFdy(hwal_vfxPlane));
        mat2 uvD = mat2(dFdx(hwal_texCoord0), dFdy(hwal_texCoord0));
        if (abs(determinant(planeD)) > 1e-12) {
            mat2 basis = uvD * inverse(planeD);
            vec2 centerUV = hwal_texCoord0 - basis * hwal_vfxPlane;
            vec2 halfUV = abs(basis[0]) + abs(basis[1]);
            vfxRect = vec4(centerUV - halfUV, centerUV + halfUV);
            // Preserve the original upright pupil (texture U runs up the eye).
            vfxSampleUV = centerUV + halfUV * hwal_vfxPlane.yx;
        }
    }
    ivec2 vfxAtlas = textureSize(Sampler0, 0);
    ivec2 vfxLast = vfxAtlas - 1;
    ivec2 vfxLo = clamp(ivec2(vfxRect.xy * vec2(vfxAtlas) + 0.5), ivec2(0), vfxLast);
    ivec2 vfxHi = clamp(ivec2(vfxRect.zw * vec2(vfxAtlas) - 0.5), ivec2(0), vfxLast);
    int vfxType = vfx_readType(texelFetch(Sampler0, vfxLo, 0), texelFetch(Sampler0, vfxHi, 0));
    // Reserved billboard keys encode NONE effects; do not reinterpret control dye
    // as color when an atlas-edge fetch falls on a neighboring transparent texel.
    if (hwal_vfxBillboardKey == 1) vfxType = VFX_TYPE_NONE;

    if (vfxType >= 0) {
        vec2 local = vfx_toLocal(vfxSampleUV, vfxRect);
        vec4 vcol = texture(Sampler0, vfxSampleUV);
        if (vfxType == VFX_TYPE_ARC) {
            vcol.a *= vfx_arcMask(vfx_turn(local, hwal_vfxVariant), hwal_vfxArc.x, hwal_vfxArc.y);
        } else if (vfxType == VFX_TYPE_CROP) {
            vcol.a *= vfx_cropMask(vfx_cropAxis(local, hwal_vfxVariant), hwal_vfxCrop.x, hwal_vfxCrop.y);
        }
        // 틴트는 rgb 에, 투명도는 알파에만. hwal_vertexColor 는 쓰지 않는다(염색색은 색이 아니라 데이터).
        vcol.rgb *= hwal_vfxTintColor;
        vcol.a   *= hwal_vfxAlpha;
        vcol *= ColorModulator;
        if (vcol.a < VFX_ALPHA_CUT) {
            discard;
        }
        hwalColor = apply_fog(vcol, hwal_sphericalVertexDistance, hwal_cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
        return;
    }

    // --- 아래는 ogresourcepack 원본 그대로 ---
    vec4 rgb=texture(Sampler0,hwal_texCoord0);
    vec4 vCol=hwal_vertexColor;
    vec4 sCol=hwal_shadeColor;

    float noshade=1;
    bool light = false;
    if (rgb.a<254.5/255.0&&rgb.a>145.0/255.0) {
        noshade = 0;
        light = true;
    }


    rgb.a=max(0.,rgb.a-hwal_alphaOffset);

    vec4 color=rgb*mix(sCol,vCol,noshade)*ColorModulator;

    if(color.a < 0.01){
        discard;
    }
    color.rgb=mix(hwal_overlayColor.rgb, color.rgb, hwal_overlayColor.a);
    color *= mix(vec4(1.), hwal_lightMapColor,1);
    hwalColor= light ? color : apply_fog(color, hwal_sphericalVertexDistance, hwal_cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}

#ifndef OIT_ALPHA_ONLY
vec4 calculateFinalColor(vec4 color) {
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;

    #ifdef GLINT
    vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);// Glint color modulator?
    // Matches BlendFuntion.GLINT
    color.rgb += glintColor.rgb * glintColor.rgb;
    #endif

    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
}
#endif

void main(){
 hwal_legacy();
#ifdef GLINT
 hwalColor.a=max(hwalColor.a,GlintAlpha);
 hwalColor.rgb+=pow(GlintAlpha*texture(GlintSampler,texCoordGlint).rgb,vec3(2.0));
#endif
#ifdef OIT_ALPHA_ONLY
 executeAlphaOnlyPhase(gl_FragCoord.z,hwalColor.a);
#else
#ifdef OIT_ACCUMULATE
 hwalColor=sampleColorForAccumulation(hwalColor);
#endif
 fragColor=hwalColor;
#endif
}
