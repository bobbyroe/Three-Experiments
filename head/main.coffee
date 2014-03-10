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

	scene.fog = new THREE.FogExp2 0x00ccFF, 0.0001 
	renderer.setSize w.innerWidth, w.innerHeight
	document.body.appendChild renderer.domElement
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

	refracto_mat = getRefractoBlurredMat()
	color_mat = getRefractoMat()

	geos = [cube_geo, tetra_geo]
	mats = [getGreyMat(), new THREE.MeshNormalMaterial(), getWireMat(0x00ff00)]
	
	objects = []

	# lights
	sunlight = new THREE.DirectionalLight 0xffffdd, 1.0
	bouncelight = new THREE.DirectionalLight 0xddffff, 0.2
	rimlight = new THREE.DirectionalLight 0xddffff, 2.0
	max_dist = 6000
	mesh_scale = 400
	i = 0
	getMesh = (n) ->

		rand = Math.random() * 100
		inc = Math.floor Math.random() * geos.length
		geometry = head_geo
		material = refracto_mat
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
		anim = ->
			randa = Math.random() * 1000
			if randa < 1 then goal_pos = do getPosition
			@mesh.rotation.y += rate
			@mesh.position.x -= (@mesh.position.x - goal_pos.x) * move_rate
			@mesh.position.y -= (@mesh.position.y - goal_pos.y) * move_rate
			@mesh.position.z -= (@mesh.position.z - goal_pos.z) * move_rate

		obj = 
			mesh: mesh
			anim: anim

	init = ->
		while i < 1
			obj = getMesh i

			objects.push obj
			scene.add obj.mesh
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

	renderFrame = ->
		requestAnimationFrame renderFrame

		if ctrls.use_turntable is true
			counter += 0.002
			camera.position.z -= (camera.position.z - 2000 * Math.sin(counter) ) * 0.01
			camera.position.x -= (camera.position.x - 2000 * Math.cos(counter) ) * 0.01
			camera.lookAt(scene.position)
		else
			controls.update()

		renderer.clear()
		renderer.render scene, camera 

	preloadAssets = ->
		loader.load '../z_objs/asaro_03.obj', (obj) ->
			log obj
			head_geo = obj.children[0].geometry
			init()
			return
		return

	preloadAssets()
		
	
	
