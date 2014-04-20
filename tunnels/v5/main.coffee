do ->
    scene = new THREE.Scene()
    camera = new THREE.PerspectiveCamera 60, window.innerWidth/window.innerHeight, 0.1, 1000
    camera.position.z = 40

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

    renderer = new THREE.WebGLRenderer()
    log = console.log.bind console
    counter = 0

    # scene.fog = new THREE.FogExp2 0x000000, 0.09
    renderer.setSize window.innerWidth, window.innerHeight 
    document.body.appendChild renderer.domElement

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

    # line_mat = new THREE.LineBasicMaterial color: 0xff0000, opacity: 1, linewidth: 1
    # line_geo = new THREE.Geometry()
    # line_geo.vertices = spline.points
    # line = new THREE.Line line_geo, line_mat
    # scene.add line
                                        # path, segments, radius, radius_segments, closed, debug
    tube_geo = new THREE.TubeGeometry extrudeSettings.extrudePath, 222, 0.65, 8, false, true

    tube_geo.vertices.forEach (vert) ->
        vert.x += Math.random() * 0.3 - 0.15
        vert.y += Math.random() * 0.3 - 0.15
        vert.z += Math.random() * 0.3 - 0.15
        return
    tube_geo.computeFaceNormals()

    getPhongMat = (col = 0x0099FF) ->
        new THREE.MeshPhongMaterial color: col, specular: 0x606060, emissive: 0x001122, side: THREE.BackSide, shading: THREE.FlatShading

    lambert_mat = new THREE.MeshLambertMaterial color: 0x0099FF, emissive: 0x001122, side: THREE.BackSide, shading:  THREE.FlatShading
    wire_mat = new THREE.MeshBasicMaterial color: 0x002244, wireframe: true, opacity: 1.0, transparent: true, wireframeLinewidth: 2
    tube_mats_array = [ getPhongMat(), wire_mat ] 

    tube = new THREE.Mesh tube_geo, lambert_mat #getPhongMat()
    # tube = new THREE.SceneUtils.createMultiMaterialObject  tube_geo, tube_mats_array
    scene.add tube


    # BOXES
    box_geo = new THREE.CubeGeometry 0.075, 0.075, 0.075
    solid_mat = new THREE.MeshBasicMaterial color: 0x440088
    getBoxWireMat = (col) ->
        col or (col = 0xCC00FF)
        new THREE.MeshBasicMaterial color: col, wireframe: true, opacity: 1.0, transparent: true, wireframeLinewidth: 2

    box_mats_array = [ solid_mat, getBoxWireMat() ] 
   
    # buncha boxes
    b = 0; num_boxes = 30
    while b < num_boxes
        # box = new THREE.Mesh box_geo, solid_mat # getPhongMat 0xCC00FF
        box = new THREE.BoxHelper()
        box.scale.set 0.05, 0.05, 0.05
        box.material.color.setRGB 0.75, 0, 1.0
        box.material.linewidth = 2
        # box = new THREE.SceneUtils.createMultiMaterialObject  box_geo, box_mats_array
        p = Math.max Math.min(b / num_boxes + Math.random() * 0.05, 1), 0
        pos = spline.getPointAt p
        box.position = pos
        box.position.x += Math.random() - 0.4
        box.position.z += Math.random() - 0.4
        box.rotation.set  Math.random() * Math.PI * 2, Math.random() * Math.PI * 2, Math.random() * Math.PI * 2
        scene.add box

        getPointLight = ->
            new THREE.PointLight 0xFFFFFF, 0.65, 3.0

        prob = Math.random() * 1.0
        if prob < 0.6
            point_light = getPointLight()
            point_light.position = box.position
        else if prob < 0.8
            if not point_light? then point_light = getPointLight()
            point_light.color.b = 1.0 # Math.random() + 0.2
            point_light.color.g = 1.0 # point_light.color.b * 0.5
            point_light.color.r = 0.0
        if point_light? then scene.add point_light
        b += 1

    onKeyUp = (evt) ->
        SPACE = 32
        ESC = 27
        z = 90
        if evt.keyCode is 27 # ESC
            toggleFollow()

        if evt.keyCode is z    
            log 'zap!'
        return

    toggleFollow = ->
        camera_uses_path = !camera_uses_path
        # log camera_uses_path
        return

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

            camera.position = pos
            camera.lookAt eye_pos
            camera.up.set 1, 0, 0
        else 
            controls.update()

        renderer.render scene, camera
    
    renderFrame()

    document.addEventListener 'keyup', onKeyUp, false
