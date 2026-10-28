#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
uniform sampler2D InSampler;
uniform sampler2D EnergySampler;
uniform sampler2D BloomSampler;
layout(std140) uniform ElectroConfig { float Intensity; float EdgeHeight; float Speed; float Distortion; };
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
void main() {
    vec4 original=texture(InSampler,texCoord);
    float aspect=ScreenSize.x/max(ScreenSize.y,1.0);
    float edge=min(min(texCoord.x,1.0-texCoord.x)*aspect,min(texCoord.y,1.0-texCoord.y));
    float height=clamp(EdgeHeight,0.10,0.30);
    if(edge>=height || Intensity<=0.0) { fragColor=original; return; }
    vec4 energy=texture(EnergySampler,texCoord);
    vec3 bloom=texture(BloomSampler,texCoord).rgb;
    float fade=1.0-smoothstep(height*0.72,height,edge);
    vec2 px=1.0/vec2(textureSize(EnergySampler,0));
    vec2 field=vec2(texture(EnergySampler,texCoord+vec2(px.x*3.0,0)).g-texture(EnergySampler,texCoord-vec2(px.x*3.0,0)).g,
                    texture(EnergySampler,texCoord+vec2(0,px.y*3.0)).g-texture(EnergySampler,texCoord-vec2(0,px.y*3.0)).g);
    vec2 displaced=clamp(texCoord+field*Distortion*0.003*fade,px*0.5,1.0-px*0.5);
    vec3 scene=texture(InSampler,displaced).rgb;
    float absorption=clamp(energy.a*0.55+bloom.g*0.65+energy.g*0.30,0.0,0.8)*fade;
    scene*=mix(vec3(1.0),vec3(0.65,0.50,0.07),absorption);
    vec3 emitted=energy.rgb+bloom*.65;
    vec3 color=scene+(1.0-scene)*clamp(emitted,0.0,1.0);
    fragColor=vec4(mix(original.rgb,color,fade),original.a);
}
