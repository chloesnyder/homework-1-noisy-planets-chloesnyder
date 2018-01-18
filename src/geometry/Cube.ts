import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;


  constructor(center: vec3) {
    super(); // Call the constructor of the super class. This is required.
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
  }

  create() {

    const cube_idx_count = 36;
    const cube_vert_count = 24;

    function createCubeIndices(): Uint32Array {
         var idx = 0;
         var cube_idx = new Uint32Array(cube_idx_count); 
        for(var i = 0; i < 6; i++)
        {
            cube_idx[idx++] = 4*i;
            cube_idx[idx++] = (4*i) + 1;
            cube_idx[idx++] = (4*i) + 2;
            cube_idx[idx++] = 4*i;
            cube_idx[idx++] = (4*i) + 2;
            cube_idx[idx++] = (4*i) + 3;
        }
        return cube_idx;
    }
    
    function createCubeNormals(): Float32Array {

        var idx = 0;
        var cube_norm = new Float32Array(cube_vert_count * 4);

        // Back square (cube indices 0-3) -xnorm
        for(var i = 0; i < 4 * 4; i = i + 4)
        {
            cube_norm[i] = -1;
            cube_norm[i + 1] = 0;
            cube_norm[i + 2] = 0;
            cube_norm[i + 3] = 0;
        }

        //left square (cube indices 4-7) +znorm
        for(var i = 3 * 4; i < 8 * 4; i = i + 4)
        {
            cube_norm[i] = 0;
            cube_norm[i + 1] = 0;
            cube_norm[i + 2] = 1;
            cube_norm[i + 3] = 0;
        }

        //right square (cube indices 8-11) -znorm
        for(var i = 8 * 4; i < 12 * 4; i = i + 4)
        {
            cube_norm[i] = 0;
            cube_norm[i + 1] = 0;
            cube_norm[i + 2] = -1;
            cube_norm[i + 3] = 0;
        }

        //bottom square (cube indices 12-15) -ynorm
        for(var i = 12 * 4; i < 16 * 4; i = i + 4)
        {
            cube_norm[i] = 0;
            cube_norm[i + 1] = -1;
            cube_norm[i + 2] = 0;
            cube_norm[i + 3] = 0;
        }

        //top  square (cube indices 16-19) +ynorm
        for(var i = 16 * 4; i < 20 * 4; i = i + 4)
        {
            cube_norm[i] = 0;
            cube_norm[i + 1] = 1;
            cube_norm[i + 2] = 0;
            cube_norm[i + 3] = 0;
        }

        //front square (cube indices 20-24) +xnorm
        for(var i = 20 * 4; i < 24 * 4; i = i + 4)
        {
            cube_norm[i] = 1;
            cube_norm[i + 1] = 0;
            cube_norm[i + 2] = 0;
            cube_norm[i + 3] = 0;
        }
        return cube_norm;
    }
    
    function createCubePositions() : Float32Array {
        return new Float32Array(
        [.5, -.5, .5, 1,
        .5, .5, .5, 1,
        .5, .5, -.5, 1,
        .5, -.5, -.5, 1,
        -.5, -.5, .5, 1,
        -.5, .5, .5, 1,
        .5, .5, .5, 1,
        .5, -.5, .5, 1,
        -.5, -.5, -.5, 1,
        -.5, .5, -.5, 1,
        .5, .5, -.5, 1,
        .5, -.5, -.5, 1,
        .5, -.5, .5, 1,
        -.5, -.5, .5, 1,
        -.5, -.5, -.5, 1,
        .5, -.5, -.5, 1,
        .5, .5, .5, 1,
        -.5, .5, .5, 1,
        -.5, .5, -.5, 1,
        .5, .5, -.5, 1,
        -.5, -.5, -.5, 1,
        -.5, .5, -.5, 1,
        -.5, .5, .5, 1,
        -.5, -.5, .5, 1]);
    }

  this.indices = createCubeIndices();
  this.normals = createCubeNormals();
  this.positions = createCubePositions();

    this.generateIdx();
    this.generatePos();
    this.generateNor();

    this.count = this.indices.length;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);


    console.log(`Created cube`);
  }
 
};

export default Cube;