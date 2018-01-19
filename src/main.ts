import {vec3, vec4} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import {fromValues} from 'node_modules/gl-matrix/src/gl-matrix/mat4';
import Drawable from './rendering/gl/Drawable';

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let time = 0;
let currShader: ShaderProgram;
let currGeometry: Drawable;
let numTesselations = 6;

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: numTesselations,
  'Load Scene': loadScene, // A function pointer, essentially
  color: [128, 128, 128, 1],
  shader: 'lambert',
  geometry: 'cube',
};


function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
};



function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.addColor(controls, 'color');
  gui.add(controls, 'Load Scene');
  gui.add(controls,'shader', ['lambert', 'normal', 'melty blob', 'drippy', 'moon']);
  gui.add(controls, 'geometry',['cube', 'icosphere', 'square'] );

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const normalShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/normal-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/normal-frag.glsl')),
  ])


  const meltingShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/melting-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/melting-frag.glsl')),
  ])

  const meltingShader2 = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/melting2-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/melting2-frag.glsl')),
  ])

  const moonShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/moon-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/moon-frag.glsl')),
  ])

  const moonShader2 = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/moon2-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/moon2-frag.glsl')),
  ])


  function changeShader(){
  if(controls.shader == 'lambert')
  {
    currShader = lambert;
  } else if (controls.shader == 'normal') {
    currShader = normalShader;
  } else if (controls.shader == 'melty blob') {
    currShader = meltingShader;
  } else if (controls.shader == 'drippy') {
    currShader = meltingShader2;
  } else if (controls.shader == 'moon') {
    currShader = moonShader;
  }
}

function changeGeometry(){
if(controls.geometry == 'cube')
{
  currGeometry = cube;
} else if (controls.geometry == 'icosphere') {
  if(controls.tesselations != numTesselations)
  {
    icosphere.destroy();
    icosphere.destroy();
    icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
    icosphere.create();
    numTesselations = controls.tesselations;
  }
  currGeometry = icosphere;
} else if (controls.geometry == 'square') {
  currGeometry = square;
}
}


  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    var eye = vec4.fromValues(camera.controls.eye[0], camera.controls.eye[1], camera.controls.eye[2], 1);
    var vec4color = vec4.fromValues(controls.color[0] / 255, controls.color[1] / 255, controls.color[2] / 255, 1);
  //  changeShader();
    //changeGeometry();

  /*  renderer.render(camera, currShader, [
       currGeometry
    ], vec4color, time, eye);*/

    renderer.render(camera, moonShader2, [
      icosphere
   ], vec4color, time, eye);

    stats.end();
    time++;

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
};

main();
