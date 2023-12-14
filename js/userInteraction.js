let cameraInitial = [0, 0, 3];
let camera = cameraInitial;
let cameraDirectionInitial = [0, 0, -1];
let cameraDirection = cameraDirectionInitial;

cursor = [0,0,0];
let mousedown = false;
let cursorOnMouseDown = [];

canvas1.onmousedown = e =>  { mousedown = true; cursorOnMouseDown = [e.clientX, e.clientY]; };
canvas1.onmouseup = e => { console.log("up"); mousedown = false; cursorOnMouseDown = []; prevCameraDirection = cameraDirection.slice(0); };
canvas1.onmousemove = e => {
    let step = 4;
    if (mousedown) { 
        console.log("mouse is down")
        let offset = [e.clientX - cursorOnMouseDown[0], e.clientY - cursorOnMouseDown[1]]; // -800 to 800
        let clampedOffset = [Math.min(Math.max(offset[0], -800), 800), Math.min(Math.max(offset[1], -800), 800)];
        cameraDirection[0] = prevCameraDirection[0] + (clampedOffset[0] / 800); // -1 to 1
        cameraDirection[1] = prevCameraDirection[1] + (clampedOffset[1] / 800); // -1 to 1
    }
}

// used on wasd
function addStep(stepVector) {
    // NOT USING THIS FUNCTION RIGHT NOW
    return addVectors(camera, stepVector);

    // stepVector is a vector of length 3, with one of the fields being `step` and the rest being 0
    let yAdjustedStepVector = multiplyMatrixVector(rotateY(cameraDirection[1]), stepVector);
    let xyAdjustedStepVector = multiplyMatrixVector(rotateX(cameraDirection[0]), yAdjustedStepVector);
    // console.log(xyAdjustedStepVector)
    return addVectors(camera, xyAdjustedStepVector);
}

document.onkeydown = e => {
    // perform WASD movement to the camera
    let step = .1;
    // w - C = (cx,cy,cz) -> C + (0,0,-step) * R
    if (e.key == 'w') camera = addStep([0, 0, -step]);
    if (e.key == 's') camera = addStep([0, 0, step]);
    if (e.key == 'a') camera = addStep([-step, 0, 0]);
    if (e.key == 'd') camera = addStep([step, 0, 0]);
    
    // y keys 
    if (e.key == 'q') camera = addStep([0, step, 0]);
    if (e.key == 'e') camera = addStep([0, -step, 0]);
}
// on drag
canvas1.ondragover = e => console.log("hi");
