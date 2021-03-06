###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->
    d = document; w = window
    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, w.innerWidth / w.innerHeight, 0.1, 10000 
    renderer = new THREE.WebGLRenderer()
    controls = new THREE.TrackballControls camera 
    log = console.log.bind console
    counter = 0

    ctrls =
        use_turntable: true

    w.ctrls = ctrls
    gui = new dat.GUI()
    gui.add ctrls, 'use_turntable'

    controls.rotateSpeed = 1.0
    controls.zoomSpeed = 1.2
    controls.panSpeed = 0.8
    controls.noZoom = false
    controls.noPan = false
    controls.staticMoving = true
    controls.dynamicDampingFactor = 0.3
    controls.keys = [ 65, 83, 68 ]

    scene.fog = new THREE.FogExp2 0x000000, 0.0025
    renderer.setSize w.innerWidth, w.innerHeight 
    d.body.appendChild renderer.domElement

    particle_geo = new THREE.Geometry()
    points = []

    ###
    Returns a random point of a sphere, evenly distributed over the sphere.
    The sphere is centered at (x0,y0,z0) with the passed in radius.
    The returned point is returned as a three element array [x,y,z]. 

    http://stackoverflow.com/questions/5531827/random-point-on-a-given-sphere
    ###
    getSpherePoint = (radius, p, r) ->
        x0 = 0; y0 = 0; z0 = 0
        u = p /  p_per_ring
        v = r /  num_rings + 0.05
        theta = 2 * Math.PI * u # between 0 and 2PI
        phi = Math.acos 2 * v - 1 # between 0 and PI

        point =
            mult: Math.random() * 0.01 + 0.2
            r: radius
            u: u
            v: v
            x: x0 + radius * Math.sin(phi) * Math.cos theta
            y: y0 + radius * Math.sin(phi) * Math.sin theta
            z: z0 + radius * Math.cos phi
        

    r = 0; num_rings = 16
    p_per_ring = 500
    radius = 100
    while r < num_rings
        p = 0
        while p < p_per_ring
            color = new THREE.Color()
            vertex = new THREE.Vector3()
            pos = getSpherePoint radius, p, r
                
            vertex.x = pos.x
            vertex.y = pos.y
            vertex.z = pos.z

            render = ->
                u = @pos.u
                v = @pos.v
                radius = @pos.r * (1 + Math.sin(counter * @pos.mult) * 0.2)
                theta = 2 * Math.PI * u # between 0 and 2PI
                phi = Math.acos 2 * v - 1 # between 0 and PI
                @vertex.x = (radius * Math.sin(phi) * Math.cos(theta))
                @vertex.y = (radius * Math.sin(phi) * Math.sin(theta))
                @vertex.z = radius * Math.cos phi

                hue_shifter = Math.sin(counter * 0.00001)
                @color.setHSL radius / @pos.r + hue_shifter, 1.0, 0.5
                return

            point =
                render: render
                vertex: vertex
                color: color
                pos: pos

            particle_geo.vertices.push vertex
            particle_geo.colors.push color
            points.push point
            p += 1
        r += 1
        
    particle_mat = new THREE.ParticleBasicMaterial size: 0.5, vertexColors: true
    particles = new THREE.ParticleSystem particle_geo, particle_mat

    scene.add particles
    camera.position.z = 200
    camera.position.x = 300

    renderFrame = -> 
        requestAnimationFrame renderFrame
        counter += 0.15
        points.forEach (p) ->
            p.render()
        particle_geo.verticesNeedUpdate = true
        particle_geo.colorsNeedUpdate = true
        
        if ctrls.use_turntable is true
            camera.position.z -= (camera.position.z - 250 * Math.sin(counter * 0.01) ) * 0.01
            camera.position.x -= (camera.position.x - 250 * Math.cos(counter * 0.01) ) * 0.01
            camera.lookAt(scene.position)
        else
            controls.update()

        renderer.render scene, camera
    
    renderFrame()
