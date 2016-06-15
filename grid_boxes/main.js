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

var cube_geo = new THREE.BoxGeometry(1, 1, 1);

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
var wbl_sz = 100;
var time_inc = 0;
var i = 0;
function getMesh (n) {

    function getPosition () {
        var wbl = {
            x: Math.random() * wbl_sz - (wbl_sz * 0.5),
            y: Math.random() * wbl_sz - (wbl_sz * 0.5),
            z: Math.random() * wbl_sz - (wbl_sz * 0.5)
        };
        var pos = {
            x: (n % grid_size * mesh_scale) - 1250,
            y: (Math.floor(n * (1 / grid_size)) % grid_size * mesh_scale) - 1250,
            z: (Math.floor(n * 1 / Math.pow(grid_size, 2)) * -mesh_scale) + 1250
        };

        return { x: pos.x + wbl.x, y: pos.y + wbl.y, z: pos.z + wbl.z };
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

        var mult = Math.max(Math.sin(this.col.x + this.col.z + n), 0.0001);
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


camera.position.x = -1851;
camera.position.y = -2304;
camera.position.z =  2251;

function renderFrame () {

    requestAnimationFrame(renderFrame);
    if (ctrls.use_turntable === true) {
        camera.position.z -= (camera.position.z - 3800 * Math.sin(time_inc * 0.1)) * 0.03;
        camera.position.x -= (camera.position.x - 3800 * Math.cos(time_inc * 0.1)) * 0.03;
        camera.lookAt(scene.position);
    } else {
        controls.update();
    }
    time_inc += 0.03;
    for (var _i = 0, _len = objects.length; _i < _len; _i++) {
        obj = objects[_i];
        obj.anim(time_inc);
    }
    renderer.clear();
    renderer.render(scene, camera);
}

renderFrame();
