#include "lib/Version.glsl"

#include "lib/Common.glsl"
#include "lib/Bloom.glsl"

const bool colortex0MipmapEnabled = true;

#include "lib/TextureIncludes.glsl"

uniform float frameTimeCounter;

uniform float viewWidth;

in vec2 texCoord;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;

#define APPLY_BLOOM_X true //[false true]

void main()
{
    vec4 inputColour = texture(colortex0, texCoord);

    vec3 bloom = (APPLY_BLOOM_X ? blurX(colortex1, texCoord, 5, viewWidth / 5.0, 10.0) : texture(colortex1, texCoord).rgb);

    outColor0 = inputColour;
    outColor1 = vec4(bloom, 1.0);
}