(function() {

    // scene set-up
    var scene = new THREE.Scene();
    var camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.z = 40;
    camera.lookAt(scene.position);
    var controls = new THREE.TrackballControls(camera);
    controls.rotateSpeed = 1.0;
    controls.zoomSpeed = 1.2;
    controls.panSpeed = 0.8;
    controls.noZoom = false;
    controls.noPan = false;
    controls.staticMoving = true;
    controls.dynamicDampingFactor = 0.3;
    controls.keys = [65, 83, 68];
    controls.enabled = false;
    // window.ctrls = controls;
    var camera_uses_path = true;
    var is_paused = false;
    var ctrls = {
        flat_shading: false
    };
    var renderer = new THREE.WebGLRenderer({antialias: true});
    renderer.setSize(window.innerWidth, window.innerHeight);
    var info_panel = document.querySelector('#info');
    var panel = renderer.domElement;
    panel.classList.add('panel');
    document.body.insertBefore(panel, info_panel);


    // misc
    var log = console.log.bind(console);
    var counter = 0;
    var mouse_pos = new THREE.Vector3();
    var mouse = new THREE.Vector2();

    var is_zapping = false;
    var win_half_width = window.innerWidth * 0.5;
    var win_half_height = window.innerHeight * 0.5;
    function degToRad(deg) {
        return deg * Math.PI / 180;
    }
    
    // construct tunnel track
    var points = [];
    var p = 0;
    var num_points = path_points.length;
    while (p < num_points) {
        points.push(new THREE.Vector3(path_points[p], path_points[p + 1], path_points[p + 2]));
        p += 3;
    }
    var spline = new THREE.SplineCurve3(points);
    var spline_length = spline.getLength();
    var extrudeSettings = {
        amount: 20,
        bevelEnabled: false,
        bevelSegments: 2,
        steps: 15,
        extrudePath: spline
    };
    var line_mat = new THREE.LineBasicMaterial({
        color: 0xff0000,
        opacity: 1,
        linewidth: 1
    });
    var line_geo = new THREE.Geometry();
    line_geo.vertices = spline.points;
    var line = new THREE.Line(line_geo, line_mat);
                                        // (path, segments, radius, radiusSegments, closed, taper?)
    var tube_geo = new THREE.TubeGeometry(extrudeSettings.extrudePath, 222, 0.65, 8, false);
    tube_geo.vertices.forEach(function(vert) {
        vert.x += Math.random() * 0.3 - 0.15;
        vert.y += Math.random() * 0.3 - 0.15;
        vert.z += Math.random() * 0.3 - 0.15;
    });
    tube_geo.computeFaceNormals();

    var lambert_mat = new THREE.MeshLambertMaterial({
        color: 0xFFFFFF,
        side: THREE.DoubleSide,
        shading: THREE.SmoothShading
    });
    var flat_mat = new THREE.MeshLambertMaterial({
        color: 0x0099FF,
        emissive: 0x001122,
        side: THREE.BackSide,
        shading: THREE.FlatShading,
        visible: false
    });
    var wire_mat = new THREE.MeshBasicMaterial({
        color: 0x009900,
        wireframe: true,
        opacity: 0.4,
        transparent: true,
        wireframeLinewidth: 2
    });
    var debug_mat = new THREE.MeshBasicMaterial({
        color: 0xFF0000,
        wireframe: true,
        opacity: 0.2,
        transparent: true,
        wireframeLinewidth: 1,
        side: THREE.BackSide
    });
    var tube_mats_array = [lambert_mat, wire_mat];
    var tube = new THREE.SceneUtils.createMultiMaterialObject(tube_geo, tube_mats_array);
    var tube_flat = new THREE.Mesh(tube_geo, flat_mat);
    var tube_debug = new THREE.Mesh(tube_geo, debug_mat);
    scene.add(tube);
    // scene.add(tube_flat);
    // scene.add(tube_debug);



    // boxes
    function getBoxMat(col) {
        if (col == null) col = Math.random() * 0xFFFFFF;
        return new THREE.MeshLambertMaterial({
            color: col,
            emissive: col,
            transparent: true,
            opacity: 0.0
        });
    }

    function getBoxWireMat(col) {
        if (col == null) col = 0xFFCC00;
        return new THREE.MeshBasicMaterial({
            color: col,
            wireframe: true,
            opacity: 0.4,
            transparent: true,
            wireframeLinewidth: 2
        });
    }

    var b = 0;
    var num_boxes = 30;
    var point_light;
    var box_geo = new THREE.BoxGeometry(0.1, 0.1, 0.1); // new THREE.IcosahedronGeometry(0.1, 1); // 
    // var box_mat = getBoxMat(0xFF9900);
    var kill_boxes = [];
    while (b < num_boxes) {
       
        p = Math.max(Math.min(b / num_boxes + Math.random() * 0.05, 1), 0);
        var pos = spline.getPointAt(p);
        pos.x += Math.random() - 0.4;
        pos.z += Math.random() - 0.4;
        var rote = new THREE.Vector3(
            Math.random() * Math.PI * 2, 
            Math.random() * Math.PI * 2, 
            Math.random() * Math.PI * 2
        );

        var box_mat = getBoxMat(0xFF9900);
        var box_fill = new THREE.Mesh(box_geo, box_mat);
        box_fill.position.copy(pos);
        box_fill.rotation.copy(rote);
        scene.add(box_fill);

        // normals
        // var face_normals = new THREE.FaceNormalsHelper( box_fill, 0.005, 0xffff00, 1 );
        // scene.add(face_normals);
        
        var box = new THREE.BoxHelper(box_fill);
        box.position.copy(pos);
        box.rotation.copy(rote);
        box.material.color.setRGB(0.6, 0.45, 0.0);
        box.material.transparent = true;
        box.material.linewidth = 2;
        box.kill = getKillBoxFn(box, box_fill);
        scene.add(box);

        var prob = Math.random() * 1.0;
        if (prob < 0.4) {
            point_light = new THREE.PointLight(0x000000, 0.8, 3.0);
            point_light.position = box.position;
            point_light.color.g = Math.random() + 0.2;
            if (prob < 0.1) {
                point_light.color.r = 1.0;
            }
            scene.add(point_light);
        }
        b += 1;
    }

    function getKillBoxFn (box, box_mesh) {
        var scale = 1.0;
        box.active = false;
        return function () {
            if (box.active === true) {
                if (scale < 50) {
                    scale *= 1.1;
                    box.material.color.r *= 1.1;
                    box.material.color.g *= 1.1;
                    box.material.color.b *= 1.1;
                    box.material.opacity -= 0.01;
                    box.material.linewidth = scale;
                    box_mesh.material.opacity += 0.02;
                } else {
                    // scale = 0.01;
                    box.material.opacity = 1.0;
                    box.material.linewidth = 1;
                    box.active = false;
                }
            }
        }
    }


    var crosshairs = new THREE.Object3D();
    crosshairs.position.z = -0.2;

    // redefine line_mat
    line_mat = new THREE.LineBasicMaterial({
        color: 0xFF0000,
        linewidth: 2
    });

    // redefine line_geo
    line_geo = new THREE.Geometry();
    line_geo.vertices.push(new THREE.Vector3(0, 0.015, 0), new THREE.Vector3(0, 0.005, 0));
    var line_n = new THREE.Line(line_geo, line_mat);
    var line_e = new THREE.Line(line_geo, line_mat);
    line_e.rotation.z = degToRad(-90);
    var line_s = new THREE.Line(line_geo, line_mat);
    line_s.rotation.z = degToRad(180);
    var line_w = new THREE.Line(line_geo, line_mat);
    line_w.rotation.z = degToRad(90);
    crosshairs.add(line_n);
    crosshairs.add(line_e);
    crosshairs.add(line_s);
    crosshairs.add(line_w);
    camera.add(crosshairs);

    // needed to make the crosshairs visible
    // scene.add(camera);

    // EVENTS

    function onKeyUp(evt) {
        var SPACE = 32;
        var ESC = 27;
        var z = 90;
        if (evt.keyCode === 27) {
            togglePause();
        }
        if (evt.keyCode === z) {
            fireLaser();
        }
    }

    function onMouseMove(evt) {
        mouse_pos.set(
            (evt.clientX - win_half_width) * 0.00025,
            (evt.clientY - win_half_height) * -0.00025,
            -0.2
        );

        // mouse 2
        mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1;
        mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1;
    }

    function togglePause() {
        // camera_uses_path = !camera_uses_path;
        is_paused = !is_paused;
        controls.enabled = is_paused;
        controls.target.copy(eye_pos);
    }




    // Frickin Lasers!
    // var laser_wire_mat = new THREE.MeshBasicMaterial({
    //     color: 0xFFFF00,
    //     wireframe: true,
    //     opacity: 1.0,
    //     transparent: true,
    //     wireframeLinewidth: 0.5
    // });
    var laser_geo = new THREE.IcosahedronGeometry(0.05, 2);
    var lasers = [];
    var raycaster = new THREE.Raycaster();
    var direction = new THREE.Vector3();

    // debug 
    var big_line_mat = new THREE.LineBasicMaterial({
        color: 0x009900,
        linewidth: 1
    });

    function getNewLaserBolt () {
        var laser_mat = new THREE.MeshBasicMaterial({ color: 0xFFCC00, transparent: true });
        var new_laser = new THREE.Mesh(laser_geo, laser_mat);
        camera.updateMatrixWorld();
        new_laser.position.copy(camera.position);
        new_laser.direction = new THREE.Vector3(0, 0, 0);
        var active = true;
        var scale = 1.0;
        var is_exploding = false;

        // calc goal position / direction
        var speed = 1;
        var goal_pos = camera.position.clone().setFromMatrixPosition(crosshairs.matrixWorld);
        new_laser.direction.subVectors(new_laser.position, goal_pos)
            .normalize()
            .multiplyScalar(speed);

        // find lasers impact point
        var impact = {
            distance: 0,
            point: new THREE.Vector3()
        };
        direction.subVectors(goal_pos, camera.position);
        raycaster.set(camera.position, direction);
        // raycaster.precision = 0.000001;
        var intersects = raycaster.intersectObjects(scene.children, true);
        
        // BIG DEBUG LINE
        var big_line_geo = new THREE.Geometry();
        var big_line_end_pos = goal_pos.sub(new_laser.direction.clone().multiplyScalar(10));
        big_line_geo.vertices.push(camera.position.clone(), big_line_end_pos);
        var big_line = new THREE.Line(big_line_geo, big_line_mat);
        big_line.direction = new_laser.direction.clone().multiplyScalar(0.5);

        if (intersects.length > 0) {
            impact = {
                distance: intersects[0].distance,
                point: intersects[0].point
            };
        }

        // cleanup
        kill_boxes = kill_boxes.filter(function (box) {
            return box.active === true;
        });
        log(kill_boxes.length);

        // other mouse – for boxes
        raycaster.setFromCamera(mouse, camera);
        intersects = raycaster.intersectObjects(scene.children);
        var dead_box;
        if (intersects.length > 0) {
            dead_box = intersects[0].object;
            if (dead_box.type === 'Line') { // box helper
                dead_box.active = true;
                kill_boxes.push(dead_box);
            }
        }

        function update () {
            if (active === true) {
                if (is_exploding === false) {
                    new_laser.position.sub(new_laser.direction);
                    // big_line.position.sub(big_line.direction);

                    if (new_laser.position.distanceTo(impact.point) < 0.5) {
                        new_laser.position.copy(impact.point);
                        new_laser.scale = new THREE.Vector3(1.0, 1.0, 1.0);
                        new_laser.material.color.setRGB(1, 0, 0);
                        is_exploding = true;
                    }
                } else {
                    if (scale > 0.01) {
                        scale *= 0.98;
                        new_laser.material.color.r *= 0.98;
                        
                    } else {
                        scale = 0.01;
                        active = false;
                    }
                    new_laser.scale.set(scale, scale, scale);
                }
            }
        }

        return {
            geo: new_laser,
            line: big_line,
            update: update,
            impact: impact,
            active: active
        }
    }

    function fireLaser() {
        var laser = getNewLaserBolt();
        lasers.push(laser);
        scene.add(laser.geo);
        // scene.add(laser.line);
    }

    var pos = new THREE.Vector3(9, -1, 10.5); // initial camera pos
    var point = new THREE.Vector3();
    var target = new THREE.Vector3();
    var eye_pos = new THREE.Vector3(10, -0.75, 3.75);
    var eye_point = new THREE.Vector3(10, -0.75, 3.75);
    var eye_target = new THREE.Vector3();
    var val = 0.0005;
    var eye_val = 0.05;
    var scale = 0.1;

    function renderFrame() {
        requestAnimationFrame(renderFrame);
        
        if (counter > 0.94) {
            val = -0.0003;
            eye_val = -0.03;
        }
        if (counter < 0.06) {
            val = 0.0003;
            eye_val = 0.03;
        }
        if (is_paused === false) {

            counter += val;

            point = tube_geo.parameters.path.getPointAt(counter);
            target.subVectors(pos, point);
            target.multiplyScalar(scale);
            pos.subVectors(pos, target);

            eye_point = tube_geo.parameters.path.getPointAt(counter + eye_val);
            eye_target.subVectors(eye_pos, eye_point);
            eye_target.multiplyScalar(scale);
            eye_pos.subVectors(eye_pos, eye_target);
            // cone.position = eye_target;

            camera.position.copy(pos);
            camera.lookAt(eye_pos);
            camera.up.set(1, 0, 0);
        } else {
            controls.update();
        }

        if (mouse_pos != null) {
            crosshairs.position.copy(mouse_pos);
        }
        
        lasers.forEach( function (zap) {
            zap.update();
        });

        kill_boxes.forEach( function (box) {
            box.kill();
        });
        
        renderer.render(scene, camera);
    }

    // START
    renderFrame();

    var doc = document;
    function showInfoPanel() {
        panel.classList.add('scooched_right');
        info_panel.classList.add('open');
    }

    function hideInfoPanel() {
        panel.classList.remove('scooched_right');
        info_panel.classList.remove('open');
    }

    function toggleInfoPanel() {
        if (info_panel.classList.contains('open')) {
            hideInfoPanel();
        } else {
            showInfoPanel();
        }
    }

    function clicked(evt) {
        if (evt.target.id === 'nub') {
            toggleInfoPanel();
        }
        if (evt.target.id === '') {
            if (is_paused === false) { fireLaser(); }
        }
    }

    doc.addEventListener('click', clicked);
    doc.addEventListener('mousemove', onMouseMove, false);
    doc.addEventListener('keyup', onKeyUp, false);
})();