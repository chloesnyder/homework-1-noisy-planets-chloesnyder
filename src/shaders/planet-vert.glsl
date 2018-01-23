#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

#define PI 3.1415926535897932384626433832795

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform vec4 u_Light;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 sphereCenter = vec4(0.0,0.0,0.0,1.0);

vec2 convertToUV(vec4 sphereSurfacePt, vec4 sphereCenterPt)
{
    vec4 d = normalize(sphereSurfacePt - sphereCenterPt);
    float phi = atan(d.z, d.x);
    if(phi < 0.f) phi += PI * 2.f;
    float theta = acos(d.y);

    return vec2(1.f - phi / PI, 1.f - theta / PI);
}

vec2 random2( vec2 p ) {
    return normalize(2.0 * fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453) - 1.0);
}

float surflet(vec2 P, vec2 gridPoint)
{
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float tX = 1.f - 6.f * pow(distX, 5.0) + 15.f * pow(distX, 4.0) - 10.f * pow(distX, 3.0);
    float tY = 1.f - 6.f * pow(distY, 5.0) + 15.f * pow(distY, 4.0) - 10.f * pow(distY, 3.0);

    // Get the random vector for the grid point
    vec2 gradient = random2(gridPoint);
    // Get the vector from the grid point to P
    vec2 diff = P - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * tX * tY;
}

float PerlinNoise(vec2 uv)
{
    // Tile the space
    vec2 uvXLYL = floor(uv);
    vec2 uvXHYL = uvXLYL + vec2(1,0);
    vec2 uvXHYH = uvXLYL + vec2(1,1);
    vec2 uvXLYH = uvXLYL + vec2(0,1);

    return surflet(uv, uvXLYL) + surflet(uv, uvXHYL) + surflet(uv, uvXHYH) + surflet(uv, uvXLYH);
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

vec2 PixelToGrid(vec2 pixel, float size)
{
    vec2 u_Dimensions = vec2(30.0,30.0);
    vec2 uv = pixel.xy / u_Dimensions.xy;
    // Account for aspect ratio
    uv.x = uv.x * float(u_Dimensions.x) / float(u_Dimensions.y);
    // Determine number of cells (NxN)
    uv *= size;

    return uv;
}

vec3 summedPerlinNoise()
{
    vec3 color;
    float summedNoise = 0.0;
    float amplitude = 0.5;
    for(int i = 2; i <= 32; i *= 2) {
        vec2 uv = PixelToGrid(convertToUV(vs_Pos, sphereCenter), float(i));
        uv = vec2(cos(3.14159/3.0 * float(i)) * uv.x - sin(3.14159/3.0 * float(i)) * uv.y, sin(3.14159/3.0 * float(i)) * uv.x + cos(3.14159/3.0 * float(i)) * uv.y);
        float perlin = abs(PerlinNoise(uv));// * amplitude;
        summedNoise += perlin * amplitude;
        amplitude *= 0.5;
    }
    color = vec3(summedNoise);//vec3((summedNoise + 1) * 0.5);
    return color;
}

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d));
}

int to1D (int i, int j, int k, int iMax, int jMax, int kMax)
{
    return (k * iMax * jMax) + (j * iMax) + i;
}

// output a nearest grid cell index
//assume worley outputs color of "zone"
// Thank you to Adam and Charles for helping me develop this function
vec3 worleyNoise()
{
    vec3 color = vec3(.0);

    float scalar = sqrt(3.0);
    vec3 gridSpacePoint = vs_Pos.xyz * scalar; // Scalar can be 1 for now for testing
    float minDist = 10.0;
    int i0;
    int j0;
    int k0;
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
                //storing what the cell that is closest to this vertex is and return that instead of returning the minimum distance itself
                if(minDist == dist) {
                    i0 = i;
                    j0 = j;
                    k0 = k;
                }
            }
        }
    }
    vec3 final_coord = floor(gridSpacePoint) + vec3(float(i0), float(j0), float(k0));
    final_coord = (final_coord + vec3(2.0)) / 4.0;
   
    int idx = to1D(i0, j0, k0, 1, 1, 1);
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.80, 0.90, 0.30);
    vec3 col = palette(float(idx), a, b, c, d);
    return final_coord * (1.0 - minDist);
   // return col;
}

void main()
{
    vec4 worleyColor = vec4(worleyNoise(), 1.);
    vec4 color =  worleyColor;                         // Pass the vertex colors to the fragment shader for interpolation

  /*  if(vs_Pos.y > .7f)
    {
        color += vec4(.5, .5, .5, 0.);
    }
*/
    //  if(color.x + color.y + color.z > .0 && color.x + color.y + color.z < 1.5)
    //  {
    //      color = worleyColor *  vec4(1.,.1,1.0,1.0);
    //  }

   
     fs_Col = color;
    vec4 pos;
   /* if(color.x + color.y + color.z > .2f)
    {
        pos = vs_Pos + .1 * (color * vs_Nor);
    } else {
        pos = vs_Pos;
    }*/
    fs_Pos = vs_Pos;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * fs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = u_Light - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
