
/**
*
* SHADOWS
*
*/

// scene setup stuff

var scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0xe0e0e0, 0.0025);
var camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 10000);
camera.position.set(1, 4, 14);
camera.lookAt(scene.position);
var renderer = new THREE.WebGLRenderer({antialias: true});
renderer.shadowMapEnabled = true;
renderer.shadowMapSoft = false;
renderer.setClearColor(0xe0e0e0);

renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Misc. 

var log = console.log.bind(console);

// camera controls

var controls = new THREE.TrackballControls(camera);
controls.rotateSpeed = 1.0;
controls.zoomSpeed = 1.2;
controls.panSpeed = 0.8;
controls.noZoom = false;
controls.noPan = false;
controls.staticMoving = true;
controls.dynamicDampingFactor = 0.3;
controls.keys = [65, 83, 68];

// Geometry and Materials

var wire_mat = new THREE.MeshBasicMaterial({
    wireframe: true,
    opacity: 1.0,
    transparent: true,
    wireframeLinewidth: 2,
    vertexColors: THREE.VertexColors
});


// Ground plane

var plane_geo = new THREE.PlaneGeometry(100, 100, 100);
var basic_mat = new THREE.MeshBasicMaterial({
    color: 0xe0e0e0
});
var plane = new THREE.Mesh(plane_geo, basic_mat);
plane.rotation.x = -Math.PI * 0.5;
plane.receiveShadow = true;
scene.add(plane);

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
// sunlight.shadowCameraVisible = true;
scene.add(sunlight);

var sunLighthelper = new THREE.DirectionalLightHelper(sunlight, 2, 1);

var bouncelight = new THREE.DirectionalLight(0xddffff, 0.2);
bouncelight.position.set(-3, -3, 3);
bouncelight.target.position.set(0, 0, 0);
scene.add(bouncelight);
var bounceLighthelper = new THREE.DirectionalLightHelper(bouncelight, 4, 4);

var rimlight = new THREE.DirectionalLight(0xddffff, 2.0);
rimlight.position.set(0, 0.5, -1);

// Quad tree
var Node = (function() {
    function Node (x, y, width, height, level) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.level = (level != null) ? level : 0;
        this.objs = [];
        this.max_objs = 10;
        this.max_levels = 6;
        this.sub_nodes = [];
    }

    Node.prototype.add = function(obj) {
        var index;
        if (this.sub_nodes.length !== 0) {
            index = this.getIndex(obj);
            if (index !== -1) {
                this.sub_nodes[index].add(obj);
                return;
            }
        }
        this.objs.push(obj);
        if (this.objs.length > this.max_objs && this.level < this.max_levels) {
            if (this.sub_nodes.length === 0) { this.split(); }
            var _ref = this.objs;
            for (var _i = 0, _len = _ref.length; _i < _len; _i++) {
                var o = _ref[_i];
                index = this.getIndex(o);
                if (index !== -1) {
                    this.sub_nodes[index].add(o);
                    this.remove(o);
                }
            }
        }
    };

    Node.prototype.getIndex = function (obj) {
        var index = -1;
        var midpoint = {
            x: this.x + this.width * 0.5,
            y: this.y + this.height * 0.5
        };
        var pos = obj.mesh.position;

        if (pos.x < midpoint.x && pos.z < midpoint.y) { index = 0; }
        if (pos.x > midpoint.x && pos.z < midpoint.y) { index = 1; }
        if (pos.x > midpoint.x && pos.z > midpoint.y) { index = 2; }
        if (pos.x < midpoint.x && pos.z > midpoint.y) { index = 3; }
        return index;
    };

    Node.prototype.getNearbyObjs = function (obj) {

        var objs = this.objs.slice(0);
        var index = this.getIndex(obj);
        if (index !== -1 && this.sub_nodes.length !== 0) {
            return this.sub_nodes[index].getNearbyObjs(obj);
        }
        return objs;
    };

    Node.prototype.remove = function (obj) {
        var index = this.objs.indexOf(obj);
        if (index !== -1) {
            this.objs = this.objs.slice(0, index);
        }
    };

    Node.prototype.split = function () {
        var half_width = this.width * 0.5;
        var half_height = this.height * 0.5;
        var level = this.level + 1;
        var x = this.x;
        var y = this.y;
        this.sub_nodes[0] = new Node(x, y, half_width, half_height, level);
        this.sub_nodes[1] = new Node(x + half_width, y, half_width, half_height, level);
        this.sub_nodes[2] = new Node(x + half_width, y + half_height, half_width, half_height, level);
        this.sub_nodes[3] = new Node(x, y + half_height, half_width, half_height, level);
    };

    Node.prototype.clear = function () {
        this.objs = [];
        if (this.sub_nodes.length !== 0) {
            var _ref = this.sub_nodes;
            for (var _i = 0, _len = _ref.length; _i < _len; _i++) {
                var node = _ref[_i];
                node.clear();
            }
        }
        this.sub_nodes = [];
    };

    return Node;

})();

var quad_tree = new Node(0, 0, 200, 200);

// Objects in scene

var ball_radius = 1;
var ball_geo = new THREE.IcosahedronGeometry(ball_radius, 1);

function getBallMat () {
    return new THREE.MeshPhongMaterial({
        color: 0x0099FF,
        specular: 0xa0a0a0,
        shininess: 10,
        shading: THREE.FlatShading
    });
}

var friction = 0.95;
var origin = new THREE.Vector3(0, 1, 0);

function getObj (num) {
    // if (num == null) num = getUniqueId();
    var mat = getBallMat();
    var ball = new THREE.Mesh(ball_geo, mat);
    var vel_mag = 0.05;
    ball.position.set(0, 1, 0);
    ball.velocity = new THREE.Vector3(
        Math.random() * vel_mag - vel_mag * 0.5,
        0,
        Math.random() * vel_mag - vel_mag * 0.5
    );
    ball.castShadow = true;

    function update () { 
        ball.position.addVectors(ball.position, ball.velocity);
        ball.velocity.multiplyScalar(friction);
    }

    function highlight (col) {
        ball.material.color.setHex(col);
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
    
    return {
        id: num,
        mesh: ball,
        update: update,
        highlight: highlight,
        nudge: nudge
    };
}
var b = 0;
var num_balls = 32;
var objs = [];
var ball;
while (b < num_balls) {
    ball = getObj(b);

    // side effect

    scene.add(ball.mesh);
    quad_tree.add(ball);
    objs.push(ball);
    b += 1;
}

// Render loop

var counter = 0;
var val = 0.01;
var hot_balls = [];
var repel_strength = 0.001;
// var max_grid_bound = 15;
function renderFrame () {
    requestAnimationFrame(renderFrame);
    controls.update();
    counter += val;

    quad_tree.clear();
    var b;
    for (var i = 0, len = objs.length; i < len; i++) {
        b = objs[i];
         // update
        b.update();
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

                var dist = b.mesh.position.distanceTo(hot_ball.mesh.position);

                // is distance < radius?

                if (dist < ball_radius * 2) {

                    // get vector

                    direction.subVectors(b.mesh.position, hot_ball.mesh.position)
                        .normalize()
                        .multiplyScalar(repel_strength);

                    // set vel based on dist

                    b.mesh.velocity.add(direction);

                    // if (b.mesh.position.x > max_grid_bound || b.mesh.position.x < -max_grid_bound) {
                    //     b.mesh.velocity.x *= -1;
                    // }
                    // if (b.mesh.position.z > max_grid_bound || b.mesh.position.z < -max_grid_bound) {
                    //     b.mesh.velocity.z *= -1;
                    // }
                }
            }
        }
        
    }

    renderer.render(scene, camera);
}

function initGraph () {
    var random_index = Math.floor(Math.random() * objs.length);
    var hot_ball = objs[random_index];
    hot_ball.highlight(0xFF0000);
    setTimeout(function () { highlightNeighbors(hot_ball) }, 2000);
}

function highlightNeighbors (ball) {
    quad_tree.getNearbyObjs(ball).forEach( function (b) {
        if (b.id !== ball.id) {

            // get distance

            var dist = ball.mesh.position.distanceTo(b.mesh.position);

            // is distance < radius * 5?
    
            if (dist < ball_radius * 5) {

                b.highlight(0xFFDD00);
            } else {
                b.highlight(0xFF7700);
            }
        }
        
    });

}

//

// line

let line_mat = new THREE.LineBasicMaterial({ 
    vertexColors: THREE.VertexColors,
    linewidth: 1
});
let cols = [new THREE.Color(1, 0, 0), new THREE.Color(1, 0, 0)];

let line_geo = new THREE.Geometry();
line_geo.vertices = [new THREE.Vector3(-15, 1, -15), new THREE.Vector3(15, 1, -15)];
line_geo.colors = cols;
scene.add(new THREE.Line(line_geo, line_mat, 1));

let line_geo2 = new THREE.Geometry();
line_geo2.vertices = [new THREE.Vector3(-15, 1, -15), new THREE.Vector3(-15, 1, 15)];
line_geo2.colors = cols;
scene.add(new THREE.Line(line_geo2, line_mat, 1));
// go!

renderFrame();
setTimeout(initGraph, 2000);

// keyboard listener

function onKey (evt) {
    repel_strength = 0.05;
    var toward_center = evt.shiftKey;
    if (evt.keyCode === 32) {

        // SPACE

        for (var _i = 0, _len = objs.length; _i < _len; _i++) {
            objs[_i].nudge(toward_center);
        }
    }
}
document.addEventListener('keypress', onKey, false);


