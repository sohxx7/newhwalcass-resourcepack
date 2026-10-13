#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in ivec2 UV2;

uniform sampler2D Sampler2;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
layout(location = 2) flat out vec4 vertexColor;

void main() {
    vec4 pos = ProjMat * ModelViewMat * vec4(Position, 1.0);

    pos.z = min(pos.z, pos.w * 0.999);
    gl_Position = pos;


    float thickness = 0.0015 * gl_Position.w; 
    if (gl_VertexIndex % 2 == 0) {
        gl_Position.x += thickness;
        gl_Position.y += thickness;
    } else {
        gl_Position.x -= thickness;
        gl_Position.y -= thickness;
    }


    sphericalVertexDistance = 0.0; 
    cylindricalVertexDistance = 0.0;
    
    vec4 greenColor = vec4(0.0, 1.0, 0.0, Color.a); 
    vertexColor = greenColor * ColorModulator * texelFetch(Sampler2, UV2 / 16, 0);
}