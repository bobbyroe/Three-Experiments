###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->
    
    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, window.innerWidth/window.innerHeight, 0.1, 1000
    camera.position.z = 40
    camera.lookAt scene.position

    controls = new THREE.TrackballControls camera
    controls.rotateSpeed = 1.0
    controls.zoomSpeed = 1.2
    controls.panSpeed = 0.8
    controls.noZoom = false
    controls.noPan = false
    controls.staticMoving = true
    controls.dynamicDampingFactor = 0.3
    controls.keys = [ 65, 83, 68 ]
    camera_uses_path = true

    ctrls =
        flat_shading: false

    # gui = new dat.GUI()
    # flat = gui.add ctrls, 'flat_shading'

    renderer = new THREE.WebGLRenderer()
    # renderer.shadowMapEnabled = true
    # renderer.shadowMapSoft = true
    # renderer.shadowMapType = THREE.PCFShadowMap
    log = console.log.bind console
    counter = 0
    mouse_pos = null
    is_zapping = false
    win_half_width = window.innerWidth * 0.5
    win_half_height = window.innerHeight * 0.5
    degToRad = (deg) -> deg * Math.PI / 180

    # scene.fog = new THREE.FogExp2 0x000000, 0.09
    renderer.setSize window.innerWidth, window.innerHeight
    info_panel = document.querySelector '#info'
    panel = renderer.domElement
    panel.classList.add 'panel'
    document.body.insertBefore panel, info_panel

    # path
    points = []
    p = 0; num_points = path_points.length # imported from curve.js
    while p < num_points
        points.push new THREE.Vector3 path_points[p], path_points[p + 1], path_points[p + 2]
        p += 3
    spline =  new THREE.SplineCurve3 points
    spline_length = spline.getLength()

    extrudeSettings =
        amount: 20
        bevelEnabled: false
        bevelSegments: 2
        steps: 15 # bevelSegments: 2, steps: 2 , bevelSegments: 5, bevelSize: 8, bevelThickness:5,
        extrudePath: spline

    line_mat = new THREE.LineBasicMaterial color: 0xff0000, opacity: 1, linewidth: 1
    line_geo = new THREE.Geometry()
    line_geo.vertices = spline.points
    line = new THREE.Line line_geo, line_mat
    # scene.add line
                                        # path, segments, radius, radius_segments, closed, debug
    tube_geo = new THREE.TubeGeometry extrudeSettings.extrudePath, 222, 0.65, 8, false, true

    tube_geo.vertices.forEach (vert) ->
        vert.x += Math.random() * 0.3 - 0.15
        vert.y += Math.random() * 0.3 - 0.15
        vert.z += Math.random() * 0.3 - 0.15
        return
    tube_geo.computeFaceNormals()

    lambert_mat = new THREE.MeshLambertMaterial color: 0xFFFFFF, side: THREE.DoubleSide, shading:  THREE.SmoothShading
    flat_mat = new THREE.MeshLambertMaterial color: 0x0099FF, emissive: 0x001122, side: THREE.BackSide, shading:  THREE.FlatShading, visible: false
    # flat_mat = new THREE.MeshLambertMaterial color: 0xFFFFFF, side: THREE.BackSide, shading:  THREE.FlatShading
    wire_mat = new THREE.MeshBasicMaterial color: 0x009900, wireframe: true, opacity: 0.4, transparent: true, wireframeLinewidth: 2
    debug_mat = new THREE.MeshBasicMaterial color: 0xFF9900, wireframe: true, opacity: 1.0, transparent: true, wireframeLinewidth: 2
    tube_mats_array = [ lambert_mat, wire_mat ] 

    # tube = new THREE.Mesh tube_geo, debug_mat # new THREE.SceneUtils.createMultiMaterialObject  tube_geo, tube_mats_array
    tube = new THREE.SceneUtils.createMultiMaterialObject  tube_geo, tube_mats_array
    tube_flat = new THREE.Mesh tube_geo, flat_mat
    # tube.castShadow = true
    # tube.receiveShadow = true
    scene.add tube
    scene.add tube_flat


    # debug
    box_geo = new THREE.CubeGeometry 0.075, 0.075, 0.075
    getBoxMat = (col) ->
        col or (col = Math.random() * 0xFFFFFF)
        new THREE.MeshLambertMaterial color: col, shading: THREE.FlatShading

    getBoxWireMat = (col) ->
        col or (col = 0xFFCC00) # Math.random() * 0xFFFFFF)
        new THREE.MeshBasicMaterial color: col, wireframe: true, opacity: 0.4, transparent: true, wireframeLinewidth: 2

    # buncha boxes
    b = 0; num_boxes = 30
    while b < num_boxes
        #
        box = new THREE.BoxHelper()
        box.scale.set 0.05, 0.05, 0.05
        box.material.color.setRGB 0.6, 0.45, 0.0
        box.material.linewidth = 2
        #
        # box = new THREE.Mesh box_geo, getBoxWireMat()
        p = Math.max Math.min(b / num_boxes + Math.random() * 0.05, 1), 0
        pos = spline.getPointAt p
        box.position = pos
        box.position.x += Math.random() - 0.4
        box.position.z += Math.random() - 0.4
        box.rotation.set  Math.random() * Math.PI * 2, Math.random() * Math.PI * 2, Math.random() * Math.PI * 2
        # box.castShadow = true
        # box.receiveShadow = true
        scene.add box

        prob = Math.random() * 1.0
        if prob < 0.4
            point_light = new THREE.PointLight 0x000000, 0.8, 3.0
            point_light.position = box.position
            point_light.color.g = Math.random() + 0.2
            if prob < 0.1 then point_light.color.r = 1.0
            scene.add point_light
        b += 1


    cone_geo = new THREE.CylinderGeometry 0.0001, 0.5, 1.25
    cone_mat = new THREE.MeshNormalMaterial()
    cone = new THREE.Mesh cone_geo, cone_mat
    cone.position = spline.getPointAt 0
    # scene.add cone

    crosshairs = new THREE.Object3D()
    crosshairs.position.z = -0.2
    line_mat = new THREE.LineBasicMaterial color: 0xFF0000, linewidth: 2
    line_geo = new THREE.Geometry()
    line_geo.vertices.push new THREE.Vector3( 0, 0.015, 0 ), new THREE.Vector3( 0, 0.005, 0 )
    line_n = new THREE.Line line_geo, line_mat
    line_e = new THREE.Line line_geo, line_mat
    line_e.rotation.z = degToRad -90
    line_s = new THREE.Line line_geo, line_mat
    line_s.rotation.z = degToRad 180
    line_w = new THREE.Line line_geo, line_mat
    line_w.rotation.z = degToRad 90
    crosshairs.add(line_n); crosshairs.add(line_e); crosshairs.add(line_s); crosshairs.add(line_w)
    camera.add crosshairs
    # scene.add camera

    laser_mat = new THREE.MeshBasicMaterial color: 0xFFCC00
    laser_geo = new THREE.CylinderGeometry 0.02, 0.02, 2, 8
    laser_geo.applyMatrix new THREE.Matrix4().makeTranslation 0, -1, 0 # offset the pivot
    laser = new THREE.Mesh laser_geo, laser_mat
    laser.position.z = 0
    laser.rotation.x = degToRad 90

    laser_targeter = new THREE.Object3D()
    laser_targeter.add laser
    scene.add laser_targeter

    # lights
    # sunlight = new THREE.DirectionalLight 0xffffdd, 1.0
    # bouncelight = new THREE.DirectionalLight 0xddffff, 0.2
    # rimlight = new THREE.DirectionalLight 0xddffff, 2.0
    # sunlight.position.set 1, 1, 1
    # bouncelight.position.set 1, -1, -1
    # rimlight.position.set 0, 0.5, -1
    # scene.add rimlight
    # scene.add sunlight
    # scene.add bouncelight

    onKeyUp = (evt) ->
        SPACE = 32
        ESC = 27
        z = 90
        if evt.keyCode is 27 # ESC
            toggleFollow()

        if evt.keyCode is z    
            fire true
        return

    onClick = (evt) ->
        # fire true

    onMouseMove = (evt) ->
        mouse_pos = 
            x: ( evt.clientX - win_half_width ) * 0.00025
            y: ( evt.clientY - win_half_height ) * -0.00025
            z: -0.2 # -10 # ( hand.palmPosition[1] * 0.1 ) - 0
        return

    toggleFollow = ->
        camera_uses_path = !camera_uses_path
        log camera_uses_path
        return

    fire = (frealz) ->
        dx = camera.position.x - (crosshairs.position.x * -2)
        dy = camera.position.y - (crosshairs.position.y * -2)
        dz = camera.position.z - crosshairs.position.z
        goal_rote_y = Math.atan2 dz, dx
        goal_rote_x = Math.atan2 dz, dy

        laser_targeter.position = camera.position.clone()
        laser_targeter.rotation.x = (1.5 * camera.rotation.x + degToRad(270)) - goal_rote_x
        laser_targeter.rotation.y = (-1.5 * camera.rotation.y + degToRad(90)) - goal_rote_y
        laser.position.z = 0
        log 'zap!'
        is_zapping = frealz
        return

    # DAT.GUI Fires on every change, drag, keypress, etc.   
    # flat.onChange (use_flat_mat) ->
    #     log tube.material, tube_flat.material
    #     tube.material.visible = not use_flat_mat
    #     tube_flat.material.visible = use_flat_mat
       

    pos = new THREE.Vector3(); point = new THREE.Vector3(); target = new THREE.Vector3()
    eye_pos = new THREE.Vector3(); eye_point = new THREE.Vector3(); eye_target = new THREE.Vector3(); 
    val = 0.0005; eye_val = 0.05
    renderFrame = -> 
        requestAnimationFrame renderFrame
        counter += val
        if counter > 0.94
            val = -0.0005
            eye_val = -0.05
        if counter < 0.06
            val = 0.0005
            eye_val = 0.05

        if camera_uses_path is true
            point = tube_geo.path.getPointAt counter
            target.subVectors pos, point
            target.multiplyScalar 0.1
            pos.subVectors pos, target
            
            eye_point = tube_geo.path.getPointAt (counter + eye_val)
            eye_target.subVectors eye_pos, eye_point
            eye_target.multiplyScalar 0.1
            eye_pos.subVectors eye_pos, eye_target
            cone.position = eye_target


            camera.position = pos
            camera.lookAt eye_pos
            camera.up.set 1, 0, 0
        else 
            controls.update()

        if mouse_pos? then crosshairs.position = mouse_pos
        
        if is_zapping is true
            laser.position.z += 0.9
            if laser.position.z > 30 then fire false

        renderer.render scene, camera
    
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

    document.addEventListener 'mousemove', onMouseMove, false
    document.addEventListener 'keyup', onKeyUp, false
    # document.addEventListener 'click', onClick, false
