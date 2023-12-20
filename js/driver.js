function driverScript() {
    gl = start_gl(canvas1, meshData, vertexSize, vertexShader, fragmentShader);
    // var opticalComponentLocations = 
    let MAX_LINES_SIZE = 10; 

    // INITIALIZE POSITION, VELOCITY AND PHONG PARAMETERS OF EACH SPHERE
    let V = [],
        S = [],
        ambient = [],
        diffuse = [],
        specular = [];
 
    // FIND LOCATIONS IN GPU PROGRAM OF UNIFORM VARIABLES
    let uFL = gl.getUniformLocation(gl.program, "uFL");
    let uTime = gl.getUniformLocation(gl.program, "uTime");
    let uCursor = gl.getUniformLocation(gl.program, "uCursor");
    let uLC = gl.getUniformLocation(gl.program, "uLC");
    let uLD = gl.getUniformLocation(gl.program, "uLD");
    let uSphere = gl.getUniformLocation(gl.program, "uSphere");
    let uAmbient = gl.getUniformLocation(gl.program, "uAmbient");
    let uDiffuse = gl.getUniformLocation(gl.program, "uDiffuse");
    let uSpecular = gl.getUniformLocation(gl.program, "uSpecular");
    
    let uCamera = gl.getUniformLocation(gl.program, "uCamera");
    let uCameraDirection = gl.getUniformLocation(gl.program, "uCameraDirection");
    let uColor = gl.getUniformLocation(gl.program, "uColor");
    let uMatrix    = gl.getUniformLocation(gl.program, "uMatrix");
    let uInvMatrix = gl.getUniformLocation(gl.program, "uInvMatrix");

    let uLineSize = gl.getUniformLocation(gl.program, "lines.size");
    initializeLines(gl);
    initializeOpticalComponents(gl);


    // ANIMATE AND RENDER EACH ANIMATION FRAME

    // SET ALL UNIFORM VARIABLES
    addLine([-3,0,-5], [0,3,-5], [1,0,0], gl, structs);
    addLine([0,3,-5], [0,0,-5], [1,0,0], gl, structs);
    addLine([0,0,-5], [3,0,-5], [1,0,0], gl, structs);
    
    let startTime = Date.now() / 1000;
    setInterval(() => {
        gl.uniform3fv(uCamera, camera);
        gl.uniform3fv(uCameraDirection, cameraDirection);
    });
    setInterval(() => {

        gl.uniform1f(uTime, Date.now() / 1000 - startTime);
        gl.uniform3fv(uCursor, cursor);
        gl.uniform1f(uFL, 3);

        // this is the light sources intensity and their directions
        // LC is the color intensity of the light source
        let r3 = Math.sqrt(1 / 3);
        gl.uniform3fv(uLC, [1, 1, 1, .3, .2, .1]);
        gl.uniform3fv(uLD, [r3, r3, r3, -r3, -r3, -r3])
        //   gl.uniform3fv(uLC, [1,1,1,      .3,.2,.1]);
        //   gl.uniform3fv(uLD, [r3,r3,r3, -r3,-r3,-r3]);

        gl.uniform4fv(uSphere, S);
        gl.uniform3fv(uAmbient, ambient);
        gl.uniform3fv(uDiffuse, diffuse);
        gl.uniform4fv(uSpecular, specular);

        gl.uniform1i(uLineSize, MAX_LINES_SIZE);

        // RENDER THE FRAME
        let m = mIdentity();
        
        
        
        
        for (let n = 0; n < meshData.length; n++) {
            if (n == 1) { m = mScale(.16, .16, .16, m); }
            else { m = mScale(1, 1, 1, m); }
            gl.uniform3fv      (uColor    , meshData[n].color);
            gl.uniformMatrix4fv(uMatrix   , false, m);
            gl.uniformMatrix4fv(uInvMatrix, false, mInverse(m));

            let mesh = meshData[n].mesh;
            gl.bufferData(gl.ARRAY_BUFFER, mesh, gl.STATIC_DRAW);
            gl.drawArrays(meshData[n].type ? gl.TRIANGLE_STRIP : gl.TRIANGLES, 0, mesh.length / vertexSize);
        }
    }, 30);
}
