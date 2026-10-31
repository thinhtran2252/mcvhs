#include "lib/Version.glsl"

#include "lib/Common.glsl"

const bool colortex0MipmapEnabled = true;

#include "lib/TextureIncludes.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

in vec2 texCoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

#define COMPRESSION_METHOD 0 //[0 1 2]

#define LUMA_COMPRESSION 2 //[1 2 3 4 5 6 7 8]
#define CHROMA_COMPRESSION 5 //[1 2 3 4 5 6 7 8]

#define CHROMA_BOOST 0.0 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

vec3 rgb2yuv(vec3 rgb)
{
    float y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    return vec3(y, 0.493 * (rgb.b - y), 0.877 * (rgb.r - y));
}

vec3 yuv2rgb(vec3 yuv)
{
    float y = yuv.x;
    float u = yuv.y;
    float v = yuv.z;
    
    return vec3
    (
        y + 1.0 / 0.877 * v,
        y - 0.39393 * u - 0.58081 * v,
        y + 1.0 / 0.493 * u
    );
}

const mat3 rgb2yiq = mat3
(
    0.299, 0.596, 0.211,
    0.587, -0.274, -0.523,
    0.114, -0.322, 0.312
);

const mat3 yiq2rgb = mat3
(
    1.0, 1.0, 1.0,
    0.956, -0.272, -1.106,
    0.621, -0.647, 1.703
);

vec3 rgb2ycbcr(vec3 c)
{
	float y = 0.299 * c.r + 0.587 * c.g + .114 * c.b;
	return vec3(y, (c.b-y) * 0.565, (c.r-y) * .713);
}

vec3 ycbcr2rgb(vec3 ycbcr)
{
	return vec3
    (
		ycbcr.x + 1.403 * ycbcr.z,
		ycbcr.x - 0.344 * ycbcr.y - 0.714 * ycbcr.z,
		ycbcr.x + 1.770 * ycbcr.y
	);
}

void main()
{
    vec4 inputColour = texture(colortex0, texCoord);

    if(COMPRESSION_METHOD == 0)
    {
        float y = rgb2yuv(textureLod(colortex0, texCoord, LUMA_COMPRESSION).rgb).x;
        vec2 uv = rgb2yuv(textureLod(colortex0, texCoord, CHROMA_COMPRESSION).rgb).yz;
        uv *= 1.0 + CHROMA_BOOST;
        vec3 rgb = yuv2rgb(vec3(y, uv));
        inputColour.rgb = rgb;
    }
    else if(COMPRESSION_METHOD == 1)
    {
        float y = (textureLod(colortex0, texCoord, LUMA_COMPRESSION).rgb * rgb2yiq).x;
        vec2 iq = (textureLod(colortex0, texCoord, CHROMA_COMPRESSION).rgb * rgb2yiq).yz;
        iq *= 1.0 + CHROMA_BOOST;
        vec3 rgb = vec3(y, iq) * yiq2rgb;
        inputColour.rgb = rgb;
    }
    else if(COMPRESSION_METHOD == 2)
    {
        float y = rgb2ycbcr(textureLod(colortex0, texCoord, LUMA_COMPRESSION).rgb).x;
        vec2 cbcr = rgb2ycbcr(textureLod(colortex0, texCoord, CHROMA_COMPRESSION).rgb).yz;
        cbcr *= 1.0 + CHROMA_BOOST;
        vec3 rgb = ycbcr2rgb(vec3(y, cbcr));
        inputColour.rgb = rgb;
    }

    outColor0 = inputColour;
}