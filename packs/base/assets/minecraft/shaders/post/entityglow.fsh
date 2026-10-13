#version 330
#extension GL_ARB_separate_shader_objects : require

// radius of the glow
layout(std140) uniform SamplerInfo { vec2 OutSize; vec2 InSize; };
layout(std140) uniform BlurConfig { vec2 BlurDir; float Radius; };

// the final alpha of the area covering the entity
#define FinalAlpha 0.5


uniform sampler2D InSampler;


layout(location = 0) in vec2 texCoord;


layout(location = 0) out vec4 fragColor;

void main() {
 vec2 sampleStep = BlurDir / InSize;
float gradient = 1.0 / (Radius + 1.0);
bool isFinal = sampleStep.y != 0;
float finalAlpha = isFinal ? FinalAlpha : 1.0;
float additionalAlpha = isFinal ? gradient : 0.0;


  // get the current pixel
  vec4 pixelSample = texture(InSampler, texCoord);
  if (pixelSample.a >= 1.0) {
    // if the pixel is opaque then
    fragColor = vec4(pixelSample.rgb, finalAlpha);
  } else {
    // accumulated RGB colors
    vec3 blurs;
    // number of pixels accumulated in blurs variable
    float totalColor;
    // the alpha value that should be the output
    float alpha = pixelSample.a;

    if (alpha > 0.0) {
      totalColor = 1;
      blurs = pixelSample.rgb;
    } else {
      totalColor = 0;
      blurs = vec3(0.0);
    }

    // iterate from far to close
    for (float r = Radius; r > 0; r--) {
      vec2 step = sampleStep * r;
      vec4 sampleL = texture(InSampler, texCoord - step);
      vec4 sampleR = texture(InSampler, texCoord + step);
      if (sampleL.a > 0.0) {
        totalColor++;
        blurs += sampleL.rgb;
        alpha = max(alpha, sampleL.a - r * gradient);
      }
      if (sampleR.a > 0.0) {
        totalColor++;
        blurs += sampleR.rgb;
        alpha = max(alpha, sampleR.a - r * gradient);
      }
    }

    fragColor = alpha > 0.0 ? vec4(blurs / totalColor, alpha + additionalAlpha) : vec4(0.0);
  }
}
