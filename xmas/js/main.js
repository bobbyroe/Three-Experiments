
// scene setup stuff
var scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0xe0e0e0, 0.0025);
var camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 10000);
camera.position.set(-1, 18, 1);
camera.lookAt(scene.position);
var renderer = new THREE.WebGLRenderer({antialias: true});
renderer.shadowMapEnabled = true;
renderer.shadowMapSoft = false;
renderer.setClearColor(0xe0e0e0);

renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Geometry and Materials
var wire_mat = new THREE.MeshBasicMaterial({
    wireframe: true,
    opacity: 1.0,
    transparent: true,
    wireframeLinewidth: 2,
    vertexColors: THREE.VertexColors,
    color: 0x202020
});


// Ground plane
var plane_geo = new THREE.PlaneBufferGeometry(100, 100, 100);
var basic_mat = new THREE.MeshBasicMaterial({
    color: 0xe0e0e0
});
var plane = new THREE.Mesh(plane_geo, basic_mat);
plane.rotation.x = -Math.PI * 0.5;
plane.receiveShadow = true;
scene.add(plane);

// "trunk" geo
var trunk_geo = new THREE.CubeGeometry(2, 1, 2);
var trunk_verts = [
    new THREE.Vector3(1, 0.25, 0.6),
    new THREE.Vector3(1, 0.25, -0.6),
    new THREE.Vector3(1, -0.25, 0.6),
    new THREE.Vector3(1, -0.25, -0.6),
    new THREE.Vector3(-1, 0.25, -1),
    new THREE.Vector3(-1, 0.25, 1),
    new THREE.Vector3(-1, -0.25, -1),
    new THREE.Vector3(-1, -0.25, 1)
];
trunk_geo.vertices = trunk_verts;
trunk_geo.computeBoundingSphere();
trunk_geo.verticesNeedUpdate = true;

// duck!
// var loader = new THREE.OBJLoader();
// var duck_geo, duck;
// var duck_mat = new THREE.MeshBasicMaterial({
//     color: 0xFFFF00
// });
// function addDuck (obj) {
//     duck_geo = obj.children[0].geometry;
//     duck = new THREE.Mesh(duck_geo, duck_mat);
//     scene.add(duck);
// }

var trunk_mat = new THREE.MeshBasicMaterial({ color: 0x202020 });
var trunk = new THREE.Mesh(trunk_geo, trunk_mat);
trunk.position.set(-5, 1, 5);
trunk.castShadow = true;
trunk.rotation.y = degToRad(45);
scene.add(trunk);

// Lights 
var sunlight = new THREE.DirectionalLight(0xe0e0e0, 0.9);
sunlight.position.set(20, 50, 0);
sunlight.castShadow = true;
sunlight.target.position.set(0, 0, 0);
sunlight.shadowCameraNear = 10;
sunlight.shadowCameraFar = 70;
sunlight.shadowCameraLeft = -30;
sunlight.shadowCameraRight = 30;
sunlight.shadowCameraTop = 30;
sunlight.shadowCameraBottom = -30;
sunlight.shadowMapWidth = 2048;
sunlight.shadowMapHeight = 2048;
scene.add(sunlight);

var sunLighthelper = new THREE.DirectionalLightHelper(sunlight, 2, 1);

var bouncelight = new THREE.DirectionalLight(0xddffff, 0.2);
bouncelight.position.set(-3, -3, 3);
bouncelight.target.position.set(0, 0, 0);
scene.add(bouncelight);
var bounceLighthelper = new THREE.DirectionalLightHelper(bouncelight, 4, 4);

var rimlight = new THREE.DirectionalLight(0xddffff, 2.0);
rimlight.position.set(0, 0.5, -1);

var quad_tree = new Node(0, 0, window.innerWidth, window.innerHeight);

// Objects in scene
var ball_radius = 0.5;
var ball_geo = new THREE.IcosahedronGeometry(ball_radius, 3);
var next_id = 0;

function getBallMat (with_color) {

    var col = new THREE.Color();

    if (with_color != null) {
        col.setRGB(with_color.r, with_color.g, with_color.b);
    } else {
        col.setHSL( 0.33 + (Math.random() * 0.2 - 0.1), 1, 0.5  + (Math.random() * 0.5 - 0.25));
    }
    return new THREE.MeshPhongMaterial({
        color: col,
        specular: 0xa0a0a0,
        shininess: 10, // Math.random() * 10,
        shading: THREE.SmoothShading // THREE.FlatShading
    });
}

var friction = 0.95;
var origin = new THREE.Vector3(0, 1, 0);
function getBall () {
    
    var num = getIncrement();
    var has_layout = layout[num] != null;
    var color = has_layout ? layout[num].color : null;
    var ball = new THREE.Mesh(ball_geo, getBallMat(color));
    
    var rand_scale = Math.random() * 0.6 + 0.5;
    var scale = has_layout ? layout[num].scale : rand_scale;
    ball.scale.set(scale, scale, scale);

    var pos = has_layout ? layout[num].position : { x: 0, y: rand_scale, z: 0 };
    ball.position.set(pos.x, rand_scale, pos.z);

    var vel_mag = 0.05;
    ball.velocity = has_layout === false ? new THREE.Vector3(
        Math.random() * vel_mag - vel_mag * 0.5,
        0,
        Math.random() * vel_mag - vel_mag * 0.5
    ) : new THREE.Vector3(0, 0, 0);

    
    ball.castShadow = true;

    function update () { 
        ball.position.addVectors(ball.position, ball.velocity);
        ball.velocity.multiplyScalar(friction);
    }

    function nudge (wants_toward_center) {
        vel_mag = 0.5;
        var impulse = new THREE.Vector3(
            Math.random() * vel_mag - vel_mag * 0.5,
            0,
            Math.random() * vel_mag - vel_mag * 0.5
        );
        if (wants_toward_center === true) {
            impulse.subVectors(origin, ball.position)
                .normalize()
                .multiplyScalar(0.1);
        }
        ball.velocity = impulse;
    }

    ball._props = {
        id: num,
        update: update,
        highlight: function() {},
        nudge: nudge,
        scale: rand_scale
    };
        
    return ball;
}

var objs = [];
function addBalls (num) {

    var num_balls = num != null ? num : 32;
    var ball;
    for (var b = 0; b < num_balls; b++) {
        ball = getBall(b);

        scene.add(ball);
        quad_tree.add(ball);
        objs.push(ball);
    }
}

// Render loop
var counter = 0;
var val = 0.01;
var hot_balls = [];
var repel_strength = 0.0005;
function renderFrame () {
    requestAnimationFrame(renderFrame);
    counter += val;

    quad_tree.clear();
    var b;
    for (var i = 0, len = objs.length; i < len; i++) {
        b = objs[i];
         // update
        b._props.update();
        quad_tree.add(b);
    }

    var direction = new THREE.Vector3(0, 0, 0);
    for (var _j = 0, _len = objs.length; _j < _len; _j++) {
        b = objs[_j];
        hot_balls = quad_tree.getNearbyObjs(b);
        for (var _k = 0, _len1 = hot_balls.length; _k < _len1; _k++) {
            var hot_ball = hot_balls[_k];
            if (hot_ball.id !== b.id) {

                // get distance
                var dist = b.position.distanceTo(hot_ball.position);

                // is distance < radius?
                if (dist < ball_radius * 2) {

                    // get vector
                    direction.subVectors(b.position, hot_ball.position)
                        .normalize()
                        .multiplyScalar(repel_strength);

                    // set vel based on dist
                    b.velocity.add(direction);

                    // override the "y" values
                    b.velocity.y = 0;
                    b.position.y = b._props.scale;
                }
            }
        }
    }

    renderer.render(scene, camera);
}

// START!
function preloadAssets () {
  // loader.load('duck.obj', function(obj) {
    // addDuck();
    addBalls(layout.length);
    renderFrame();
  // });
}
preloadAssets();


// keyboard listener
function onKey (evt) {

    var layout;
    var SPACE = 32;
    if (evt.code === "Space") {

        if (evt.shiftKey === false) {
            addBalls(12);
        } else {
            layout = JSON.stringify(getLayoutData());
            console.log(layout);
        }
    }
    if (evt.code === "KeyD") {
        console.log("delete:", selected_obj);
    }
}
document.addEventListener('keypress', onKey, false);

function getLayoutData () {
    var arr = [];
    var obj;
    for (var i = 0, len = objs.length; i < len; i++) {
        obj = {
            position: objs[i].position,
            id: objs[i]._props.id,
            scale: objs[i]._props.scale,
            color: objs[i].material.color
        };
        arr.push(obj);
    }
    return arr;
}

function getIncrement () {
    var n = next_id;
    next_id++;
    return n;
}

function degToRad(deg) {
    return deg * Math.PI / 180;
}

var selected_obj;
var dragControls = new THREE.DragControls( objs, camera, renderer.domElement );
dragControls.addEventListener( 'dragstart', function ( evt ) { 
    console.log(evt.object.position); 
} );
dragControls.addEventListener( 'dragend', function ( evt ) {
    console.log(evt.object.position);
    evt.object.position.y = 1.0; // reset y pos to 1
    selected_obj = evt.object;
} );





