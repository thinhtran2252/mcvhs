const float e = 2.71828182846;

float gauss(float x, float a)
{
    a /= 3.14159;
    return pow(e, -0.5 * (x / a) * (x / a)) / (a * sqrt(2.0 * 3.14159));
}

vec3 blurX(sampler2D tex, vec2 uv, int samples, float screenWidth, float scale)
{
    vec3 blurred = vec3(0.0);
    for(int x = -samples; x < samples; x++)
    {
        blurred += texture(tex, uv + vec2(float(x), 0.0) / screenWidth).rgb * gauss(float(x), scale);
    }
    return blurred;
}

vec3 blurY(sampler2D tex, vec2 uv, int samples, float screenHeight, float scale)
{
    vec3 blurred = vec3(0.0);
    for(int y = -samples; y < samples; y++)
    {
        blurred += texture(tex, uv + vec2(0.0, float(y)) / screenHeight).rgb * gauss(float(y), scale);
    }
    return blurred;
}