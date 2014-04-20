do ->
	w = window

	App = 
		camera: new THREE.PerspectiveCamera 75, w.innerWidth / w.innerHeight, 1, 10000
		controls: null
		scene: new THREE.Scene()
		# mesh: null
		renderer: new THREE.WebGLRenderer()
		cubes: []

		init: ->
			# geometry = new THREE.CubeGeometry 20, 20, 20 
			# material = new THREE.MeshBasicMaterial { color: 0xff0000, wireframe: false } 

			@camera.position.z = 100
			@controls = new THREE.TrackballControls @camera 
			# @mesh = new THREE.Mesh geometry, material
			# @scene.add @mesh 
			do @createSomeGeo
			@scene.fog = new THREE.Fog 0x000000, 40, 240
			@renderer.setSize w.innerWidth, w.innerHeight 

			document.body.appendChild @renderer.domElement

			window.app = @
			# @mesh.rotation.x = 0.5
			# @mesh.rotation.y = -0.5

		createSomeGeo: ->
			colors = [0xff0000, 0xff9900, 0xffff00, 0x99ff00, 0x00ff00, 0x00CCff, 0x0000ff, 0x9900ff]
			cube_width = 10
			num_shapes = 2
			s = 0

			while s < num_shapes
				shape = new THREE.Object3D()
				num_groups = 12
				g = 0
				while g < num_groups
					group = new THREE.Object3D()
					num_cubes = 8
					c = 0
					while c < num_cubes
						rand_color = Math.floor Math.random() * colors.length
						geo = new THREE.CubeGeometry cube_width, cube_width, cube_width 
						mat = new THREE.MeshBasicMaterial { color: colors[c], wireframe: false }
						mesh = new THREE.Mesh geo, mat
						# mesh.position.x = i * cube_width
						mesh.position.y = c * (cube_width + 0) + cube_width
						# mesh.scale.x = mesh.scale.y = mesh.scale.z = Math.random() * 0.8 + 0.2
						mesh.scale.x = mesh.scale.y = mesh.scale.z = (c) * 0.4
						group.add mesh
						@cubes.push(mesh)
						c += 1
					group.rotation.z = g * -(Math.PI / 180) * 30
					shape.add group
					g += 1
				shape.rotation.y = (s * (Math.PI / 180) * 90) - 45
				@scene.add shape
				s += 1
			return


		animate: ->
			requestAnimationFrame @animate.bind @ # note: three.js includes requestAnimationFrame shim

			for cube in @cubes
				cube.position.y += ((80 - cube.position.y) * 0.01) + 0.1
				cube.position.x = Math.sin(cube.position.y * 0.1) * (80 - cube.position.y) * 0.1
				cube.scale.x = cube.scale.y = cube.scale.z = (80 - cube.position.y) * 0.01
				if cube.position.y > 80 then cube.position.y = 0

			do @controls.update
			@renderer.render @scene, @camera

	do App.init
	do App.animate
	return