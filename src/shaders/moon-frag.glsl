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

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
     return a + b*cos(6.28318f * (c*t+d));
}    

void main()
{
        vec3 b = vec3(0.6, 0.6, 0.7);
        vec3 c = vec3(0.2, 0.2, 0.2);
        vec3 d = vec3(8.f, 8.f, 9.f);
        vec3 a = vec3(0.f, 0.0f, 0.f);

       vec4 diffuseColor = fs_Nor + vec4(palette(displacement, a, b, c, d),1.f);

        out_Col = diffuseColor;
}
