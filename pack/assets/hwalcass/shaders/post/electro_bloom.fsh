#version 330
#extension GL_ARB_separate_shader_objects : require
uniform sampler2D InSampler;
layout(std140) uniform BloomConfig { vec2 Direction; float Radius; };
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
void main() {
    vec2 size=vec2(textureSize(InSampler,0));
    vec2 delta=Direction*Radius*(size.y/720.0)/size;
    vec3 glow=texture(InSampler,texCoord).rgb*0.227027;
    glow+=texture(InSampler,texCoord+delta*1.384615).rgb*0.316216;
    glow+=texture(InSampler,texCoord-delta*1.384615).rgb*0.316216;
    glow+=texture(InSampler,texCoord+delta*3.230769).rgb*0.070270;
    glow+=texture(InSampler,texCoord-delta*3.230769).rgb*0.070270;
    fragColor=vec4(glow,1.0);
}
