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



layout(location = 8) in float hwal_sphericalVertexDistance;
layout(location = 9) in float hwal_cylindricalVertexDistance;
layout(location = 10) in vec4 hwal_vertexColor;
layout(location = 14) in vec4 hwal_overlayColor;
layout(location = 11) in vec2 hwal_texCoord0;
layout(location = 15) in vec4 hwal_shadeColor;
layout(location = 16) in vec4 hwal_lightMapColor;
layout(location = 17) in float hwal_alphaOffset;
vec4 hwalColor;

vec4 brightColor(vec4 color) {
    float max = 1 / max(color.r,max(color.g,color.b));
    return color * vec4(max, max, max, 1);
}

void hwal_legacy(){
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
