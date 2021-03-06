// Generated by CoffeeScript 1.7.1
(function() {
  var App, w;
  w = window;
  App = {
    camera: new THREE.PerspectiveCamera(75, w.innerWidth / w.innerHeight, 1, 10000),
    controls: null,
    scene: new THREE.Scene(),
    renderer: new THREE.WebGLRenderer(),
    cubes: [],
    init: function() {
      this.camera.position.z = 100;
      this.controls = new THREE.TrackballControls(this.camera);
      this.createSomeGeo();
      this.scene.fog = new THREE.Fog(0x000000, 40, 240);
      this.renderer.setSize(w.innerWidth, w.innerHeight);
      document.body.appendChild(this.renderer.domElement);
      return window.app = this;
    },
    createSomeGeo: function() {
      var c, colors, cube_width, g, geo, group, mat, mesh, num_cubes, num_groups, num_shapes, rand_color, s, shape;
      colors = [0xff0000, 0xff9900, 0xffff00, 0x99ff00, 0x00ff00, 0x00CCff, 0x0000ff, 0x9900ff];
      cube_width = 10;
      num_shapes = 2;
      s = 0;
      while (s < num_shapes) {
        shape = new THREE.Object3D();
        num_groups = 12;
        g = 0;
        while (g < num_groups) {
          group = new THREE.Object3D();
          num_cubes = 8;
          c = 0;
          while (c < num_cubes) {
            rand_color = Math.floor(Math.random() * colors.length);
            geo = new THREE.CubeGeometry(cube_width, cube_width, cube_width);
            mat = new THREE.MeshBasicMaterial({
              color: colors[c],
              wireframe: false
            });
            mesh = new THREE.Mesh(geo, mat);
            mesh.position.y = c * (cube_width + 0) + cube_width;
            mesh.scale.x = mesh.scale.y = mesh.scale.z = c * 0.4;
            group.add(mesh);
            this.cubes.push(mesh);
            c += 1;
          }
          group.rotation.z = g * -(Math.PI / 180) * 30;
          shape.add(group);
          g += 1;
        }
        shape.rotation.y = (s * (Math.PI / 180) * 90) - 45;
        this.scene.add(shape);
        s += 1;
      }
    },
    animate: function() {
      var cube, _i, _len, _ref;
      requestAnimationFrame(this.animate.bind(this));
      _ref = this.cubes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cube = _ref[_i];
        cube.position.y += ((80 - cube.position.y) * 0.01) + 0.1;
        cube.position.x = Math.sin(cube.position.y * 0.1) * (80 - cube.position.y) * 0.1;
        cube.scale.x = cube.scale.y = cube.scale.z = (80 - cube.position.y) * 0.01;
        if (cube.position.y > 80) {
          cube.position.y = 0;
        }
      }
      this.controls.update();
      return this.renderer.render(this.scene, this.camera);
    }
  };
  App.init();
  App.animate();
})();

/*
//@ sourceMappingURL=main.map
*/
