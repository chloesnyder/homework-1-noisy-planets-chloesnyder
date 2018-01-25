#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

float noise(vec3 x)
{
    return fract(sin(dot(x, vec3(44.2432, 532.313, 491.91))) * 72.3274);
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
float fbm(vec3 x, int octaves) 
{ 
    float total = 0.0;
    float persistence =  1.0 / 1.5f;
    float amplitude = .5;
    float maxPossible = 0.0;
    float frequency = 5.0;

    for(int i = 0; i < octaves; ++i)
    {
        total += amplitude * perlinNoise(x * frequency); // 3D value noise function
        maxPossible += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }
    return total;
}
// Referenced slides in https://petewerner.blogspot.com/2015/02/intro-to-curl-noise.html
vec3 curlNoise (vec3 v)
{
    float eps = 1.0;
    float n1, n2, n3, a, b, c;
    vec3 curl;

    n1 = fbm((v + vec3(0.0, eps, 0.0)), 2);
    n2 = fbm((v - vec3(0.0, eps, 0.0)), 2);
    a = (n1 - n2) / (2.0 * eps);

    n1 = fbm((v + vec3(0.0, 0.0, eps)), 2);
    n2 = fbm((v - vec3(0.0, 0.0, eps)), 2);
    b = (n1 - n2) / (2.0 * eps);

    curl.x = a - b;

    n1 = fbm((v + vec3(0.0, 0.0, eps)), 2);
    n2 = fbm((v - vec3(0.0, 0.0, eps)), 2);
    a = (n1 - n2) / (2.0 * eps);

    n1 = fbm((v + vec3(eps, 0.0, 0.0)), 2);
    n2 = fbm((v - vec3(eps, 0.0, 0.0)), 2);
    b = (n1 - n2) / (2.0 * eps);

    curl.y = a - b;

    n1 = fbm((v + vec3(eps, 0.0, 0.0)), 2);
    n2 = fbm((v - vec3(eps, 0.0, 0.0)), 2);
    a = (n1 - n2) / (2.0 * eps);

    n1 = fbm((v + vec3(0.0, eps, 0.0)), 2);
    n2 = fbm((v - vec3(0.0, eps, 0.0)), 2);
    b = (n1 - n2) / (2.0 * eps);

    curl.z = a - b;

    return normalize(curl);
}


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vec4(curlNoise(vs_Pos.xyz),1.0);

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
