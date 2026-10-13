#version 330
#extension GL_ARB_separate_shader_objects : require

#ifdef GLINT
#include <minecraft:globals.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
layout(location = 2) in vec4 vertexPerFaceColorBack;
layout(location = 3) in vec4 vertexPerFaceColorFront;
#else
layout(location = 2) in vec4 vertexColor;
#endif

#ifndef EMISSIVE
layout(location = 4) in vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
layout(location = 5) in vec4 overlayColor;
#endif

layout(location = 6) in vec2 texCoord0;
#ifdef GLINT
layout(location = 7) in vec2 texCoordGlint;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

#if defined(ALPHA_CUTOUT) && !defined(EMISSIVE) && !defined(NO_OVERLAY) && !defined(APPLY_TEXTURE_MATRIX)
#define MAYBE_PLAYERDISP 1
#endif

#ifdef MAYBE_PLAYERDISP


#if defined(ALPHA_CUTOUT) && !defined(EMISSIVE) && !defined(NO_OVERLAY) && !defined(APPLY_TEXTURE_MATRIX)
#define MAYBE_PLAYERDISP 1
#endif


layout(location = 8) in float hwal_sphericalVertexDistance;
layout(location = 9) in float hwal_cylindricalVertexDistance;
layout(location = 10) in vec4 hwal_vertexColor;
layout(location = 11) in vec4 hwal_floweryTint;
layout(location = 12) in float hwal_pussBody;
layout(location = 13) in vec4 hwal_lightMapColor;
layout(location = 14) in vec4 hwal_overlayColor;
layout(location = 15) in vec2 hwal_texCoord0;
#ifdef MAYBE_PLAYERDISP
layout(location = 16) in vec2 hwal_texCoord1;
layout(location = 17) in float hwal_part;

#define FADERANGE 12.0
#define FADEBIAS 8.0
#define MINALPHA 0.25

const mat4 bayer4 = mat4( 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
                         12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
                          3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
                         15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0);
                         
#endif

vec4 hwalColor;

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

void hwal_legacy() {
    // HWAL_UV263: remap the interpolated skull face into the matching body skin face.
    vec2 sampleUV = hwal_texCoord0;
    vec2 underUV = hwal_texCoord0;
    if (hwal_part > 0.5) {
        int bodyPart = (int(round(hwal_part)) - 1) % 5;
        vec2 pixel = hwal_texCoord0 * 64.0;
        int outerLayer = int(floor(pixel.x / 32.0));
        vec2 headUV = pixel - vec2(float(outerLayer) * 32.0, 0.0);
        int face = headUV.y < 8.0 ? (headUV.x < 16.0 ? 0 : 1) : int(floor(headUV.x / 8.0)) + 2;
        vec2 headOrigin = face < 2 ? vec2(face == 0 ? 8.0 : 16.0, 0.0) : vec2(float(face - 2) * 8.0, 8.0);
        int rect = face;
        if (bodyPart == 2) rect += 12;
        else if (bodyPart < 2 && hwal_texCoord1.x > 0.5) rect += 6;
        vec4 bounds = subuvs[rect];
        vec2 offset = mix(bounds.xy, bounds.zw, (headUV - headOrigin) / 8.0);
        sampleUV = (origins[2 * bodyPart + outerLayer] + offset) / 64.0;
        underUV = (origins[2 * bodyPart] + offset) / 64.0;
    }

    // Keep the caster's first-person view clear without changing their camera.
    if (hwal_pussBody > 0.5 && hwal_sphericalVertexDistance < 0.7) discard;
    vec4 color = texture(Sampler0, sampleUV);
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif
    color *= hwal_vertexColor * ColorModulator;
#ifndef NO_OVERLAY
    color.rgb = mix(hwal_overlayColor.rgb, color.rgb, hwal_overlayColor.a);
#endif
#ifndef EMISSIVE
    color *= hwal_lightMapColor;
#endif
    if (hwal_floweryTint.a >= 0.0) {
        // 스킨의 얼굴/옷 명암을 남기면서 원래 색상에 관계없이 무지개 틴트가 드러난다.
        float shade = dot(texture(Sampler0, sampleUV).rgb, vec3(0.2126, 0.7152, 0.0722));
        color.rgb = hwal_floweryTint.rgb * (0.28 + 0.82 * shade);
        color.a *= hwal_floweryTint.a;
    }
    hwalColor = apply_fog(color, hwal_sphericalVertexDistance, hwal_cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);

#ifdef MAYBE_PLAYERDISP
    if (hwal_floweryTint.a >= 0.0) {
        // 본인 1인칭 카메라 안쪽의 대체 몸은 가리고, F5/다른 시점에서는 그대로 보인다.
        if (hwal_floweryTint.a > 0.99 && hwal_sphericalVertexDistance < 0.65) discard;
        if (hwalColor.a < bayer4[int(gl_FragCoord.x) % 4][int(gl_FragCoord.y) % 4] + 0.03125) discard;
        hwalColor.a = 1.0;
        return;
    }
    if (hwal_part > 1.0 - 10e-6 && hwalColor.a < 1.0) {
        hwalColor.a = max(hwalColor.a, MINALPHA);

        vec3 underCol = texture(Sampler0, underUV).rgb;
        vec3 trueMix = mix(underCol, hwalColor.rgb, hwalColor.a);
        float fade = mix(hwalColor.a, 1.0, clamp((hwal_cylindricalVertexDistance - FADEBIAS) / (FADERANGE - FADEBIAS), 0.0, 1.0));

        hwalColor = vec4((trueMix - (1 - fade) * underCol) / fade,  fade);
        if (hwalColor.a < bayer4[int(gl_FragCoord.x) % 4][int(gl_FragCoord.y) % 4] + (0.5 / 16.0)) {
            discard;
        }
        else {
            hwalColor.a = 1.0;
        }
    }
#endif
}

#endif
vec4 calculateFinalColor(vec4 color) {
    #ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    #endif

    #ifndef EMISSIVE
    color *= lightMapColor;
    #endif

    #ifdef GLINT
    vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);
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

void main() {
#ifdef MAYBE_PLAYERDISP
 if (hwal_part > 0.0 || hwal_floweryTint.a >= 0.0 || hwal_pussBody > 0.5) {
  hwal_legacy();
#ifdef OIT_ALPHA_ONLY
  executeAlphaOnlyPhase(gl_FragCoord.z,hwalColor.a);
#else
#ifdef OIT_ACCUMULATE
  hwalColor=sampleColorForAccumulation(hwalColor);
#endif
  fragColor=hwalColor;
#endif
  return;
 }
#endif

    vec4 color = texture(Sampler0, texCoord0);

    #ifdef OIT_ADDITIVE
    color.a = min(0.99, color.a);
    #endif

    #ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
    #endif

    #ifdef PER_FACE_LIGHTING
    vec4 faceVertexColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
    #else
    vec4 faceVertexColor = vertexColor;
    #endif

    #ifdef DISSOLVE
    if (faceVertexColor.a < texture(DissolveMaskSampler, texCoord0).a) {
        discard;
    }
    // The dissolve effect entirely replaces translucency
    faceVertexColor.a = 1.0;
    #endif

    color *= faceVertexColor * ColorModulator;

    #ifdef GLINT
    color.a = max(color.a, GlintAlpha);
    #endif

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}
