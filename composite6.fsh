#include "lib/Version.glsl"

#include "lib/Common.glsl"

const bool colortex0MipmapEnabled = true;

#include "lib/TextureIncludes.glsl"

uniform float frameTimeCounter;

in vec2 texCoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

#define USE_SHARPNESS true //[false true]
#define SHARPNESS_STRENGTH 2 //[1 2 3 4 5 6 7 8 9 10]
#define SHARPNESS_RADIUS 2.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0]

#define EXTRA_ZOOM 0.0 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define SIDE_JITTER false //[false true]
#define SIDE_JITTER_AMMOUNT 0.001 //[0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.01]

void main()
{
    vec2 coord = texCoord * 2.0 - 1.0;
    coord /= (1.0 + EXTRA_ZOOM);
    coord = coord * 0.5 + 0.5;

    if(SIDE_JITTER)
    {
        uint seed = uint(fract(frameTimeCounter) * 10000);
        coord.x += (pow(RandomValue(seed), 2.0) * 2.0 - 1.0) * SIDE_JITTER_AMMOUNT;
    }

    vec4 inputColour = texture(colortex0, coord);

    vec3 blurredColour = textureLod(colortex0, coord, SHARPNESS_RADIUS).rgb;
    inputColour.rgb = mix(inputColour.rgb, blurredColour, -SHARPNESS_STRENGTH);

    outColor0 = inputColour;
}