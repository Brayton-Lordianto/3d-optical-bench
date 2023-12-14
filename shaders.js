
// remember to change these values in the shaders as well
let NLIGHTS  = 2;
let NSPHERES = 1;

fetch('./shaders/vertexShader.glsl')
   .then(response => response.text())
   .then((shaderSource) => {
      vertexShader = shaderSource;
   });

// fetch('./shaders/old_fragmentShader.glsl')
fetch('./shaders/fragmentShader.glsl')
   .then(response => response.text())
   .then((shaderSource) => {
      fragmentShader = shaderSource;
   });