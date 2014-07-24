###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->
    w = window
    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, w.innerWidth / w.innerHeight, 0.1, 20000
    renderer = new THREE.WebGLRenderer()
    controls = new THREE.TrackballControls camera 
    postprocessing = enabled:false 
    texture_cube = null
    texture_blurred_cube = null
    log = console.log.bind console
    counter = 0

    ctrls =
        use_turntable: true
        glass_material: false

    w.ctrls = ctrls
    gui = new dat.GUI()
    gui.add ctrls, 'use_turntable'
    gold = gui.add ctrls, 'glass_material'

    controls.rotateSpeed = 1.0
    controls.zoomSpeed = 1.2
    controls.panSpeed = 0.8
    controls.noZoom = false
    controls.noPan = false
    controls.staticMoving = true
    controls.dynamicDampingFactor = 0.3
    controls.keys = [ 65, 83, 68 ] # A, S, D

    scene.fog = new THREE.FogExp2 0x00ccFF, 0.0001 
    renderer.setSize w.innerWidth, w.innerHeight
    info_panel = document.querySelector '#info'
    panel = renderer.domElement
    panel.classList.add 'panel'
    document.body.insertBefore panel, info_panel
    document.addEventListener 'keyup', onKeyUp, false 

    ball_geo = new THREE.IcosahedronGeometry(0.6, 1)
    cube_geo = new THREE.CubeGeometry(1, 1, 1)
    tetra_geo = new THREE.SphereGeometry(1, 3, 2)
    loader = new THREE.OBJLoader()
    head_geo = null

    getWireMat = (col) ->
        new THREE.MeshBasicMaterial color: col, opacity: 0.5, wireframe: true, wireframeLinewidth: 1
    getGreyMat =  ->
        new THREE.MeshBasicMaterial color: 0xFF0000, opacity: 1.0, wireframe: false
    getRefractoMat = ->
        img = 
        path = "../z_images/"
        format = '.png'
        urls = [
            path + 'checkers' + format, path + 'checkers' + format,
            path + 'checkers' + format, path + 'checkers' + format,
            path + 'checkers' + format, path + 'checkers' + format
        ]

        texture_cube = THREE.ImageUtils.loadTextureCube( urls, new THREE.CubeRefractionMapping() )
        new THREE.MeshBasicMaterial color: 0xFFFFFF, envMap: texture_cube, refractionRatio: 0.95

    getRefractoBlurredMat = ->
        path = "../z_images/"
        format = '.png'
        burls = [
            path + 'checkers_blurred' + format, path + 'checkers_blurred' + format,
            path + 'checkers_blurred' + format, path + 'checkers_blurred' + format,
            path + 'checkers_blurred' + format, path + 'checkers_blurred' + format
        ]

        texture_blurred_cube = THREE.ImageUtils.loadTextureCube burls, new THREE.CubeRefractionMapping()
        new THREE.MeshBasicMaterial color: 0xFFFFFF, envMap: texture_blurred_cube, refractionRatio: 0.95

    getPhongMat = ->

        # environment reflection map
        path = "images/"
        format = '.jpg'
        urls = [
            path + 'disturb3a' + format, path + 'disturb3a' + format,
            path + 'disturb3a' + format, path + 'disturb3a' + format,
            path + 'disturb3a' + format, path + 'disturb3a' + format
        ]
        phong_texture_cube = THREE.ImageUtils.loadTextureCube( urls )

        # bump map
        map_height = THREE.ImageUtils.loadTexture( "images/bump.jpg" );

        map_height.anisotropy = 4
        map_height.repeat.set 0.998, 0.998
        map_height.offset.set 0.001, 0.001

        map_height.wrapS = map_height.wrapT = THREE.RepeatWrapping
        map_height.format = THREE.RGBFormat

        options =
            envMap: phong_texture_cube
            bumpMap: map_height
            # ambient: 0xFF0000
            color: 0xFFFFFF
            specular: 0xFFFFFF
            shininess: 30
            bumpScale: 1.5
            emissive: 0x552200
            shading: THREE.SmoothShading

        new THREE.MeshPhongMaterial options

    refracto_mat = getRefractoBlurredMat()
    color_mat = getRefractoMat()
    gold_mat = getPhongMat()

    geos = [cube_geo, tetra_geo]
    
    objects = []
    parent = new THREE.Object3D()
    scene.add parent

    # lights
    sunlight = new THREE.DirectionalLight 0xffffdd, 1.0
    bouncelight = new THREE.DirectionalLight 0xddffff, 0.6
    rimlight = new THREE.DirectionalLight 0xddffff, 1.2
    sunlight.position.set 1, 1, 1 
    bouncelight.position.set -1, -1, -1 
    rimlight.position.set 0, 0.5, -1 
    scene.add rimlight
    scene.add sunlight
    scene.add bouncelight

    max_dist = 6000
    mesh_scale = 400
    i = 0
    getMesh = (n) ->

        rand = Math.random() * 100
        inc = Math.floor Math.random() * geos.length
        geometry = head_geo
        material = gold_mat # refracto_mat
        mesh = new THREE.Mesh(geometry, material)

        getPosition = ->
            x: Math.random() * max_dist - max_dist * 0.5
            y: Math.random() * max_dist - max_dist * 0.5
            z: Math.random() * max_dist - max_dist * 0.5

        getGridPosition = ->
            x: (n % 5 * mesh_scale) - 800
            y: (Math.floor(n * 0.2) % 5 * mesh_scale) - 800
            z: (Math.floor(n * 0.04) * -mesh_scale) + 800

        mesh.position = x: 0, y: -1000, z: 0
        mesh.scale.x = mesh.scale.y = mesh.scale.z = 1000

        rate = Math.random() * 0.03 + 0.0
        move_rate = Math.random() * 0.03 + 0.005
        goal_pos = mesh.position

        parent.add mesh

        obj = 
            mesh: mesh

    init = ->
        while i < 1
            obj = getMesh i
            objects.push obj
            i += 1
        renderFrame()
        return

    shader = THREE.ShaderLib[ "cube" ]
    shader.uniforms[ "tCube" ].value = texture_cube

    box_mat = new THREE.ShaderMaterial
        fragmentShader: shader.fragmentShader,
        vertexShader: shader.vertexShader,
        uniforms: shader.uniforms,
        depthWrite: false,
        side: THREE.BackSide

    box_mesh = new THREE.Mesh(new THREE.CubeGeometry( 10000, 10000, 10000 ), box_mat)
    scene.add box_mesh

    camera.position.z = 2000
    camera.position.y = 800
    camera.position.x = -1200

    onKeyUp = (evnt) ->
        console.log evt.keyCode
        return

    # Fires on every change, drag, keypress, etc.
    gold.onChange (use_glass_shader) ->
        obj = objects[0]
        log obj
        if use_glass_shader is false
            obj.mesh.material = gold_mat
        else 
            obj.mesh.material = refracto_mat

    renderFrame = ->
        requestAnimationFrame renderFrame

        if ctrls.use_turntable is true
            counter += 0.004
            parent.rotation.y = counter * -1
        
        controls.update()

        renderer.clear()
        renderer.render scene, camera 

    preloadAssets = ->
        loader.load '../z_objs/asaro_04a.obj', (obj) ->
            head_geo = obj.children[0].geometry
            init()
            return
        return

    preloadAssets()

    #

    d = document
    showInfoPanel = ->
        panel.classList.add 'scooched_right'
        info_panel.classList.add 'open'
        is_highlighing_points = false

    hideInfoPanel = ->
        panel.classList.remove 'scooched_right'
        info_panel.classList.remove 'open'
        is_highlighing_points = true

    toggleInfoPanel = ->
        if info_panel.classList.contains 'open'
            hideInfoPanel()
        else 
            showInfoPanel()

    clicked = (evt) ->
        if evt.target.id is 'nub'
            toggleInfoPanel()
        if evt.target.id is ''
            hideInfoPanel()

    d.addEventListener 'click', clicked
        
    
    
