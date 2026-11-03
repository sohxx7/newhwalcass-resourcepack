#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D MainSampler;
uniform sampler2D PartyIconSampler;

layout(std140) uniform SamplerInfo {
    vec2 OutSize;
    vec2 MainSize;
    vec2 IconSize;
};

layout(std140) uniform IconConfig {
    vec2 Layout;
    // x = 아이콘 개수
    // y = 아이콘 사이 간격
};

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 background = texture(MainSampler, texCoord);

    float count = Layout.x;
    float gap = Layout.y;

    float iconSize = 64.0;
    float totalWidth = count * iconSize + (count - 1.0) * gap;

    vec2 pixel = gl_FragCoord.xy;

    float startX = (OutSize.x - totalWidth) * 0.5;
    float startY = (OutSize.y - iconSize - 96.0) * 0.5;

    float localX = pixel.x - startX;
    float localY = pixel.y - startY;

    float index = floor(localX / (iconSize + gap));

    bool inside =
        localX >= 0.0 &&
        localX < totalWidth &&
        localY >= 0.0 &&
        localY < iconSize &&
        index < count &&
        mod(localX, iconSize + gap) < iconSize;

    if (!inside) {
        fragColor = background;
        return;
    }

    vec2 iconUV = vec2(
        mod(localX, iconSize + gap) / iconSize,
        localY / iconSize
    );

    vec4 icon = texture(PartyIconSampler, iconUV);

    fragColor = mix(background, icon, icon.a);
}