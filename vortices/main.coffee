###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->

    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, window.innerWidth/window.innerHeight, 0.1, 10000
    camera.position.z = 200
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
    use_vortex = false
    is_paused = false
    mouse = 
        x: 0
        y: 0
    windowHalf =
        x: window.innerWidth * 0.5
        y: window.innerHeight * 0.5
    t = 0


    particle_geo = new THREE.Geometry()

    grid_size = 40
    num_particles = grid_size * grid_size
    spacing = 1
    i = 0
    while i < num_particles
        color = new THREE.Color()
        # col = if Math.random() < 0.01 then 0.12 else 0.04
        col = if i is 0 then 0.15 else 0.0
        color.setHSL( col, 1.0, 0.5 )

        vertex = 
            x: i % grid_size * spacing - (grid_size * 0.5 * spacing)
            y: (Math.floor i / grid_size) * spacing - (grid_size * 0.5 * spacing)
            z: 0

        vertex.velocity = 
            x: 0
            y: 0
            z: 0
        vertex.age = 0
        vertex.lifespan = 3

        particle_geo.vertices.push vertex
        particle_geo.colors.push color
        i += 1
        
    particle_mat = new THREE.ParticleSystemMaterial size: 1, vertexColors: true
    particles = new THREE.ParticleSystem particle_geo, particle_mat
    scene.add particles

    getMover = ->
        goal:
            speed:
                x: 1
                y: 1
                z: 1
            move_scale: 
                x: 1
                y: 1
                z: 1
            offset: 
                x: 1
                y: 1
                z: 1
        speed:
            x: 1
            y: 1
            z: 1
            prob: 
                x: 1
                y: 1
                z: 1
        move_scale: 
            x: 1
            y: 1
            z: 1
            prob: 
                x: 1
                y: 1
                z: 1
        offset: 
            x: 1
            y: 1
            z: 1
            prob: 
                x: 1
                y: 1
                z: 1
        rate: 0.002

        getPos: (pos) ->
            # X
            @speed.prob.x = Math.random()
            if @speed.prob.x < 0.05
                @goal.speed.x = Math.random() * 1 + 0.2
            # @speed.x -= (@speed.x - @goal.speed.x) * @rate

            @move_scale.prob.x = Math.random()
            if @move_scale.prob.x < 0.05
                @goal.move_scale.x = Math.random() * 50 + 2
            @move_scale.x -= (@move_scale.x - @goal.move_scale.x) * 0.01

            @offset.prob.x = Math.random()
            if @offset.prob.x < 0.05
                @goal.offset.x = Math.random() * 200 - 100
            @offset.x -= (@offset.x - @goal.offset.x) * @rate

            # Y
            @speed.prob.y = Math.random()
            if @speed.prob.y < 0.05
                @goal.speed.y = Math.random() * 1 + 0.2
            # @speed.y -= (@speed.y - @goal.speed.y) * @rate

            @move_scale.prob.y = Math.random()
            if @move_scale.prob.y < 0.05
                @goal.move_scale.y = Math.random() * 50 + 2
            @move_scale.y -= (@move_scale.y - @goal.move_scale.y) * 0.01

            @offset.prob.y = Math.random()
            if @offset.prob.y < 0.05
                @goal.offset.y = Math.random() * 200 - 100
            @offset.y -= (@offset.y - @goal.offset.y) * @rate

            # Z
            @speed.prob.z = Math.random()
            if @speed.prob.z < 0.05
                @goal.speed.z = Math.random() * 1 + 0.2
            # @speed.z -= (@speed.z - @goal.speed.z) * @rate

            @move_scale.prob.z = Math.random()
            if @move_scale.prob.z < 0.05
                @goal.move_scale.z = Math.random() * 50 + 2
            @move_scale.z -= (@move_scale.z - @goal.move_scale.z) * @rate

            @offset.prob.z = Math.random()
            if @offset.prob.z < 0.05
                @goal.offset.z = Math.random() * 200 - 100
            @offset.z -= (@offset.z - @goal.offset.z) * @rate

            position =
                x: Math.sin(t * @speed.x) * @move_scale.x # + @offset.x
                y: Math.cos(t * @speed.y) * @move_scale.y # + @offset.y
                z: 0 # Math.sin(t * @speed.z) * @move_scale.z
        

    getWireMat = (col = 0x004488) ->
            new THREE.MeshBasicMaterial color: col, opacity: 1, wireframe: false, wireframeLinewidth: 1
    createVortex = ->
        # add the sphere to the scene ....... radius, segments, thetaStart, thetaLength)
        sphere_geo = new THREE.IcosahedronGeometry 3, 2
        sphere = new THREE.Mesh sphere_geo, getWireMat()
        # sphere.position.z = 10
        scene.add sphere
        update = ->
            pos = 
            @sphere.position = @mover.getPos()
            # log @mover.move_scale.x
            # @sphere.position.z = Math.sin(t) * 3
            @x = sphere.position.x
            @y = sphere.position.y
            @z = 0 # sphere.position.z
        toggleViz = ->
            @visible = !@visible
            @sphere.visible = @visible 
        
        new_vortex = 
            x: sphere.position.x
            y: sphere.position.y
            z: sphere.position.z
            mover: getMover()
            speed: x: 1, y: 1, z: 1
            scale: 0.02
            sphere: sphere
            update: update
            toggleVisibility: toggleViz
            visible: true

    vortex = createVortex()

    damping = 1 - 0.005
    max_velocity = 1
    diff = new THREE.Vector3()
    vel = new THREE.Vector3()
    particles_update = ->
        if is_paused is true then return

        p_count = 0
        p = null
        while p_count < num_particles
            p = particle_geo.vertices[p_count]

            # # check if we need to reset
            # if p.y > 100 or p.y < -100
            #     p.velocity.y *= -1
            # if p.x > 100 or p.x < -100
            #     p.velocity.x *= -1

            # VORTEX
            if use_vortex is true
                diff.subVectors(p, vortex)
                vel.crossVectors(diff, vortex.speed)
                factor = Math.min 1 / (0.0000001 + (diff.x * diff.x + diff.y * diff.y + diff.z * diff.z) / vortex.scale), max_velocity
                p.velocity.x += (vel.x - p.velocity.x) * factor 
                p.velocity.y += (vel.y - p.velocity.y) * factor 
                p.velocity.z += (vel.z - p.velocity.z) * factor 

            p.velocity.x *= damping
            p.velocity.y *= damping
            p.velocity.z *= damping
            p.x += p.velocity.x
            p.y += p.velocity.y
            p.z += p.velocity.x

            p_count += 1
        particle_geo.verticesNeedUpdate = true
        return
        

    renderFrame = ->
        t += 0.02
        requestAnimationFrame renderFrame

        particles_update()
        controls.update()
        vortex.update()

        renderer.render scene, camera
    
    renderFrame()

    onKeyed = (evt) ->
        log evt.keyCode
        SPACE = 32
        ESC = 27
        if evt.keyCode is SPACE
            use_vortex = !use_vortex
            if evt.shiftKey is true
                vortex.toggleVisibility()
        if evt.keyCode is ESC
            is_paused = !is_paused

    document.addEventListener 'keyup', onKeyed

    onMouseMoved = (evt) ->
        normalized_mouseX = (evt.clientX / window.innerWidth ) * 2 - 1
        normalized_mouseY =  -(evt.clientY / window.innerHeight ) * 2 + 1
        
        mouse = 
            x: normalized_mouseX * windowHalf.x * 0.2
            y: normalized_mouseY * windowHalf.y * 0.2
        return

    # document.addEventListener 'mousemove', onMouseMoved
