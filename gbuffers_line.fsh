#include "lib/Version.glsl"
#extension GL_ARB_explicit_attrib_location : enable

uniform float alphaTestRef;
uniform float frameTimeCounter;

in vec4 tint;
in vec3 position;

/*
const int colortex0Format = RGBA32F;
*/

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;

void main() {
	vec4 color = tint;
	if (color.a < alphaTestRef) discard;

	colortex0Out = color;
}