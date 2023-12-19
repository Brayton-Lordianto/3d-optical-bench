function driverScript() {
    gl = start_gl(canvas1, meshData, vertexSize, vertexShader, fragmentShader);
    var structs = { uniform: { lines: [] } }
    var lineLocations = ["point1", "point2", "color"];
    let LINES_SIZE = 10; 

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
    for (var i = 0; i < LINES_SIZE; i++) {
        var locations = {} 
        for (var j = 0; j < lineLocations.length; j++) {
            var field = lineLocations[j];
            var locationName = `lines.at[${i}].${field}`;
            console.log(locationName)
            locations[field] = gl.getUniformLocation(gl.program, locationName);
        }
        structs.uniform.lines.push(locations);
    }

    // ANIMATE AND RENDER EACH ANIMATION FRAME


    let startTime = Date.now() / 1000;
    setInterval(() => {
        gl.uniform3fv(uCamera, camera);
        gl.uniform3fv(uCameraDirection, cameraDirection);
    });
    setInterval(() => {

        // SET ALL UNIFORM VARIABLES
        // structs.uniform.lines[0].point1 = [-3,0,-5];
        // structs.uniform.lines[0].point2 = [3,0,-5]; 
        // structs.uniform.lines[0].color = [1,0,0];
        // console.log(structs.uniform.lines[0]);
        gl.uniform3fv(structs.uniform.lines[0].point1, [-3,0,-5]);
        gl.uniform3fv(structs.uniform.lines[0].point2, [0,3,-5]);
        gl.uniform3fv(structs.uniform.lines[0].color, [1,0,0]);
        

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

        gl.uniform1i(uLineSize, LINES_SIZE);

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