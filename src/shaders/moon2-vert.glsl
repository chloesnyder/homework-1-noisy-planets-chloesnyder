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

uniform vec4 u_Light;

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
    float z = 1.f - (2.f * cos(theta));
    float e1 = cos(theta);
    float e2 = phi / (2.f * PI);
    float xnew = cos(2.f*PI*e2) * sqrt(1.f - z * z);
    float ynew = sin(2.f*PI*e2) * sqrt(1.f - z * z);
    float znew = 1.f - 2.f*e1;
    return vec3(xnew,ynew,znew);
}


void main()
{
    vec4 pos = vs_Pos;
    vec2 uv = convertToUV(pos, sphereCenter); // convert worldspace vector into polar uv coordinates

    fs_UV = uv;

    const int numCircles = 50;
    vec3 samples[numCircles];
    float radii[numCircles];
    vec2 phiThetaPair[numCircles];
    int count = 0;

    // Use uniform spherical distribution to sample points on the sphere
    // From offset each point by some theta and phi offset to add randomness
    // These samples will be the center of randomly placed circles on the moon's surface
    // Generate a random radii. These circles will be where craters are placed 
    for(float theta = 0.f; theta < 90.f * PI/180.f; theta += (18.f * PI/180.f))
    {
        for(float phi = 0.f; phi < 2.f * PI ; phi += (16.f * PI/180.f))
        {
            float thetaOffset = cos_interp(theta, phi, phi);
            float phiOffset = cos_interp(phi, theta, thetaOffset);
            float u = theta + phi * thetaOffset;
            float v = phi + theta * phiOffset;
            vec3 spherePt = squareToSphere(u, v);
            samples[count] = spherePt;
            radii[count] = .1f * cos_interp(thetaOffset, phiOffset, float(count));
            phiThetaPair[count] = vec2(phi, theta);
            count += 1;
        }
    }

    vec3 centerCol;
    displacement = 0.f;
    for(int i = 0; i < numCircles; i++)
    {
        // To create crater depth,use a sin curve to displace the vertex along it's normal by some   
        float dist = distance(pos.xyz, samples[i]);
        float cx = pos.x + dist * sin(pos.z / 5.f);
        float cy = pos.y + dist * sin(pos.z / 3.f);
        radii[i] += .1 * cos(sqrt(99.f * cx*cx + cy*cy + 1.f)+dist);
        if(dist <= pow(radii[i], 2.f))
        {
            
            float domeDist = dist / radii[i];
            float t = clamp(0.f, PI / 2., dist / radii[i]);
            
            displacement += (sin(t));  
            centerCol = vec3(dist, dist, dist);              
        } 
        float r2 = pow(radii[i], 2.f);

        if(dist > r2 && dist < r2 + .02)
        {
            float t = clamp(0.f, 1.f, dist / radii[i]);
            pos += ((pow(2.0, t) / 10.f) * vs_Nor * .1);
            centerCol = vec3(dist, dist,dist);
        }
        
    }


        float noise = cos(sin(displacement));
        float noise2 = cos(noise);

         if(fract(noise * noise2) < 1.f )
        {        
          pos += ((pow(2.0, displacement) / 10.f) * vs_Nor * .1);
        }

        pos -= (displacement * vs_Nor * .1);
        

        float deltaPos = 5. * distance(vs_Pos, pos);
        // Determine if the point should be moved outward or inward (inward = inside crater, outward = small peak outside crater)
        float posOrNeg = distance(pos, sphereCenter) - distance(vs_Pos, sphereCenter);
        vec3 col;
        if(posOrNeg >= 0.f)
        {
            col = vec3(.5, .5, .5) + vec3(deltaPos) + centerCol;

        } else {
            col = vec3(.5, .5, .5) - vec3(deltaPos) + centerCol;
        }
        fs_Col = vec4(col, 1.0);
    

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below
    vec4 lightPosition = u_Model * (u_Light);
    fs_Pos = vs_Pos;
    

    fs_LightVec = u_Light  - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

}
