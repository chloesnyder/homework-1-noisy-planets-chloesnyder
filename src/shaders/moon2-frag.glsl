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

// referenced https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Brushed_Metal#Implementation_of_Ward's_BRDF_Model

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform vec4 u_Eye;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

in vec2 fs_UV;
in float displacement, dx, dy, dz;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// referenced: https://thebookofshaders.com/13/
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

void main()
{
        vec4 diffuseColor = fs_Col;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
         diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    float scalar = 5.;
    float summedNoise = 0.0;
    float amplitude = 0.5; 
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
                summedNoise += minDist * amplitude;
                amplitude *= .5;
            }
        }
    }
    vec3 color = .5 * vec3(minDist);
                                                     

        // Compute final shaded color
        out_Col = vec4((color.rgb + diffuseColor.rgb) * lightIntensity, diffuseColor.a);

}
