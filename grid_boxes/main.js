var scene = new THREE.Scene();
var aspect = window.innerWidth / window.innerHeight;
var camera = new THREE.PerspectiveCamera(60, aspect, 0.1, 10000);
var renderer = new THREE.WebGLRenderer();
var controls = new THREE.TrackballControls(camera);
var ctrls = {
    use_turntable: false
};
var gui = new dat.GUI();
gui.add(ctrls, 'use_turntable');
controls.rotateSpeed = 1.0;
controls.zoomSpeed = 1.2;
controls.panSpeed = 0.8;
controls.noZoom = false;
controls.noPan = false;
controls.staticMoving = true;
controls.dynamicDampingFactor = 0.3;
controls.keys = [65, 83, 68];
scene.fog = new THREE.FogExp2(0x000000, 0.00025);
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

var ball_geo = new THREE.IcosahedronGeometry(0.6, 1);
var cube_geo = new THREE.BoxGeometry(1, 1, 1);
var tetra_geo = new THREE.SphereGeometry(1, 3, 2);
function getWireMat (col) {

    var color = col || 0xFFFF00;
    return new THREE.MeshBasicMaterial({
        color: color,
        opacity: 0.5,
        wireframe: true,
        wireframeLinewidth: 2
    });
}

function getSolidMat (col) {

    var color = col || 0xFFFF00;
    return new THREE.MeshBasicMaterial({
        color: color,
        opacity: 1.0,
        wireframe: false
    });
}

var objects = [];
var mesh_scale = 300;
var grid_size = 10;
var num_boxes = Math.pow(grid_size, 3);
var time_inc = 0;
var i = 0;
function getMesh (n) {

    function getPosition () {
        return new THREE.Vector3(
            (n % grid_size * mesh_scale) - 1250,
            (Math.floor(n * (1 / grid_size)) % grid_size * mesh_scale) - 1250,
            (Math.floor(n * 1 / Math.pow(grid_size, 2)) * -mesh_scale) + 1250
        );
    }
    function getRGB () {
        return {
            x: (n % grid_size) * (1 / grid_size + 0.1),
            y: (Math.floor(n * (1 / grid_size)) % grid_size) * (1 / grid_size + 0.1),
            z: (Math.floor(n * 1 / Math.pow(grid_size, 2))) * (1 / grid_size + 0.1)
        };
    }
    var col = getRGB();
    var geometry = cube_geo;
    var material = getSolidMat();
    material.color.setRGB(col.x, col.y, col.z);
    var mesh = new THREE.Mesh(geometry, material);
    var pos = getPosition();
    mesh.position.set(pos.x, pos.y, pos.z);
    mesh.scale.x = mesh.scale.y = mesh.scale.z = 40;

    function anim (n) {

        var mult = Math.max(Math.sin(this.col.x + this.col.z + n), 0.001);
        this.mesh.scale.x = this.mesh.scale.y = this.mesh.scale.z = mult * 160;
        // this.material.color.setHSL(1 - mult, 1.0, 0.5);
    }
    return {
        mesh: mesh,
        anim: anim,
        n: n,
        col: col,
        material: material
    };
}

for (var i = 0; i < num_boxes; i++) {
    var obj = getMesh(i);
    objects.push(obj);
    scene.add(obj.mesh);
}

camera.position.z = 3200;
camera.position.y = 2000;
function onKeyUp (evt) {
    console.log(evt.keyCode);
}

function renderFrame () {

    requestAnimationFrame(renderFrame);
    if (ctrls.use_turntable === true) {
        camera.position.z -= (camera.position.z - 3800 * Math.sin(time_inc * 0.1)) * 0.03;
        camera.position.x -= (camera.position.x - 3800 * Math.cos(time_inc * 0.1)) * 0.03;
        camera.lookAt(scene.position);
    } else {
        controls.update();
    }
    time_inc += 0.08;
    for (var _i = 0, _len = objects.length; _i < _len; _i++) {
        obj = objects[_i];
        obj.anim(time_inc);
    }
    renderer.clear();
    renderer.render(scene, camera);
}

renderFrame();
// document.addEventListener('keyup', onKeyUp, false);



