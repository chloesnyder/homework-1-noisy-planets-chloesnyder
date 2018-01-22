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


const vec4 sphereCenter = vec4(0.f,0.f,0.f,1.f);

vec2 convertToUV(vec4 sphereSurfacePt, vec4 sphereCenterPt)
{
    vec4 d = normalize(sphereSurfacePt - sphereCenterPt);
    float phi = atan(d.z, d.x);
    if(phi < 0.f) phi += PI * 2.f;
    float theta = acos(d.y);

    return vec2(1.f - phi / PI, 1.f - theta / PI);
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
    vec2 st = convertToUV(fs_Pos, sphereCenter);
 

    vec3 color = vec3(.0);

  /*  // Cell positions
    vec3 point[30];
    point[0] = .5 * vec3(1.0, 1.0, 1.0);
    point[1] = .5 * vec3(-1.0, 1.0, 1.0);
    point[2] = .5 * vec3(1.0, -1.0, 1.0);
    point[3] = .5 * vec3(1.0, 1.0, -1.0);
    point[4] = .5 * vec3(-1.0, -1.0, 1.0);
    point[5] = .5 * vec3(1.0, -1.0, -1.0);
    point[6] = .5 * vec3(-1.0, -1.0, -1.0);

    //now add some random points

   for(int i = 0; i < 30; i++)
    {
        point[i] = (random(vec3(float(i) / 30.f, 30.f - float(i) / 30.f, float(i*i)/30.f)));
    }


    float m_dist = 1.;  // minimun distance

    // 3D 
    // Iterate through the points positions
    for (int i = 0; i < 30; i++) {
       // vec3 spherePt = squareToSphere(point[i]);
        float dist = distance(vec3(fs_Pos),point[i]);

        // Keep the closer distance
        m_dist = min(m_dist, dist);
    }

    // Draw the min distance (distance field)
    color += vec3(1.) - vec3(m_dist);

    // Show isolines
    // color -= step(.7,abs(sin(50.0*m_dist)))*.3;

    out_Col = vec4(color,1.0);*/


    float scalar = 5.0;
    vec3 gridSpacePoint = fs_Pos.xyz * scalar; // Scalar can be 1 for now for testing
    float minDist = 10.0;
    for(int i = -1; i <= 1; ++i)
    {
        for(int j = -1; j <= 1; ++j)
        {
            for(int k = -1; k <= 1; ++k)
            {
                vec3 gridCellCorner = floor(gridSpacePoint) + vec3(float(i), float(j), float(k));
                vec3 worleyPoint = random3D(gridCellCorner);
                float dist = distance(worleyPoint + gridCellCorner, gridSpacePoint);
                minDist = min(minDist, dist);
            }
        }
    }
    color = vec3(minDist);
    out_Col = vec4(color,1.0);
}
