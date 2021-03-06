###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
do ->
	w = window
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
	controls.keys = [ 65, 83, 68 ] # A, S, D

	scene.fog = new THREE.FogExp2 0x000000, 0.00025 
	renderer.setSize w.innerWidth, w.innerHeight
	document.body.appendChild renderer.domElement

	ball_geo = new THREE.IcosahedronGeometry 0.6, 1
	cube_geo = new THREE.CubeGeometry 1, 1, 1
	tetra_geo = new THREE.SphereGeometry 1, 3, 2
	getWireMat = (col) ->
		color = col or 0xFFFF00
		new THREE.MeshBasicMaterial color: color, opacity: 0.5, wireframe: true, wireframeLinewidth: 2

	getSolidMat = (col) ->
		color = col or 0xFFFF00
		new THREE.MeshBasicMaterial color: color, opacity: 1.0, wireframe: false

	getGreyMat =  ->
		new THREE.MeshBasicMaterial color: 0xFFFFFF, opacity: 0.2, wireframe: false
	geos = [ball_geo, cube_geo, tetra_geo]
	mats = [getGreyMat(), new THREE.MeshNormalMaterial(), getWireMat(0x00ff00)]
	
	objects = []
	mesh_scale = 300

	grid_size = 10
	num_boxes = Math.pow grid_size, 3
	time_inc = 0
	max_dist = 4000
	i = 0
	getMesh = (n) ->

		rand = Math.random() * 100
		inc = Math.floor Math.random() * geos.length
		getPosition = ->
			x: (n % grid_size * mesh_scale) - 1250
			y: (Math.floor(n * (1 / grid_size)) % grid_size * mesh_scale) - 1250
			z: (Math.floor(n * 1 / Math.pow(grid_size, 2)) * -mesh_scale) + 1250
		getRGB = ->
			x: (n % grid_size) * (1 / grid_size + 0.1)
			y: (Math.floor(n * (1 / grid_size)) % grid_size) * (1 / grid_size + 0.1)
			z: (Math.floor(n * 1 / Math.pow(grid_size, 2))) * (1 / grid_size + 0.1)

		col = do getRGB

		geometry = cube_geo
		material = getSolidMat()
		material.color.setRGB col.x, col.y, col.z
		mesh = new THREE.Mesh geometry, material
		
		mesh.position = do getPosition
		mesh.scale.x = mesh.scale.y = mesh.scale.z = 40

		rate = Math.random() * 0.03 + 0.0
		anim = (n) ->
			mult = Math.max Math.sin(@col.x + @col.z + n), 0.01
			@mesh.scale.x = @mesh.scale.y = @mesh.scale.z = mult * 160
			@material.color.setHSL 1 - mult, 1.0, 0.5

		obj = 
			mesh: mesh
			anim: anim
			n: n
			col: col
			material: material

	while i < num_boxes
		obj = getMesh i

		objects.push obj
		scene.add obj.mesh
		i += 1

	camera.position.z = 3200
	camera.position.y = 2000

	onKeyUp = (evnt) ->
		console.log evt.keyCode
		return

	renderFrame = ->
		requestAnimationFrame renderFrame
		if ctrls.use_turntable is true
            camera.position.z -= (camera.position.z - 3800 * Math.sin(time_inc * 0.1) ) * 0.03
            camera.position.x -= (camera.position.x - 3800 * Math.cos(time_inc * 0.1) ) * 0.03
            camera.lookAt(scene.position)
        else
            controls.update()

		time_inc += 0.02
		for obj in objects
			obj.anim time_inc

		do renderer.clear
		renderer.render scene, camera 

	
	renderFrame()
	document.addEventListener 'keyup', onKeyUp, false 

