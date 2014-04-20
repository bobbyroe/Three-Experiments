###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->
    d = document
    windowHalf =
        x: window.innerWidth * 0.5
        y: window.innerHeight * 0.5
    mouse = {x: 0, y: 0}
    HALF_PI = Math.PI * 0.5
    counter = 0

    reverse_direction = 0

    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, window.innerWidth/window.innerHeight, 0.1, 10000
    distance = 250
    camera.position.z = distance
    # scene.fog = new THREE.FogExp2 0x000000, 0.0025
    renderer = new THREE.WebGLRenderer()
    controls = new THREE.TrackballControls camera 
    log = console.log.bind console

    controls.rotateSpeed = 1.0
    controls.zoomSpeed = 1.2
    controls.panSpeed = 0.8
    controls.noZoom = false
    controls.noPan = false
    controls.staticMoving = true
    controls.dynamicDampingFactor = 0.3
    controls.keys = [ 65, 83, 68 ]

    # scene.fog = new THREE.FogExp2 0x000000, 0.0025
    renderer.setSize window.innerWidth, window.innerHeight 
    document.body.appendChild renderer.domElement

    getWireMat = (col = 0x660000) ->
        new THREE.MeshBasicMaterial color: col, opacity: 1, wireframe: true, wireframeLinewidth: 2

    getLineMat = (col) ->
        new THREE.LineBasicMaterial color: col, linewidth: 1

    # get ready to normalize the data
    max_pos = 
        x: 0
        y: 0
    min_pos =
        x: 1000
        y: 1000

    world.forEach (land_mass) ->
        land_mass.forEach (vertex) ->
            min_pos = 
                x: Math.min min_pos.x, vertex.x
                y: Math.min min_pos.y, vertex.y
            max_pos = 
                x: Math.max max_pos.x, vertex.x
                y: Math.max max_pos.y, vertex.y

    # normalize
    world.forEach (land_mass) ->
        land_mass.forEach (vertex) ->
            temp_y = vertex.y
            vertex.x = -1 * (vertex.x / max_pos.x) + 1
            vertex.y = -0.92 * (vertex.y / max_pos.y) + 0.98 # quantize the top and bottoms 
            # vertex.y = -1 * (vertex.y / max_pos.y) + 1
            
    # map to a sphere
    radius = 100
    world.forEach (land_mass) ->
        land_mass.forEach (vertex) ->
            x0 = 0; y0 = 0; z0 = 0
            u = vertex.x
            v = vertex.y
            theta = 2 * Math.PI * u
            phi = Math.acos 2 * v - 1
            vertex.x = x0 + (radius * Math.sin(phi) * Math.cos(theta))
            vertex.y = y0 + (radius * Math.cos(phi))
            vertex.z = z0 + (radius * Math.sin(phi) * Math.sin(theta))


    # p_geo = new THREE.Geometry()
    # p_geo.vertices = data
    # p_mat = new THREE.ParticleBasicMaterial size: 1, color: 0xFFFFFF # 0x006080
    # particles = new THREE.ParticleSystem p_geo, p_mat
    # scene.add particles
    #
    # dark background
    sphere_geo = new THREE.IcosahedronGeometry 99, 3
    sphere_mat = new THREE.MeshBasicMaterial color: 0x101010, wireframe: false, transparent: true, opacity: 0.8
    # sphere = new THREE.Mesh sphere_geo, sphere_mat
    sphere_mats_array = [sphere_mat, getWireMat()]
    sphere = new THREE.SceneUtils.createMultiMaterialObject sphere_geo, sphere_mats_array
    scene.add sphere

    colors = [0xFF4400, 0x44FF00, 0x22FF00]
    drawWorld = ->
        world.forEach (land_mass, i) ->
            random_color = if i < 3 then colors[i] else Math.random() * 0xFFFFFF
            line_geo = new THREE.Geometry()
            line_geo.vertices = land_mass
            line = new THREE.Line line_geo, getLineMat(random_color)
            sphere.add line
    #
    drawWorld()

    

    # onMouseMove = (evt) ->
    #     normalized_mouseX = (evt.clientX / window.innerWidth ) * 2 - 1
    #     normalized_mouseY =  -(evt.clientY / window.innerHeight ) * 2 + 1
        
    #     mouse = 
    #         x: normalized_mouseX * windowHalf.x * 0.23
    #         y: normalized_mouseY * windowHalf.y * 0.23
    #     return

    onKeyUp = (evt) ->
        evt.preventDefault()
        if evt.keyCode is 32 # SPACE
            log min_pos, max_pos # JSON.stringify p_geo.vertices
        return

    renderFrame = ->
        requestAnimationFrame renderFrame

        controls.update()
        counter += 0.01
        # camera.position.z = Math.sin(counter) * distance
        # camera.position.x = Math.cos(counter) * distance
        sphere.rotation.y = counter
        renderer.render scene, camera

    renderFrame()
    # d.addEventListener( 'mousemove', onMouseMove, false )
    d.addEventListener('keyup', onKeyUp, false)
    
