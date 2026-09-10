#version 150

// [활카스] ogresourcepack 의 SPD 프래그먼트에 1.21.8vfx 의 서명 관문을 얹은 것.
// 서명(스프라이트 네 모서리 픽셀)이 맞는 판만 VFX 경로로 가고, 나머지는 원래 코드 그대로다.

#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <globals.glsl>
#moj_import <vfx.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 shadeColor;
in vec4 lightMapColor;
in float alphaOffset;

// --- VFX ---
in vec3 vfxCornerA;
in vec3 vfxCornerB;
flat in vec2  vfxArc;
flat in vec2  vfxCrop;
flat in vec3  vfxTintColor;
flat in float vfxAlpha;
flat in int   vfxVariant;

out vec4 fragColor;

vec4 brightColor(vec4 color) {
    float max = 1 / max(color.r,max(color.g,color.b));
    return color * vec4(max, max, max, 1);
}

void main(){
    // --- VFX 관문 ---
    // 정점이 흘려보낸 대각선 두 코너로 스프라이트 사각형을 되살리고, 첫/마지막 텍셀의 서명을 읽는다.
    // texelFetch 라 밉맵·선형보간에 안 뭉개진다. 범위 밖 fetch 는 정의돼 있지 않으므로 반드시 묶는다.
    vec4 vfxRect = vfx_spriteRect(vfxCornerA, vfxCornerB);
    ivec2 vfxAtlas = textureSize(Sampler0, 0);
    ivec2 vfxLast = vfxAtlas - 1;
    ivec2 vfxLo = clamp(ivec2(vfxRect.xy * vec2(vfxAtlas) + 0.5), ivec2(0), vfxLast);
    ivec2 vfxHi = clamp(ivec2(vfxRect.zw * vec2(vfxAtlas) - 0.5), ivec2(0), vfxLast);
    int vfxType = vfx_readType(texelFetch(Sampler0, vfxLo, 0), texelFetch(Sampler0, vfxHi, 0));

    if (vfxType >= 0) {
        vec2 local = vfx_toLocal(texCoord0, vfxRect);
        vec4 vcol = texture(Sampler0, texCoord0);
        if (vfxType == VFX_TYPE_ARC) {
            vcol.a *= vfx_arcMask(vfx_turn(local, vfxVariant), vfxArc.x, vfxArc.y);
        } else if (vfxType == VFX_TYPE_CROP) {
            vcol.a *= vfx_cropMask(vfx_cropAxis(local, vfxVariant), vfxCrop.x, vfxCrop.y);
        }
        // 틴트는 rgb 에, 투명도는 알파에만. vertexColor 는 쓰지 않는다(염색색은 색이 아니라 데이터).
        vcol.rgb *= vfxTintColor;
        vcol.a   *= vfxAlpha;
        vcol *= ColorModulator;
        if (vcol.a < VFX_ALPHA_CUT) {
            discard;
        }
        fragColor = apply_fog(vcol, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
        return;
    }

    // --- 아래는 ogresourcepack 원본 그대로 ---
    vec4 rgb=texture(Sampler0,texCoord0);
    vec4 vCol=vertexColor;
    vec4 sCol=shadeColor;

    float noshade=1;
    bool light = false;
    if (rgb.a<254.5/255.0&&rgb.a>145.0/255.0) {
        noshade = 0;
        light = true;
    }


    rgb.a=max(0.,rgb.a-alphaOffset);

    vec4 color=rgb*mix(sCol,vCol,noshade)*ColorModulator;

    if(color.a < 0.01){
        discard;
    }
    color.rgb=mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= mix(vec4(1.), lightMapColor,1);
    fragColor= light ? color : apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
