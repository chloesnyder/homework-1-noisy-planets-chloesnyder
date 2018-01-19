#version 300 es
#define PI 3.1415926535897932384626433832795

// Referenced these tutorials: http://diary.conewars.com/vertex-displacement-shader/, http://diary.conewars.com/melting-shader-part-2/

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;

uniform vec4 u_Eye;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

in vec2 vs_UV;

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Pos;

out vec2 fs_UV;

out float displacement;

const vec4 sphereCenter = vec4(0.f,0.f,0.f,1.f);

vec2 convertToUV(vec4 sphereSurfacePt, vec4 sphereCenterPt)
{

    vec4 d = normalize(sphereSurfacePt - sphereCenterPt);
    float phi = atan(d.z, d.x);
    if(phi < 0.f) phi += PI * 2.f;
    float theta = acos(d.y);

    return vec2(1.f - phi / PI, 1.f - theta / PI);
}

bool inCircle(vec2 P, vec2 center, float radius)
{
    //test to see if current vector is inside circle
    float epsilon = .00001f;

    if(distance(P, center) < radius)
    {
        return true;
    }
   return false;
}

float lin_interp(float a, float b, float t)
{
   return a * (1.f - t) + b * t;
}

float cos_interp(float a, float b, float t)
{
    float cos_t = (1.f - cos(t * PI)) * .5f;
    return lin_interp(a,b,cos_t);
}

// given theta E [0, pi/2] and phi E [0, 2pi]
// convert square to sphere coords
vec3 squareToSphere(float theta, float phi)
{   
    float x = sin(theta) * cos(phi);
    float y = sin(theta) * sin(phi);
    float z = 1.f - 2.f * cos(theta);
    float e1 = cos(theta);
    float e2 = phi / (2.f * PI);
    float xnew = cos(2.f*PI*e2) * sqrt(1.f - pow(z,2.f));
    float ynew = sin(2.f*PI*e2) * sqrt(1.f - pow(z,2.f));
    float znew = 1.f - 2.f*e1;
    return vec3(xnew,ynew,znew);
}


void main()
{
    vec4 pos = vs_Pos;
    vec2 uv = convertToUV(pos, sphereCenter); // convert worldspace vector into polar uv coordinates

    const int numCircles = 9;
    vec3 samples[numCircles];
    float radii[numCircles];
    int count = 0;

    for(float theta = 0.f; theta <= 90.f; theta += 30.f)
    {
        for(float phi = 0.f; phi <= 360.f; phi += (120.f))
        {
            theta *= PI / 180.f;
            phi *= PI / 180.f;
            vec3 spherePt = squareToSphere(theta, phi);
            samples[count] = spherePt;
            radii[count] = .1f;
            count += 1;
        }
    }


    fs_Col = vec4(0.f,0.f,0.f,1.f);
    displacement = 0.f;
    for(int i = 0; i < numCircles; i++)
    {
        float dist = distance(pos.xyz, samples[i]);
        if(dist <= radii[i])
        {
            fs_Col = vec4(1.f,1.f,1.f,1.f);
            float domeDist = 1.f - dist / radii[i];
            // TODO: figure out a way to randomly generate a scale factor [0,1]
            float scale = 1.f;
            displacement += cos_interp(0.f, 1.f, scale * domeDist);
        } 
    }

    pos -= displacement * vs_Nor * 0.1f;
    

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = u_Eye - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

}
