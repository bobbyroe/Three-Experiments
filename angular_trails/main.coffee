###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->
    d = document; w = window
    windowHalf =
        x: w.innerWidth * 0.5
        y: w.innerHeight * 0.5
    mouse = {x: 0, y: 0}
    HALF_PI = Math.PI * 0.5

    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, w.innerWidth / w.innerHeight, 0.1, 10000
    camera.position.z = 200
    renderer = new THREE.WebGLRenderer preserveDrawingBuffer: true
    log = console.log.bind console

    ctrls =
        auto_clear: true

    w.ctrls = ctrls
    gui = new dat.GUI()
    gui.add ctrls, 'auto_clear'

    renderer.setSize w.innerWidth, w.innerHeight 
    info_panel = document.querySelector '#info'
    panel = renderer.domElement
    panel.classList.add 'panel'
    document.body.insertBefore panel, info_panel

    getWireMat = (col = 0xFFFF00) ->
        new THREE.MeshBasicMaterial color: col, opacity: 0, wireframe: true, wireframeLinewidth: 0, transparent: true

    tetra_geo = new THREE.SphereGeometry 0.1, 3, 2
    mouse_mesh = new THREE.Mesh tetra_geo, getWireMat()
    scene.add mouse_mesh

    getLineMat = (col = 0xFF0000) ->
        new THREE.LineBasicMaterial color: col, linewidth: 2

    getVertices = ->
        verts = []
        verts.push new THREE.Vector3 0, 0.75, 0
        verts.push new THREE.Vector3 0.5, -0.75, 0
        verts.push new THREE.Vector3 0, -0.5, 0
        verts.push new THREE.Vector3 -0.5, -0.75, 0
        verts.push new THREE.Vector3 0, 0.75, 0
        verts

    head_geo = new THREE.Geometry()
    head_geo.vertices = getVertices()


    num_verts = 250
    getLineVerts = (pos) ->
        verts = []
        n = 0
        while n < num_verts
            verts.push new THREE.Vector3 pos.x, pos.y, pos.z
            n += 1
        verts

    getLineColors = (pos) ->
        cols = []
        n = 0
        while n < num_verts
            cols.push new THREE.Color 0xFFFFFF
            n += 1
        cols

    emitters = []
    getEmitter = (pos) ->

        geo = new THREE.Line head_geo, getLineMat(), THREE.LineLoop
        geo.position =
            x: pos.x
            y: pos.y
            z: 0
        geo.init_pos = geo.position
        geo.scale = x: 0.0001, y: 0.0001, z: 0.0001

        is_frozen = false
        im_special = if Math.random() < 0.2 then true else false
        speed = 1.2

        random_angle = 0
        goal_pos = x: 150, y: geo.position.y
        goal_rote = 0
        rote_speed = Math.random() * 0.4 + 0.01
        rote_offset = 0
        update = (pos) ->

            if @is_frozen then return

            @goal_pos = pos
            dx = @geo.position.x - @goal_pos.x
            dy = @geo.position.y - @goal_pos.y
            dist = Math.sqrt Math.abs dx * dx - dy * dy
            goal_rote = Math.atan2(dy, dx) + HALF_PI + @random_angle
            @goal_rote = Math.round(goal_rote * 2) * 0.5 # 'angularize' the rotation

            @geo.position.x -= Math.sin(@goal_rote) * @speed
            @geo.position.y += Math.cos(@goal_rote) * @speed

            if Math.abs(@geo.position.x - @goal_pos.x) < 1.0 and Math.abs(@geo.position.y - @goal_pos.y) < 1.0
                @random_angle = Math.random() * 2 * Math.PI

            # boundries
            if geo.init_pos.x > 0 and @geo.position.x > geo.init_pos.x then @geo.position.x = geo.init_pos.x
            if geo.init_pos.x < 0 and @geo.position.x < geo.init_pos.x then @geo.position.x = geo.init_pos.x
            if geo.init_pos.y > 0 and @geo.position.y > geo.init_pos.y then @geo.position.y = geo.init_pos.y
            if geo.init_pos.y < 0 and @geo.position.y < geo.init_pos.y then @geo.position.y = geo.init_pos.y
            @line_anim()
            return

        emit = ->
            @particles.geo.vertices[@particles.index].init()
            @particles.index += 1
            return

        line_geo = new THREE.Geometry()
        line_geo.vertices = getLineVerts geo.position
        line_geo.colors = getLineColors()
        line_mat = new THREE.LineBasicMaterial linewidth: Math.random() * 2 + 0.2, vertexColors: THREE.VertexColors
        line = new THREE.Line line_geo, line_mat
        scene.add line

        line_anim = ->

            @line_geo.vertices[0].set @geo.position.x, @geo.position.y, @geo.position.z

            i = @line_geo.vertices.length - 1
            while i > 0
                n = i - 1
                cur_vert = @line_geo.vertices[i]
                next_vert = @line_geo.vertices[n]
                hue = if im_special then 0.6 else 0.0
                sat = if im_special then i/num_verts else 1 - i/num_verts

                if next_vert? then cur_vert.set next_vert.x, next_vert.y, next_vert.z
                @line_geo.colors[i].setHSL(hue, sat, (1.0 - i/num_verts) * 0.25 + 0.15)
                i -= 1

            @line_geo.verticesNeedUpdate = true
            @line_geo.colorsNeedUpdate = true
            return

        scene.add geo

        emitter = 
            geo: geo
            update: update
            emit: emit
            line_anim: line_anim
            speed: speed
            random_angle: random_angle
            goal_rote: goal_rote
            rote_offset: rote_offset
            is_frozen: is_frozen
            goal_pos: goal_pos
            line_geo: line_geo
    # end getEmitter

    e = 0
    num_emitters = 100
    while e < num_emitters
        rand_angle = Math.random() * Math.PI * 2
        radius = 150
        emitter = getEmitter x: Math.sin(rand_angle) * radius, y: Math.cos(rand_angle) * radius
        emitters.push emitter
        e += 1
        
    toggleFollow = ->
        for emtr in emitters
            emtr.random_angle = 0
        return

    toggleFreeze = ->
        for emtr in emitters
            emtr.is_frozen = not emtr.is_frozen
        return

    onMouseMove = (evt) ->
        normalized_mouseX = (evt.clientX / w.innerWidth ) * 2 - 1
        normalized_mouseY =  -(evt.clientY / w.innerHeight ) * 2 + 1
        
        mouse = 
            x: normalized_mouseX * windowHalf.x * 0.23
            y: normalized_mouseY * windowHalf.y * 0.23
        return

    onKeyUp = (evt) ->
        log evt.keyCode
        if evt.keyCode is 32 # SPACE
            toggleFollow()

        if evt.keyCode is 27 # ESC
            toggleFreeze()
        return

    # animation loop
    renderFrame = ->
        requestAnimationFrame renderFrame

        mouse_mesh.position.x = mouse.x
        mouse_mesh.position.y = mouse.y
        
        for emtr in emitters
            emtr.update mouse_mesh.position

        renderer.autoClear = ctrls.auto_clear
        renderer.render scene, camera

    # begin looping
    renderFrame()

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
    d.addEventListener 'mousemove', onMouseMove, false
    d.addEventListener 'keyup', onKeyUp, false
    
