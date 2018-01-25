#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

#define PI 3.1415926535897932384626433832795

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float lin_interp(float a, float b, float t)
{
   return a * (1.0 - t) + b * t;
}

float cos_interp(float a, float b, float t)
{
    float cos_t = (1.0 - cos(t * PI)) * .5f;
    return lin_interp(a,b,cos_t);
}

float noise(vec3 x)
{
    return fract(sin(dot(x, vec3(414.2432, 532.313, 491.91))) * 7182.3274);
}

float perlinNoise(vec3 v) 
{ 
    vec3 nXnYnZ = floor(v); // grid corner
    vec3 i = fract(v);

    // generate other grid corners
    vec3 pXpYpZ = nXnYnZ + vec3(1.0, 1.0, 1.0);
    vec3 pXpYnZ = nXnYnZ + vec3(1.0, 1.0, 0.0);
    vec3 pXnYnZ = nXnYnZ + vec3(1.0, 0.0, 0.0);
    vec3 pXnYpZ = nXnYnZ + vec3(1.0, 0.0, 1.0);
    vec3 nXpYpZ = nXnYnZ + vec3(0.0, 1.0, 1.0);
    vec3 nXnYpZ = nXnYnZ + vec3(0.0, 0.0, 1.0);
    vec3 nXpYnZ = nXnYnZ + vec3(0.0, 1.0, 0.0);

    // feed these grid corners into a noise function that takes a vec3 and returns a float
    float ppp = noise(pXpYpZ);
    float ppn = noise(pXpYnZ);
    float pnn = noise(pXnYnZ);
    float pnp = noise(pXnYpZ);
    float npp = noise(nXpYpZ);
    float nnp = noise(nXnYpZ);
    float npn = noise(nXpYnZ);
    float nnn = noise(nXnYnZ);

    // interpolate 3D  to 2D
    float nn = nnn * (1.0 - i.x) + pnn * i.x;
    float np = nnp * (1.0 - i.x) + pnp * i.x;
    float pn = npn * (1.0 - i.x) + ppn * i.x;
    float pp = npp * (1.0 - i.x) + ppp * i.x;

    //interpolate 2D to 1 D
    float n = nn * (1.0 - i.y) + pn * i.y;
    float p = np * (1.0 - i.y) + pp * i.y;

    return n * (1.0 - i.z) + p * i.z;

}

// Referenced slides in https://petewerner.blogspot.com/2015/02/intro-to-curl-noise.html
vec3 curlNoise (vec3 v)
{
    float eps = 1.0;
    float n1, n2, n3, a, b, c;
    vec3 curl;

    n1 = perlinNoise(v + vec3(0.0, eps, 0.0));
    n2 = perlinNoise(v - vec3(0.0, eps, 0.0));
    a = (n1 - n2) / (2.0 * eps);

    n1 = perlinNoise(v + vec3(0.0, 0.0, eps));
    n2 = perlinNoise(v - vec3(0.0, 0.0, eps));
    b = (n1 - n2) / (2.0 * eps);

    curl.x = a - b;

    n1 = perlinNoise(v + vec3(0.0, 0.0, eps));
    n2 = perlinNoise(v - vec3(0.0, 0.0, eps));
    a = (n1 - n2) / (2.0 * eps);

    n1 = perlinNoise(v + vec3(eps, 0.0, 0.0));
    n2 = perlinNoise(v - vec3(eps, 0.0, 0.0));
    b = (n1 - n2) / (2.0 * eps);

    curl.y = a - b;

    n1 = perlinNoise(v + vec3(eps, 0.0, 0.0));
    n2 = perlinNoise(v - vec3(eps, 0.0, 0.0));
    a = (n1 - n2) / (2.0 * eps);

    n1 = perlinNoise(v + vec3(0.0, eps, 0.0));
    n2 = perlinNoise(v - vec3(0.0, eps, 0.0));
    b = (n1 - n2) / (2.0 * eps);

    curl.z = a - b;

    return normalize(cos(u_Time / 100.0) * curl);
}

float fbm(vec3 x, int octaves) 
{ 
    float total = 0.0;
    float persistence =  1.0 / 1.5f;
    float amplitude = .5;
    float maxPossible = 0.0;
    float frequency = 5.0;

    float t =  u_Time / 100000.0;

    for(int i = 0; i < octaves; ++i)
    {
        total += amplitude * perlinNoise(x * frequency * t); // 3D value noise function
        maxPossible += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }
    return total;
}


void main()
{
    // Material base color (before shading)
        float alpha = 1.0 - fbm(vec3(fs_Pos) + vec3((u_Time / 50.0)), 15);
        alpha = cos_interp(alpha / 2.0, alpha / 7.0, dot(vec3(u_Time / 100.0), vec3(fs_Pos)));
        vec4 diffuseColor = vec4(1.0, 1.0, 1.0, alpha);

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
         diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
