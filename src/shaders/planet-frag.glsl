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

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

uniform vec4 u_Eye;

#define PI 3.1415926535897932384626433832795
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


in float isWater;
const vec4 sphereCenter = vec4(0.0,0.0,0.0,1.0);

vec2 convertToUV(vec4 sphereSurfacePt, vec4 sphereCenterPt)
{
    vec4 d = normalize(sphereSurfacePt - sphereCenterPt);
    float phi = atan(d.z, d.x);
    if(phi < 0.0) phi += PI * 2.0;
    float theta = acos(d.y);

    return vec2(1.0 - phi / PI, 1.0 - theta / PI);
}

vec3 random3D (vec3 st) {
    float x = fract(sin(dot(st.xyz,
                         vec3(12.9898,78.233,78.233)))*
        52758.5453123);
    float y = fract(sin(dot(st.xyz,
                         vec3(134578989.8,7131.233,78.233)))*
        454.53123);
    float z = fract(sin(dot(st.xyz,
                         vec3(18.23498,72.25333,5438.233)))*
        43714791.53123);
    return(vec3(x,y,z));
}

vec3 random3DTest(vec3 st) {
    return vec3(fract(sin(dot(st, vec3(12.9898, 78.233, 56.176)) * 43758.5453)));
}

void main() {
    
   vec4 diffuseColor = fs_Col;

     // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.2;
    float shininess = 10.0;
    float attenuation = 3.0;
    float specularTerm = 0.0;
    vec4 viewDirection = normalize(u_Eye - fs_Pos);

    // Compute blinn-phong specular highlight on ocean surfaces
    if(dot(fs_Nor, fs_LightVec) > 0. && (abs(isWater - 1.0) < 0.01) )
    {
          
        specularTerm = attenuation * pow(max(0.0, dot(reflect(-fs_LightVec, fs_Nor), viewDirection)),
	      shininess);
    }

    float lightIntensity = diffuseTerm + ambientTerm + specularTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
