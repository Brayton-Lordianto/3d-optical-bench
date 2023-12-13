// INITIALIZE GPU PROGRAM

let start_gl = (canvas, meshData, vertexSize, vertexShader, fragmentShader) => {
    let gl = canvas.getContext("webgl");
    let program = gl.createProgram();
    gl.program = program;
    let addshader = (type, src) => {
        let shader = gl.createShader(type);
        gl.shaderSource(shader, src);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS))
            throw "Cannot compile shader:\n\n" + gl.getShaderInfoLog(shader);
        gl.attachShader(program, shader);
    };
    addshader(gl.VERTEX_SHADER, vertexShader);
    addshader(gl.FRAGMENT_SHADER, fragmentShader);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS))
        throw "Could not link the shader program!";
    gl.useProgram(program);
    gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);
    let vertexAttribute = (name, size, position) => {
        let attr = gl.getAttribLocation(program, name);
        gl.enableVertexAttribArray(attr);
        gl.vertexAttribPointer(attr, size, gl.FLOAT, false, vertexSize * 4, position * 4);
    }
    vertexAttribute('aPos', 3, 0);
    return gl;
}

// TRIANGLE DATA (IN THIS CASE, ONE SQUARE)
let sphere = (nu, nv) => createMesh(nu, nv, (u,v) => {
    let theta = 2 * Math.PI * u;
    let phi = Math.PI * (v - .5);
    let x = Math.cos(phi) * Math.cos(theta),
        y = Math.cos(phi) * Math.sin(theta),
        z = Math.sin(phi);
    return [ x,y,z, x,y,z ];
 });


let createMesh = (nu, nv, p) => {
let mesh = [];
for (let j = nv ; j > 0 ; j--) {
    for (let i = 0 ; i <= nu ; i++)
        mesh.push(p(i/nu,j/nv), p(i/nu,j/nv-1/nv));
    mesh.push(p(1,j/nv-1/nv), p(0,j/nv-1/nv));
}
return mesh.flat();
}


let meshData = [
// {
//     type: 1, color: [1.,.1,.1],
//     mesh: new Float32Array([-1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0])
// }, 
{ type: 1, color: [1.,.1,.1], mesh: new Float32Array(sphere(20, 10)) },
];

// SET NUMBER OF LIGHTS AND NUMBER OF SPHERES IN THE SCENE

// VERTEX AND FRAGMENT SHADERS

let vertexSize = 3;


// WAIT 100 MSECS BEFORE STARTING UP


setTimeout(() => {
    driverScript()
}, 100);