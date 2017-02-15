/*
    A THREE.js experiment 2014 by http://bobbyroe.com
 */
(function() {
    "use strict"

    const HALF_PI = Math.PI * 0.5;
    let counter = 0;
    let scene = new THREE.Scene();
    let camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 10000);
    camera.position.z = 250;

    let controls = new THREE.TrackballControls(camera);
    controls.rotateSpeed = 1.0;
    controls.zoomSpeed = 1.2;
    controls.panSpeed = 0.8;
    controls.noZoom = false;
    controls.noPan = false;
    controls.staticMoving = true;
    controls.dynamicDampingFactor = 0.3;
    controls.keys = [65, 83, 68];
    let renderer = new THREE.WebGLRenderer();
    renderer.setSize(window.innerWidth, window.innerHeight);

    const log = console.log.bind(console);

    let info_panel = document.querySelector('#info');
    let panel = renderer.domElement;
    panel.classList.add('panel');
    document.body.insertBefore(panel, info_panel);

    function getWireMat (col = 0x660000) {
        return new THREE.MeshBasicMaterial({
            color: col,
            opacity: 1,
            wireframe: true,
            wireframeLinewidth: 2
        });
    }

    function getLineMat (col) {
        return new THREE.LineBasicMaterial({
            color: col,
            linewidth: 1
        });
    }

    // get ready to normalize the data
    let max_pos = {
        x: 0,
        y: 0
    };

    let min_pos = {
        x: 1000,
        y: 1000
    };

    // normalize
    world.forEach( (land_mass) => {
        land_mass.forEach( (vertex) => {
            min_pos = {
                x: Math.min(min_pos.x, vertex.x),
                y: Math.min(min_pos.y, vertex.y)
            };
            max_pos = {
                x: Math.max(max_pos.x, vertex.x),
                y: Math.max(max_pos.y, vertex.y)
            };
        });
    });

    // map to a sphere
    world.forEach( (land_mass) => {
        land_mass.forEach( (vertex) => {
            let temp_y = vertex.y;
            vertex.x = -1 * (vertex.x / max_pos.x) + 1;
            vertex.y = -0.92 * (vertex.y / max_pos.y) + 0.98;
        });
    });

    let radius = 100;
    world.forEach( (land_mass) => {
        land_mass.forEach( (vertex) => {
            let x0 = 0;
            let y0 = 0;
            let z0 = 0;
            let u = vertex.x;
            let v = vertex.y;
            let theta = 2 * Math.PI * u;
            let phi = Math.acos(2 * v - 1);
            vertex.x = x0 + (radius * Math.sin(phi) * Math.cos(theta));
            vertex.y = y0 + (radius * Math.cos(phi));
            vertex.z = z0 + (radius * Math.sin(phi) * Math.sin(theta));
        });
    });

    // dark background
    let sphere_geo = new THREE.IcosahedronGeometry(99, 3);
    let sphere_mat = new THREE.MeshBasicMaterial({
        color: 0x101010,
        wireframe: false,
        transparent: true,
        opacity: 0.8
    });
    let sphere_mats_array = [sphere_mat, getWireMat()];
    let sphere = new THREE.SceneUtils.createMultiMaterialObject(sphere_geo, sphere_mats_array);
    scene.add(sphere);
    let colors = [0xFF4400, 0x44FF00, 0x22FF00];

    function drawWorld () {
        world.forEach( (land_mass, i) => {
            let random_color = i < 3 ? colors[i] : Math.random() * 0xFFFFFF;
            let line_geo = new THREE.Geometry();
            line_geo.vertices = land_mass;
            let line = new THREE.Line(line_geo, getLineMat(random_color));
            sphere.add(line);
        });
    }

    drawWorld();

    function onKeyUp (evt) {
        evt.preventDefault();
        if (evt.keyCode === 32) {
            log(min_pos, max_pos);
        }
    }

    function renderFrame () {
        requestAnimationFrame(renderFrame);
        controls.update();
        counter += 0.01;
        sphere.rotation.y = counter;
        renderer.render(scene, camera);
    }

    renderFrame();
    function showInfoPanel () {
        panel.classList.add('scooched_right');
        info_panel.classList.add('open');
    }

    function hideInfoPanel () {
        panel.classList.remove('scooched_right');
        info_panel.classList.remove('open');
    }

    function toggleInfoPanel () {
        if (info_panel.classList.contains('open')) {
            hideInfoPanel();
        } else {
            showInfoPanel();
        }
    }

    function clicked (evt) {
        if (evt.target.id === 'nub') {
            toggleInfoPanel();
        }
        if (evt.target.id === '') {
            hideInfoPanel();
        }
    }

    document.addEventListener('click', clicked);
    document.addEventListener('keyup', onKeyUp, false);
})();
