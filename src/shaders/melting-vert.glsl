#version 300 es
#define PI 3.1415926535897932384626433832795

// Referenced these tutorials: http://diary.conewars.com/vertex-displacement-shader/, http://diary.conewars.com/melting-shader-part-2/
// inspiration and some functions from these sources (genWave in particular)
//https://www.shadertoy.com/view/4dlGDN , https://www.shadertoy.com/view/XsXSW8 , https://www.shadertoy.com/view/XtscWr 
// https://www.shadertoy.com/view/4ljXDy, https://www.shadertoy.com/view/ltffzl , https://www.shadertoy.com/view/XdXGR7 , https://www.shadertoy.com/view/4ldSRj 
// https://www.shadertoy.com/view/ldySDh  https://www.shadertoy.com/view/XlXBRX 


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

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Pos;
out vec4 fs_Tangent;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

const float speed = .1f;
const float amount = 3.f;
const float distance = .1f;


float oPdisplace( vec3 p )
{
    float d1 = length(p) - .5f;
    float d2 = sin(p[0])*sin(p[1]*2.f)*sin(2.f*p[2]);
    return d1+d2;
}


mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

float genWave1(float len)
{
	float wave = sin(8.0 * PI * len + .2 * u_Time);
	wave = (wave + 1.0) * 0.5; // <0 ; 1>
	wave -= 0.3;
	wave *= wave * wave;
	return wave;
}

float genWave2(float len)
{
	float wave = sin(7.0 * PI * len + .2 * u_Time);
	float wavePow = 1.0 - pow(abs(wave*1.1), 0.8);
	wave = wavePow * wave; 
	return wave;
}

float scene(float len)
{
	return genWave1(len);
}

vec4 blob(vec4 position, vec4 normal)
{
    position[0] += pow(normal[0],2.f) + cos(u_Time * .1);
    position[2] += pow(normal[2],3.f) + sin(u_Time * .1);

    return position;
}

vec4 meltVertPos(vec4 position, vec4 normal)
{
 
    float meltY =  0.f;//-0.325f;
    float meltDistance = 1.f;
    float meltCurve = mix(pow(2.f, clamp(sin(.01f*u_Time), -.5f, 1.f)), pow(2.f, clamp(cos(.01f*u_Time), -.5f, 1.f)),.05f);
    float melt = (position[1] - meltY) / meltDistance;
    melt = 1.f - clamp(melt, -.666f, 1.f);
    melt = pow(melt, meltCurve);

    float gc_distance = acos(dot(normal[0],normal[2]));
    float gc_distance2 = acos(dot(normal[1],normal[2]));
    float distMix = mix(scene(gc_distance/3.f), scene(gc_distance/2.f), .01);

    position[0] += (normal[0] * melt * gc_distance/2.f);
    position[2] += ((normal[2] * melt * gc_distance/2.f) + (normal[2] * gc_distance2/2.f * distMix));

    return position;
}

vec3 getTangent()
{
    vec3 c1 = cross(vec3(vs_Nor), vec3(0, 0, 1));
    vec3 c2 = cross(vec3(vs_Nor), vec3(0, 1, 0));
    if (length(c1) > length (c2))
    {
        return c1;
    } else  {
        return c2;
    }
}

void main()
{

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation


    mat3 invTranspose = mat3(u_ModelInvTr);
  
    vec3 tangentv3 = getTangent();
    vec4 tangent = vec4(tangentv3, 0);
    vec4 bitangent = vec4(cross(vec3(vs_Nor), tangentv3),0);

    float offset = .1f;
    vec4 position =  meltVertPos( vs_Pos, vs_Nor);

    vec4 v1 = meltVertPos( vs_Pos + tangent * offset, vs_Nor );
	vec4 v2 = meltVertPos( vs_Pos + bitangent * offset, vs_Nor);
    vec4 newTangent = v1 - position;
    vec4 newBitangent = v2 - position;

    vec4 newNormal = normalize(vec4(cross(vec3(newTangent), vec3(newBitangent)),0));
  
    fs_Nor = vec4(invTranspose * vec3(newNormal), 0);
    fs_Tangent = vec4(invTranspose * vec3(newTangent), 0);

    float len = length(position - vec4(0,0,0,1));
    float wave = scene(len) / (1.0f + len);

    fs_Pos = mix(vs_Pos, position, clamp(sin(.01f * u_Time), 0.f, 1.f));

    vec4 modelposition = u_Model * fs_Pos;   // Temporarily store the transformed vertex positions for use below
    fs_LightVec = u_Eye - modelposition;  // Compute the direction in which the light source lies


    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices


}


