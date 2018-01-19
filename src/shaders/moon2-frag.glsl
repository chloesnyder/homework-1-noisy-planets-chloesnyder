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

// referenced https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Brushed_Metal#Implementation_of_Ward's_BRDF_Model

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform vec4 u_Eye;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

in vec2 fs_UV;
in float displacement;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// referenced: https://thebookofshaders.com/13/

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
     return a + b*cos(6.28318f * (c*t+d));
}  

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm (vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}


void main()
{
        vec3 b = vec3(0.6, 0.6, 0.7);
        vec3 c = vec3(0.2, 0.2, 0.2);
        vec3 d = vec3(8.f, 8.f, 9.f);
        vec3 a = vec3(0.f, 0.0f, 0.f);

     /*   //if(displacement > 0.f) {
           // vec2 st = gl_FragCoord.xy / cross(gl_FragCoord.xy, fs_UV);
            st.x *= displacement;
            vec4 diffuseColor = fs_Col;//vec4(palette(displacement, a, b, c, d),1.f);
            float noise = fbm(st*2.0f + displacement);
            diffuseColor += vec4(noise, noise, noise, 0.f);

        
    //    } else {

//        }*/

    out_Col = fs_Col;
     
}