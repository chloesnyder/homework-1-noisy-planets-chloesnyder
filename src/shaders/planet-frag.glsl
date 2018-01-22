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
#define PI 3.1415926535897932384626433832795
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

/*void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}*/

const vec4 sphereCenter = vec4(0.f,0.f,0.f,1.f);

vec2 convertToUV(vec4 sphereSurfacePt, vec4 sphereCenterPt)
{

    vec4 d = normalize(sphereSurfacePt - sphereCenterPt);
    float phi = atan(d.z, d.x);
    if(phi < 0.f) phi += PI * 2.f;
    float theta = acos(d.y);

    return vec2(1.f - phi / PI, 1.f - theta / PI);
}

vec3 squareToSphere(vec2 v)
{   
    float theta = v.x;
    float phi = v.y;
    float x = sin(theta) * cos(phi);
    float y = sin(theta) * sin(phi);
    float z = 1.f - (2.f * cos(theta));
    float e1 = cos(theta);
    float e2 = phi / (2.f * PI);
    float xnew = cos(2.f*PI*e2) * sqrt(1.f - z * z);
    float ynew = sin(2.f*PI*e2) * sqrt(1.f - z * z);
    float znew = 1.f - 2.f*e1;
    return vec3(xnew,ynew,znew);
}

/*float greatCircleDistance (vec3 a, vec3 b)
{
   return (cross(a, b) / dot(a, b));
}*/
 

void main() {
    vec2 st = convertToUV(fs_Pos, sphereCenter);
   // st.x /= .5f;
    //st.x *= u_resolution.x/u_resolution.y;

    vec3 color = vec3(.0);

    // Cell positions
    vec3 point[7];
    point[0] = .5 * vec3(1.0, 1.0, 1.0);
    point[1] = .5 * vec3(-1.0, 1.0, 1.0);
    point[2] = .5 * vec3(1.0, -1.0, 1.0);
    point[3] = .5 * vec3(1.0, 1.0, -1.0);
    point[4] = .5 * vec3(-1.0, -1.0, 1.0);
    point[5] = .5 * vec3(1.0, -1.0, -1.0);
    point[6] = .5 * vec3(-1.0, -1.0, -1.0);


    float m_dist = 1.;  // minimun distance

    // 3D 
    // Iterate through the points positions
    for (int i = 0; i < 7; i++) {
       // vec3 spherePt = squareToSphere(point[i]);
        float dist = distance(vec3(fs_Pos),point[i]);

        // Keep the closer distance
        m_dist = min(m_dist, dist);
    }

    // Draw the min distance (distance field)
    color += m_dist;

    // Show isolines
    // color -= step(.7,abs(sin(50.0*m_dist)))*.3;

    out_Col = vec4(color,1.0);
}
