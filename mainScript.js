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
    vertexAttribute('aNor', 3, 3);
    return gl;
}

// WAIT 100 MSECS BEFORE STARTING UP


setTimeout(() => {
    driverScript()
}, 100);