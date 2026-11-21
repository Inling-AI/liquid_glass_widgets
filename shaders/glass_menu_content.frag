#include <flutter/runtime_effect.glsl>
#include "gles_compat.glsl"

uniform vec2 uSize;
uniform float uCornerRatio;
uniform float uRefraction;
uniform sampler2D uContent;

out vec4 fragColor;

void main() {
  vec2 pixel = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  float shortestSide = min(uSize.x, uSize.y);
  float radius = shortestSide * uCornerRatio;
  vec2 centered = pixel - halfSize;
  vec2 corner = abs(centered) - halfSize + radius;
  vec2 rounded = max(corner, vec2(0.0));
  float roundedLength = length(rounded);
  float distance = min(max(corner.x, corner.y), 0.0) + roundedLength - radius;
  vec2 axis = corner.x > corner.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec2 normal = sign(centered) *
      (roundedLength > 0.0 ? rounded / roundedLength : axis);
  float rimWidth = shortestSide * 0.20;
  float bend = smoothstep(-rimWidth, 0.0, distance);
  vec2 uv = (pixel - normal * (rimWidth * 0.48 * bend * uRefraction)) / uSize;
#ifdef LGR_GLES_FLIP_SAMPLE_Y
  uv.y = 1.0 - uv.y;
#endif
  fragColor = texture(uContent, uv);
}
