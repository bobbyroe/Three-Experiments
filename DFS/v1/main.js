(function() {
    "use strict"
    const scene = new THREE.Scene();
    let aspect = window.innerWidth / window.innerHeight;
    const camera = new THREE.PerspectiveCamera(60, aspect, 0.1, 20000);
    const renderer = new THREE.WebGLRenderer({ antialias: true });
    const controls = new THREE.TrackballControls(camera);
    const color_cube = null;
    const log = console.log.bind(console);
    controls.rotateSpeed = 1.0;
    controls.zoomSpeed = 1.2;
    controls.panSpeed = 0.8;
    controls.noZoom = false;
    controls.noPan = false;
    controls.staticMoving = true;
    controls.dynamicDampingFactor = 0.3;
    controls.keys = [65, 83, 68]; // A, S, D
    // scene.fog = new THREE.FogExp2(0x00ccFF, 0.00005);
    renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);
    document.addEventListener('keyup', onKeyUp, false);

    function getWireMat (col) {
        return new THREE.MeshBasicMaterial({
            color: col,
            opacity: 0.5,
            wireframe: true,
            wireframeLinewidth: 1
        });
    }

    function getFlatMat (col) {
        return new THREE.MeshPhongMaterial({
            color: col,
            wireframe: false,
            // specular: 0x009900,
            shininess: 0,
            emissive: 0x552200,
            shading: THREE.FlatShading
        });
    }

    var objects = [];
    var obj_geo = new THREE.IcosahedronGeometry(1, 1);
            
 
    init();
    function init () {
        
        getMeshes(16);
        renderFrame();
    }

    function getMeshes (num_meshes) {
        for (let i = 0; i < num_meshes; i++) {
            let mesh = new THREE.Mesh(obj_geo, getFlatMat(0xFF9900));
            let pos = getRandomPos();
            mesh.position.copy(pos);
            objects.push(mesh);
            scene.add(mesh);
        }
    }
    
    function getRandomPos () {
        return new THREE.Vector3(
            Math.random() * 50 - 25,
            0,
            Math.random() * 50 - 25
        );
    }

    // lights
    var sunlight = new THREE.DirectionalLight(0xffffee, 2.0);
    var bouncelight = new THREE.DirectionalLight(0xeeffff, 0.5);
    var rimlight = new THREE.DirectionalLight(0xeeffff, 1.0);
    sunlight.position.set(1, -1, 1);
    bouncelight.position.set(-0.5, -1, 1);
    rimlight.position.set(0, 0.5, -1);
    scene.add(sunlight);
    scene.add(bouncelight);
    scene.add(rimlight);

    var helper = new THREE.DirectionalLightHelper(bouncelight, 1);
    // scene.add(helper);


    camera.position.z = 10;
    camera.position.y = 50;
    camera.position.x = 0;

    function onKeyUp (evt) {
        console.log('keyCode', evt.keyCode);
    }

    function renderFrame () {
        requestAnimationFrame(renderFrame);
        controls.update();
        renderer.clear();
        objects.forEach( (o) => {
            o.rotation.y -= 0.01;
        });
        renderer.render(scene, camera);
    }

})();
