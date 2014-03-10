###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->
    w = window
    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, w.innerWidth/w.innerHeight, 0.1, 10000 
    camera.position.y = -200
    camera.position.z = 100
    renderer = new THREE.WebGLRenderer()
    controls = new THREE.TrackballControls camera 
    log = console.log.bind console
    counter = 0

    ctrls =
        use_turntable: true

    w.ctrls = ctrls
    gui = new dat.GUI()
    gui.add ctrls, 'use_turntable'

    stop_anim = false

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
    document.body.appendChild renderer.domElement

    # PARTICLES
    p_geo = new THREE.Geometry()
    p_mat = new THREE.ParticleBasicMaterial size: 0.5, vertexColors: true

    materials = []
    particles = []
    mesh = {}
    stems = []
    num_cubes = 5
   
    ###
    Returns a random point of a sphere, evenly distributed over the sphere.
    The sphere is centered at (x0,y0,z0) with the passed in radius.
    The returned point is returned as a three element array [x,y,z]. 

    http://stackoverflow.com/questions/5531827/random-point-on-a-given-sphere
    ###
    randomSpherePoint = (opts) ->
        u = opts.u 
        v = opts.v
        theta = 2 * Math.PI * u # between 0 and 2PI
        phi = Math.acos 2 * v - 1 # between 0 and PI

        point =
            u: u
            v: v
            x: opts.x + (opts.length * Math.sin(phi) * Math.cos(theta))
            y: opts.y + (opts.length * Math.sin(phi) * Math.sin(theta))
            z: opts.z + (opts.length * Math.cos(phi)) 
    

    num_generations = 5
    getSegment = (generation, verts, cols, surface_pos, parent) ->

        vertex = new THREE.Vector3()
        prev_pos = 
            x: parent?.pos.x or 0
            y: parent?.pos.y or 0
            z: parent?.pos.z or 0

        options =
            x: prev_pos.x
            y: prev_pos.y
            z: prev_pos.z
            length: (num_generations + 10) - generation # min length = 4
            u: surface_pos.u
            v: surface_pos.v

        pos = randomSpherePoint options
        pos.magnitude = surface_pos.magnitude
        vertex.x = pos.x
        vertex.y = pos.y
        vertex.z = pos.z
        color = new THREE.Color()
        color.setHSL (if surface_pos.prob < 0.1 then 0.33 else 0.76), 1.0, generation / num_generations

        p_geo.vertices.push vertex
        p_geo.colors.push color
        verts.push vertex
        cols.push color

        render = ->
            u = Math.max Math.min( (@pos.u + Math.sin(counter) * @pos.magnitude), 1 ), 0
            v = Math.max Math.min( (@pos.v + Math.cos(counter) * @pos.magnitude), 1 ), 0

            theta = 2 * Math.PI * u # between 0 and 2PI
            phi = Math.acos(2 * v - 1) # between 0 and PI

            @vertex.x = @pos.x + (@length * Math.sin(phi) * Math.cos(theta))
            @vertex.y = @pos.y + (@length * Math.sin(phi) * Math.sin(theta))
            @vertex.z = @pos.z + (@length * Math.cos(phi))
            @children.forEach (child) ->
                child.render()
            return

        segment = 
            length: options.length
            pos: pos
            vertex: vertex
            color: color
            parent: parent
            children: []
            render: render

        generation += 1
        if generation < num_generations

            # 2 branches!
            new_pos = 
                prob: surface_pos.prob
                magnitude: surface_pos.magnitude + 0.01
                u: surface_pos.u + 0.01
                v: surface_pos.v
            segment.children.push getSegment generation, verts, cols, new_pos, segment # recurse!

            new_pos = 
                prob: surface_pos.prob
                magnitude: surface_pos.magnitude + 0.01
                u: surface_pos.u - 0.01
                v: surface_pos.v
            segment.children.push getSegment generation, verts, cols, new_pos, segment # recurse!

        segment


    getStem = ->
        # LINE
        line_geo = new THREE.Geometry()
        line_mat = new THREE.LineBasicMaterial vertexColors: THREE.VertexColors, linewidth: 1
        verts = [new THREE.Vector3( 0, 0, 0 )]
        cols = [new THREE.Color( 0xc0c0c0, 0, 0 )]
        pos = 
            magnitude: 0.01
            prob: Math.random()
            u: Math.random()
            v: Math.random() * 0.9 + 0.05

        stem = getSegment 0, verts, cols, pos, null
        line_geo.vertices = verts
        line_geo.colors = cols
        render = ->
            if stop_anim then return
            @line_geo.verticesNeedUpdate = true
            @stem.render()

        verts: verts
        stem: stem
        line_geo: line_geo
        line: new THREE.Line line_geo, line_mat, THREE.LineStrip
        cols: cols
        render: render 


    i = 0; num_stems = 200
    radius = 20
    while i < num_stems

        stem = getStem()
        scene.add stem.line
        stems.push stem
        i += 1


    particles = new THREE.ParticleSystem p_geo, p_mat

    scene.add particles

    renderFrame = -> 
        requestAnimationFrame renderFrame
        counter += 0.1
        stems.forEach (stem) ->
            stem.render()
        p_geo.verticesNeedUpdate = true

        if ctrls.use_turntable is true
            camera.position.x -= (camera.position.x - 200 * Math.sin(counter * 0.02) ) * 0.01
            camera.position.y -= (camera.position.y - 200 * Math.cos(counter * 0.02) ) * 0.01
            camera.lookAt scene.position
        else
            controls.update()

        renderer.render scene, camera
    
    renderFrame()

    onKeyUp = (evt) ->
        evt.preventDefault()
        if evt.keyCode is 32 # SPACE
            stop_anim = !stop_anim
        return
    document.addEventListener 'keyup', onKeyUp, false
