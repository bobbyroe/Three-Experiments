###
    A THREE.js experiment 2014 by http://bobbyroe.com
###
log = console.log.bind console
do ->
    SCREEN_HEIGHT = window.innerHeight
    SCREEN_WIDTH = window.innerWidth

    camera = null
    controls = null
    scene = null
    renderer = null
    mesh = null
    directionalLight = null
    parent = null
    meshes = []
    p = null
    bloader = null
    clock = new THREE.Clock()
    noise_mat = null
    start = Date.now()
    mouse = x: 0, y: 0

    init = ->
        camera = new THREE.PerspectiveCamera( 20, SCREEN_WIDTH / SCREEN_HEIGHT, 1, 50000 )
        camera.position.set( 100, 100, 100 )
        window.camera = camera
        scene = new THREE.Scene()
        # scene.fog = new THREE.FogExp2 0x000000, 0.0025
        parent = new THREE.Object3D()
        scene.add parent

        camera.lookAt( scene.position )

        controls = new THREE.TrackballControls camera
        controls.rotateSpeed = 1.0
        controls.zoomSpeed = 1.2
        controls.panSpeed = 0.8
        controls.noZoom = false
        controls.noPan = false
        controls.staticMoving = true
        controls.dynamicDampingFactor = 0.3
        controls.keys = [ 65, 83, 68 ] # A, S, D

        getLambertMat =  ->
            new THREE.MeshLambertMaterial color: 0xe0e0e0, opacity: 1.0, wireframe: true
        
        getWireMat = (col = 0x004488) ->
            new THREE.MeshBasicMaterial color: col, wireframe: true, wireframeLinewidth: 1

        ball_geo = new THREE.IcosahedronGeometry 20, 6

        extractNormals = (geo) ->
            vertex_normals = []
            for face in geo.faces
                vertex_normals[face.a] = face.vertexNormals[0]
                vertex_normals[face.b] = face.vertexNormals[1]
                vertex_normals[face.c] = face.vertexNormals[2]

            vertex_normals
                
        # log extractNormals ball_geo
        shader_uniforms =
            tExplosion:  # texture in slot 0, loaded with ImageUtils
                type: "t"
                value: THREE.ImageUtils.loadTexture 'explosion.png'
            
            time: # float initialized to 0
                type: "f"
                value: 0.0
            disp:
                type: 'f'
                value: 10.0

        shader_attrs =
            vNormal:
                type: 'v3'
                value: []
            vColor:
                type: 'f'
                value: []

        noise_mat = new THREE.ShaderMaterial
            uniforms: shader_uniforms
            attributes: shader_attrs
            vertexShader: document.getElementById( 'vert' ).textContent,
            fragmentShader: document.getElementById( 'frag' ).textContent

        shader_mat = new THREE.ShaderMaterial
            # uniforms: 
            #     time: # float initialized to 0
            #         type: "f"
            #         value: 0.0
            attributes: shader_attrs
                    
            vertexShader: document.getElementById( 'vs' ).textContent,
            fragmentShader: document.getElementById( 'fs' ).textContent

        shader_attrs.vNormal.value = extractNormals ball_geo


        
            
        # ball_mats_array = [ noise_mat, getWireMat() ]
        
        # ball = new THREE.Mesh ball_geo, noise_mat
        # ball = new THREE.SceneUtils.createMultiMaterialObject  ball_geo, ball_mats_array
        # ball.position.x = 0
        # ball.position.y = -5
        # ball.position.z = 0
        # ball.scale.x = ball.scale.y = ball.scale.z = 10
        # parent.add ball
        # parent.add new THREE.VertexNormalsHelper ball, 3


        # PARTICLES
        # p_geo = new THREE.Geometry() 
        # p_geo.vertices = ball_geo.vertices

        # log ball_geo

        # temp_mat = new THREE.ParticleSystemMaterial color: 0xFF9900, size: 0.1
        # particles = new THREE.ParticleSystem p_geo, shader_mat
        particles = new THREE.ParticleSystem ball_geo, noise_mat
        parent.add particles
        #
        renderer = new THREE.WebGLRenderer( { antialias: false } )
        renderer.setSize( SCREEN_WIDTH, SCREEN_HEIGHT )
        # renderer.autoClear = false
        # renderer.sortObjects = false
        renderer.context.getProgramInfoLog = -> '' # silence the warnings
        document.body.appendChild( renderer.domElement )
        #

        # lights
        # sunlight = new THREE.DirectionalLight 0xffffdd, 1.0
        # bouncelight = new THREE.DirectionalLight 0xddffff, 0.2
        # rimlight = new THREE.DirectionalLight 0xddffff, 2.0
        # sunlight.position.set( 1, 1, 1 )
        # bouncelight.position.set( 1, -1, -1 )
        # rimlight.position.set( 0, 0.5, -1 )
        # scene.add(rimlight)
        # scene.add(sunlight)
        # scene.add(bouncelight)

        window.addEventListener( 'resize', onWindowResize, false )
        animate()

    #
    onWindowResize = (evt) ->
        renderer.setSize SCREEN_WIDTH, SCREEN_HEIGHT 

        camera.aspect = SCREEN_WIDTH / SCREEN_HEIGHT
        camera.updateProjectionMatrix()

        camera.lookAt scene.position
        return

    onMouseMoved = (evt) ->
        mouse = 
            x: Math.abs(evt.clientX - SCREEN_WIDTH * 0.5) * -0.05
            y: Math.abs(evt.clientY - SCREEN_HEIGHT * 0.5) * -0.05

    animate = ->
        requestAnimationFrame( animate )
        render()
        return

    render = ->
        delta = 10 * clock.getDelta()
        delta = delta < 2 ? delta : 2
        parent.rotation.y += -0.005 * delta

        noise_mat.uniforms[ 'time' ].value = 0.00025 * ( Date.now() - start )
        noise_mat.uniforms[ 'disp' ].value = (mouse.x + mouse.y) * 0.5

        renderer.render(scene, camera)
        controls.update()
        return

    document.addEventListener "DOMContentLoaded", init
    document.addEventListener "mousemove", onMouseMoved
    return

    

