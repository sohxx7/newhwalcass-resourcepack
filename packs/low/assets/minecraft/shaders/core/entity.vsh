#version 330
#extension GL_ARB_separate_shader_objects : require

#if defined(PER_FACE_LIGHTING) || !defined(NO_CARDINAL_LIGHTING)
#include <minecraft:light.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in ivec2 UV1;
layout(location = 4) in ivec2 UV2;
layout(location = 5) in vec3 Normal;

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler1;
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler2;
#endif

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;

#ifdef PER_FACE_LIGHTING
layout(location = 2) out vec4 vertexPerFaceColorBack;
layout(location = 3) out vec4 vertexPerFaceColorFront;
#else
layout(location = 2) out vec4 vertexColor;
#endif

#ifndef EMISSIVE
layout(location = 4) out vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
layout(location = 5) out vec4 overlayColor;
#endif

layout(location = 6) out vec2 texCoord0;
#ifdef GLINT
layout(location = 7) out vec2 texCoordGlint;
#endif

#if defined(ALPHA_CUTOUT) && !defined(EMISSIVE) && !defined(NO_OVERLAY) && !defined(APPLY_TEXTURE_MATRIX)
#define MAYBE_PLAYERDISP 1
#endif

#ifdef MAYBE_PLAYERDISP
uniform sampler2D Sampler0;
vec4 hwal_light(){
#ifndef OIT_ALPHA_ONLY
 return sample_lightmap(Sampler2, UV2);
#else
 return vec4(1.0);
#endif
}
vec4 hwal_overlay(){
#ifndef OIT_ALPHA_ONLY
 return texelFetch(Sampler1, UV1, 0);
#else
 return vec4(0.0,0.0,0.0,1.0);
#endif
}


#if defined(ALPHA_CUTOUT) && !defined(EMISSIVE) && !defined(NO_OVERLAY) && !defined(APPLY_TEXTURE_MATRIX)
#define MAYBE_PLAYERDISP 1
#endif

#define SPLITMODEL 0


#ifdef MAYBE_PLAYERDISP
#endif

layout(location = 8) out float hwal_sphericalVertexDistance;
layout(location = 9) out float hwal_cylindricalVertexDistance;
layout(location = 10) out vec4 hwal_vertexColor;
layout(location = 11) out vec4 hwal_lightMapColor;
layout(location = 12) out vec4 hwal_overlayColor;
layout(location = 13) out vec2 hwal_texCoord0;
#ifdef MAYBE_PLAYERDISP
layout(location = 14) out vec2 hwal_texCoord1;
layout(location = 15) out float hwal_part;

#define SPACING 1024.0
#define MAXRANGE (0.5 * SPACING)
#define SKINRES 64
#define FACERES 8

#define SLIMCHECK0 vec2(54.0 / float(SKINRES), 20.0 / float(SKINRES))
#define SLIMCHECK1 vec2(55.0 / float(SKINRES), 20.0 / float(SKINRES))

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
#endif

void hwal_legacy() {
#ifdef NO_CARDINAL_LIGHTING
    hwal_vertexColor = Color;
#else
    hwal_vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
#endif
    hwal_lightMapColor = hwal_light();
    hwal_overlayColor = hwal_overlay();

#ifdef MAYBE_PLAYERDISP
    ivec2 dim = textureSize(Sampler0, 0);
    hwal_part = 0.0;
    hwal_texCoord1 = vec2(0.0);

    // check world projmat (not gui), 64x64 texture (player tex dim), valid fog (not hand)
    if (abs(ProjMat[2][3]) > 10e-6 && dim.x == SKINRES && dim.y == SKINRES && FogRenderDistanceEnd > FogRenderDistanceStart) {
        int partId = -int((Position.y - MAXRANGE) / SPACING);

        hwal_part = float(partId);

        if (partId != 0) {
            // HWAL_UV263: UV face rectangles remain stable when vertex ordering changes.
            vec4 samp1 = texelFetch(Sampler0, ivec2(54, 20), 0);
            vec4 samp2 = texelFetch(Sampler0, ivec2(55, 20), 0);
            bool slim = samp1.a == 0.0 || (((samp1.r + samp1.g + samp1.b) == 0.0) && ((samp2.r + samp2.g + samp2.b) == 0.0) && samp1.a == 1.0 && samp2.a == 1.0);
            hwal_texCoord1 = vec2(slim ? 1.0 : 0.0, 0.0);

            // assign output
            vec3 wpos = Position;
            wpos.y += SPACING * (partId + 1);
            gl_Position = ProjMat * ModelViewMat * vec4(wpos, 1.0);

            hwal_sphericalVertexDistance = fog_spherical_distance(wpos);
            hwal_cylindricalVertexDistance = fog_cylindrical_distance(wpos);
            
            hwal_texCoord0 = UV0;


            return;
        }
    }
#endif

    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    hwal_sphericalVertexDistance = fog_spherical_distance(Position);
    hwal_cylindricalVertexDistance = fog_cylindrical_distance(Position);

    hwal_texCoord0 = UV0;
#ifdef APPLY_TEXTURE_MATRIX
    hwal_texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif
}

#endif
void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);

#ifdef PER_FACE_LIGHTING
    vec2 light = minecraft_compute_light(Light0_Direction, Light1_Direction, Normal);
    vertexPerFaceColorBack = minecraft_mix_light_separate(-light, Color);
    vertexPerFaceColorFront = minecraft_mix_light_separate(light, Color);
#elif defined(NO_CARDINAL_LIGHTING)
    vertexColor = Color;
#else
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
    lightMapColor = sample_lightmap(Sampler2, UV2);
#endif

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
    overlayColor = texelFetch(Sampler1, UV1, 0);
#endif

    texCoord0 = UV0;

#ifdef APPLY_TEXTURE_MATRIX
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif

#ifdef GLINT
    texCoordGlint = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif

#ifdef MAYBE_PLAYERDISP
 hwal_legacy();
 texCoord0=hwal_texCoord0;
#endif
}
