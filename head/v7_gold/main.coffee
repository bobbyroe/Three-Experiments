do ->
	scene = new THREE.Scene()
	camera = new THREE.PerspectiveCamera 60, window.innerWidth/window.innerHeight, 0.1, 20000
	renderer = new THREE.WebGLRenderer()
	controls = new THREE.TrackballControls camera 
	postprocessing = enabled:false 
	log = console.log.bind console
	counter = 0

	controls.rotateSpeed = 1.0
	controls.zoomSpeed = 1.2
	controls.panSpeed = 0.8
	controls.noZoom = false
	controls.noPan = false
	controls.staticMoving = true
	controls.dynamicDampingFactor = 0.3
	controls.keys = [ 65, 83, 68 ] # A, S, D

	scene.fog = new THREE.FogExp2 0x552200, 0.0001 
	renderer.setSize window.innerWidth, window.innerHeight
	document.body.appendChild renderer.domElement
	document.addEventListener 'keyup', onKeyUp, false 

	loader = new THREE.OBJLoader()
	head_geo = null

	getPhongMat = ->

		# environment reflection map
		path = "images/"
		format = '.jpg'
		urls = [
			path + 'disturb3a' + format, path + 'disturb3a' + format,
			path + 'disturb3a' + format, path + 'disturb3a' + format,
			path + 'disturb3a' + format, path + 'disturb3a' + format
		]
		texture_cube = THREE.ImageUtils.loadTextureCube( urls ) # new THREE.CubeRefractionMapping()

		# bump map
		map_height = THREE.ImageUtils.loadTexture( "images/bump.jpg" );

		map_height.anisotropy = 4
		map_height.repeat.set 0.998, 0.998
		map_height.offset.set 0.001, 0.001

		map_height.wrapS = map_height.wrapT = THREE.RepeatWrapping
		map_height.format = THREE.RGBFormat

		options =
			envMap: texture_cube
			bumpMap: map_height
			# ambient: 0xFF0000
			color: 0xFFFFFF
			specular: 0xFFFFFF
			shininess: 30
			bumpScale: 1.5
			emissive: 0x552200
			shading: THREE.SmoothShading

		new THREE.MeshPhongMaterial options

	objects = []

	max_dist = 6000
	mesh_scale = 400
	i = 0
	getMesh = (n) ->
		geometry = head_geo 
		material = getPhongMat() # refracto_mat
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
		
		obj = getMesh i

		objects.push obj
		scene.add obj.mesh
		renderFrame()
		return

	getBoxMat = ->
		path = "../../z_images/"
		format = '.png'
		urls = [
			path + 'checkers' + format, path + 'checkers' + format,
			path + 'checkers' + format, path + 'checkers' + format,
			path + 'checkers' + format, path + 'checkers' + format
		]

		texture_cube = THREE.ImageUtils.loadTextureCube( urls, new THREE.CubeRefractionMapping() )

		shader = THREE.ShaderLib[ "cube" ]
		shader.uniforms[ "tCube" ].value = texture_cube

		new THREE.ShaderMaterial
			fragmentShader: shader.fragmentShader,
			vertexShader: shader.vertexShader,
			uniforms: shader.uniforms,
			depthWrite: false,
			side: THREE.BackSide

	box_mesh = new THREE.Mesh(new THREE.CubeGeometry( 10000, 10000, 10000 ), getBoxMat())
	scene.add box_mesh

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


	# sunlighthelper = new THREE.DirectionalLightHelper sunlight, 2, 1
	# bouncelighthelper = new THREE.DirectionalLightHelper bouncelight, 2, 1
	# rimlighthelper = new THREE.DirectionalLightHelper rimlight, 2, 1
	# scene.add rimlighthelper
	# scene.add sunlighthelper
	# scene.add bouncelighthelper

	camera.position.z = 2000
	camera.position.y = 800
	camera.position.x = -1200

	onKeyUp = (evnt) ->
		console.log evt.keyCode
		return

	renderFrame = ->
		requestAnimationFrame renderFrame
		controls.update()

		renderer.clear()
		counter += 0.002
		camera.position.z = 2000 * Math.sin(counter)
		camera.position.x = -2000 * Math.cos(counter)
		camera.lookAt(scene.position)
		renderer.render scene, camera 


	parseQueryString = (url_frag) ->
	    url_bits = url_frag.split('?')
	    q_string = url_bits[1] || 'obj=asaro_04a'

	    q_string.split('=')[1] + '.obj'

	url_string = '' + window.location
	model_string = parseQueryString url_string
	preloadAssets = ->
		loader.load "../../z_objs/#{model_string}", (obj) ->
			log obj
			head_geo = obj.children[0].geometry
			init()
			return
		return

	preloadAssets()
		
	
	
