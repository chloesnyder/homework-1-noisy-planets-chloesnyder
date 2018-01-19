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
out vec4 fs_Tangent;

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

//https://thebookofshaders.com/13/
float random (vec2 st) {
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


// given theta E [0, pi/2] and phi E [0, 2pi]
// convert square to sphere coords
vec3 squareToSphere(float theta, float phi)
{   
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

vec3 getTangent(vec3 nor)
{
    vec3 c1 = cross(nor, vec3(0, 0, 1));
    vec3 c2 = cross(nor, vec3(0, 1, 0));
    if (length(c1) > length (c2))
    {
        return c1;
    } else  {
        return c2;
    }
}

void main()
{
    vec4 pos = vs_Pos;
    vec2 uv = convertToUV(pos, sphereCenter); // convert worldspace vector into polar uv coordinates

    const int numCircles = 2 * 12 * 9;
    vec3 samples[numCircles];
    float radii[numCircles];
    int count = 0;

    for(float theta = 0.f; theta < 90.f * PI/180.f; theta += (10.f * PI/180.f))
    {
        for(float phi = 0.f; phi < 2.f * PI ; phi += (30.f * PI/180.f))
        {
            float fbm1 = fbm(vec2(phi, theta));
            float fbm2 = fbm(vec2(theta, phi));
            float thetaOffset = cos_interp(theta, phi, fbm(vec2(fbm1, fbm2)));
            float phiOffset = cos_interp(fbm1, theta, thetaOffset);
            vec3 spherePt = squareToSphere(theta + fbm1 + phi * thetaOffset, phi + fbm2 + theta * phiOffset);
            samples[count] = spherePt;
            radii[count] = .12f * cos_interp(thetaOffset, phiOffset, noise(vec2(float(count), fbm2)));
            samples[count + 1] = -spherePt;
            radii[count+1] = .4 * cos_interp(fbm1, phiOffset, noise(vec2(phi, fbm2)));
            count += 2;
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
            float scale = pow(.5f, domeDist);
            displacement += cos_interp(0.f, 1.f, scale * domeDist);
        } 
    }

    

   float fbm = fbm(convertToUV(vs_Nor, sphereCenter));

    vec3 newNor = fbm * vec3(vs_Nor);

    fs_Tangent = vec4(getTangent(newNor),0.f);
    
    pos -= displacement * vs_Nor * .1 * fbm;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * newNor, 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = u_Eye - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

}
