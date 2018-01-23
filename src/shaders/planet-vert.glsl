#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

#define PI 3.1415926535897932384626433832795
#define RED vec3(1.0, 0.0, 0.0);
#define YELLOW vec3(1.0,1.0,0.0);
#define PINK vec3(1.0,0.0,1.0);
#define CYAN vec3(0.0,1.0,1.0);
#define BLUE vec3(0.0,0.0,1.0);
#define ORANGE vec3(1.0,0.50,0.0);
#define OLIVE vec3(.5,.5,.0);
#define WHITE vec3(1.0,1.0,1.0);
#define GRAY vec3(.5,.5,.5);

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
uniform vec4 u_Eye;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

out float isWater;

const vec4 sphereCenter = vec4(0.0,0.0,0.0,1.0);

float minDist;

// The following are from https://www.shadertoy.com/view/4dS3Wd
float hash(float n) 
{ 
    return fract(sin(n) * 1e4); 
}

float hash(vec2 p) 
{ 
    return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}
float noise(float x) 
{ 
    float i = floor(x); 
    float f = fract(x); 
    float u = f * f * (3.0 - 2.0 * f); 
    return mix(hash(i), hash(i + 1.0), u); 
}
float noise(vec2 x) 
{ 
    vec2 i = floor(x); 
    vec2 f = fract(x); 
    float a = hash(i); 
    float b = hash(i + vec2(1.0, 0.0)); 
    float c = hash(i + vec2(0.0, 1.0)); 
    float d = hash(i + vec2(1.0, 1.0)); 
    vec2 u = f * f * (3.0 - 2.0 * f); 
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y; 
}

float noise(vec3 x) 
{ 
    const vec3 step = vec3(110., 241., 171.); 
    vec3 i = floor(x); 
    vec3 f = fract(x); 
    float n = dot(i, step); 
    vec3 u = f * f * (3.0 - 2.0 * f); 
    return mix(mix(mix( hash(n + dot(step, vec3(0., 0., 0.))), hash(n + dot(step, vec3(1., 0., 0.))), u.x), mix( hash(n + dot(step, vec3(0., 1., 0.))), hash(n + dot(step, vec3(1., 1., 0.))), u.x), u.y), mix(mix( hash(n + dot(step, vec3(0., 0., 1.))), hash(n + dot(step, vec3(1., 0., 1.))), u.x), mix( hash(n + dot(step, vec3(0., 1., 1.))), hash(n + dot(step, vec3(1., 1., 1.))), u.x), u.y), u.z); 
}


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

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d));
}

vec3 greenPalette(float t)
{
    vec3 a = vec3(0.0, .5, 0.1);
    vec3 b = vec3(0.0, .50, 0.0);
    vec3 c = vec3(0.4, .50, 0.0);
    vec3 d = vec3(0.0, .15, 0.20);
    return a + b*cos( 6.28318*(c*t+d));
}

vec3 bluePalette(float t)
{
    vec3 a = vec3(0.0, 0.0, 1.0);
    vec3 b = vec3(0.0, 0.0, 1.0);
    vec3 c = vec3(0.0, 0.0, 1.0);
    vec3 d = vec3(0.0, 0.0, 1.0);
    return a + b*cos( 6.28318*(c*t+d));
}

int to1D (int x, int y, int z, int height, int width, int depth)
{
    return x + y * width + z * width * depth;
}

// output a nearest grid cell index
//assume worley outputs color of "zone"
// Thank you to Adam and Charles for helping me develop this function
vec3 worleyNoise(vec3 p, float scalar)
{
    vec3 color = vec3(.0);

    vec3 gridSpacePoint = p * scalar; // Scalar can be 1 for now for testing
    minDist = 10.0;
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
    vec3 coord = floor(gridSpacePoint) + vec3(float(i0), float(j0), float(k0));
    coord = (coord + vec3(2.0)) / 4.0;
    return coord;
}

// Break up worley noise into a voronoi type diagram
vec3 colorize(vec3 coord)
{  
    if(coord.x < .3 && coord.x > .15)
    {
        if(coord.y < .3 && coord.y > .15)
        {
             // red biome
            return RED;
        } else if (coord.y > .3) {
            // yellow biome
            return YELLOW;
        }  else {
            // pink biome
            return PINK;
        }     
    } else if(coord.x < .15 && coord.x > -.2) {
        if(coord.z < .5 && coord.z > -.2)
        {
            //cyan biome
            return CYAN;
        }
        //blue biome
        return BLUE;
    } else {
        if(coord.y < .3 && coord.y > .15)
        {
             // orange biome
            return ORANGE;
        } else if (coord.y > .12 ) {
            if(coord.z > .4)
            {
                // puke color?
                return OLIVE; 
            }
            // white biome
            return WHITE;
        } else if (coord.y < .78) {
            //gray biome
             return GRAY;
        }  else if (coord.z < 0.){
            // pink biome
            return PINK;
        }  else {
            // black biome
            return vec3(0.0);
        }
    }
}

// use input color to determine what biome this vertex lies on
// calculate noise function
float biomes(vec3 c)
{
    float epsilon = .0001;
    vec3 olive = OLIVE;
    vec3 blue = BLUE;
    vec3 red = RED;
    vec3 pink = PINK;
    vec3 yellow = YELLOW;
    vec3 orange = ORANGE;
    vec3 gray = GRAY;

    float t = 1.0;

    if(all(lessThan(abs(c) - blue, vec3(epsilon))))
    {
        isWater = 1.0;
        fs_Col = vec4(.3, 0., 0., 1.) * vec4(worleyNoise(vs_Pos.xyz, 5.0),1.0);
        //fs_Col = vec4(bluePalette(t),1.0);
        return t;
    } else if (all(lessThan(abs(c) - red, vec3(epsilon)))) 
    {
        t = hash(vs_Pos.x * vs_Pos.y) * noise(vs_Pos.xyz) + noise(71324382.f);
        fs_Col = vec4(greenPalette(t),1.0);
        return t;
        
    } else {
        fs_Col = vec4(c,1.0);;
        return 1.0f;
    }
}

void main()
{
    float scalar = sqrt(3.0);
    vec3 pos = vs_Pos.xyz;
    vec3 worley = worleyNoise(pos, scalar);
    vec4 worleyColor = vec4(worley * (1.0 - minDist), 1.);
    vec3 c = colorize(worley);
    float displacement = biomes(c);
    vec4 color =  vec4(c, 1.0);                         // Pass the vertex colors to the fragment shader for interpolation

    fs_Pos = vs_Nor * displacement * .1 + vec4(pos,1.0);
    //fs_Col = color;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(normalize(invTranspose * vec3(vs_Nor)), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * fs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = normalize(u_Light - modelposition);  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
