#include "lib/Version.glsl"

#include "lib/Common.glsl"
#include "lib/Bloom.glsl"

const bool colortex0MipmapEnabled = true;

#include "lib/TextureIncludes.glsl"

uniform float frameTimeCounter;

uniform float viewHeight;

in vec2 texCoord;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 outColor0;

#define BLOOM_STRENGTH 2.0 //[1.0 2.0 3.0 4.0 5.0]
#define APPLY_BLOOM_Y true //[false true]

//0 = none. 1 = hyperbolic tangent. 2 = beer's law. 3 = idk what its called
#define TONEMAPPING_METHOD 0 //[0 1 2 3]

void main()
{
    vec4 inputColour = texture(colortex0, texCoord);

    if(APPLY_BLOOM_Y)
    {
        vec3 bloom = blurY(colortex1, texCoord, 15, viewHeight / 10.0, 15.0);
        inputColour.rgb += bloom * BLOOM_STRENGTH;
    }

    if(TONEMAPPING_METHOD == 1)
        inputColour.rgb = tanh(inputColour.rgb);
    else if(TONEMAPPING_METHOD == 2)
        inputColour.rgb = 1.0 - exp(-inputColour.rgb);
    else if(TONEMAPPING_METHOD == 3)
        inputColour.rgb = (inputColour.rgb) / (1.0 + inputColour.rgb);

    outColor0 = inputColour;
}