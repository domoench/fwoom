// Generated by CoffeeScript 1.6.3
/*

  Fwoom! A WebGL game by David Moench
*/


(function() {
  var DMOENCH;

  DMOENCH = DMOENCH || {};

  DMOENCH.Fwoom = new function() {
    var $container, BODYTYPE, Body, FPMS, HEIGHT, HERO_ENGINE_FORCE, Manifold, WIDTH, bbIntersects, bodies, camera, collideWall, detectBodyCollisions, handleCollisions, handleKeyDown, handleKeyUp, handleKeys, hero, initObjects, keys_down, render, renderer, resolveBodyCollisions, scene, sign, time_last, updateBodies;
    WIDTH = 800;
    HEIGHT = 600;
    HERO_ENGINE_FORCE = 400;
    BODYTYPE = {
      hero: 0,
      hunter: 1,
      rock: 2
    };
    Object.freeze(BODYTYPE);
    FPMS = 60 / 1000;
    camera = null;
    scene = null;
    renderer = null;
    $container = $('#container');
    bodies = [null, null];
    hero = null;
    time_last = 0;
    keys_down = {};
    /*
      Initialize and start the game
    */

    this.init = function() {
      initObjects();
      document.onkeydown = handleKeyDown;
      document.onkeyup = handleKeyUp;
      render();
      return null;
    };
    /*
      Create WebGL renderer, camera, and a scene.
    */

    initObjects = function() {
      var aspect, far, hero_mat, hero_mesh, near, pointLight, rad_segs, radius, rock, rock_mat, rock_mesh, view_angle;
      renderer = new THREE.WebGLRenderer();
      scene = new THREE.Scene();
      view_angle = 90;
      aspect = WIDTH / HEIGHT;
      near = 0.1;
      far = 10000;
      camera = new THREE.PerspectiveCamera(view_angle, aspect, near, far);
      camera.position.z = 300;
      renderer.setSize(WIDTH, HEIGHT);
      $container.append(renderer.domElement);
      pointLight = new THREE.PointLight(0xFFFFFF);
      pointLight.position.set(100, -250, 130);
      radius = 20;
      rad_segs = 64;
      hero_mat = new THREE.MeshLambertMaterial({
        color: 0xCC0000
      });
      hero_mesh = new THREE.Mesh(new THREE.CircleGeometry(radius, rad_segs), hero_mat);
      hero_mesh.position.set(0, 0, 0);
      hero = new Body('hero', 1.0, new THREE.Vector3(0), 300, hero_mesh);
      bodies[0] = hero;
      radius = 30;
      rad_segs = 64;
      rock_mat = new THREE.MeshLambertMaterial({
        color: 0xFFFF00
      });
      rock_mesh = new THREE.Mesh(new THREE.CircleGeometry(radius, rad_segs), rock_mat);
      rock_mesh.position.set(-100, 0, 0);
      rock = new Body('rock', 0.0, new THREE.Vector3(0), 0, rock_mesh);
      bodies[1] = rock;
      scene.add(pointLight);
      _.each(bodies, function(body) {
        return scene.add(body.mesh);
      });
      scene.add(camera);
      return null;
    };
    /*
      Move each body for the next frame according to its current velocity and
      the net force acting on it.
    */

    updateBodies = function(delta) {
      _.each(bodies, function(body) {
        return body.update(delta);
      });
      return null;
    };
    /*
      Render Loop: Update scene, render it, and request next iteration
    */

    render = function() {
      var delta, time_now;
      time_now = new Date().getTime();
      if (time_last !== 0) {
        delta = (time_now - time_last) / 1000;
        handleKeys();
        handleCollisions(delta);
        updateBodies(delta);
      }
      time_last = time_now;
      renderer.render(scene, camera);
      requestAnimationFrame(render);
      return null;
    };
    /*
      Detect and resolve collisions between all bodies.
    */

    handleCollisions = function(delta) {
      var collisions;
      _.each(bodies, function(body) {
        return collideWall(body);
      });
      collisions = detectBodyCollisions(delta);
      resolveBodyCollisions(delta, collisions);
      return null;
    };
    /*
      Detect collisions between bodies in the scene and generate a manifold
      object for each collision
    
      Returns a list of manifold objects
    */

    detectBodyCollisions = function(delta) {
      var candidates;
      candidates = [];
      _.each(bodies, function(a) {
        _.each(bodies, function(b) {
          if (a !== b && bbIntersects(a, b)) {
            candidates[candidates.length] = new Manifold(a, b);
          }
          return null;
        });
        return null;
      });
      return candidates;
    };
    /*
      Determine if the bounding boxes of bodies A and B intersect.
    */

    bbIntersects = function(a, b) {
      var a_BB, b_BB, x_intersect, y_intersect;
      a.mesh.geometry.computeBoundingBox();
      b.mesh.geometry.computeBoundingBox();
      a_BB = a.mesh.geometry.boundingBox;
      b_BB = b.mesh.geometry.boundingBox;
      a_BB.min.add(a.mesh.position);
      a_BB.max.add(a.mesh.position);
      b_BB.min.add(b.mesh.position);
      b_BB.max.add(b.mesh.position);
      x_intersect = (a_BB.min.x <= b_BB.max.x) && (a_BB.max.x >= b_BB.min.x);
      y_intersect = (a_BB.min.y <= b_BB.max.y) && (a_BB.max.y >= b_BB.min.y);
      return x_intersect && y_intersect;
    };
    /*
      Resolve collisions between bodies in the scene.
    */

    resolveBodyCollisions = function(delta, collisions) {
      return null;
    };
    /*
      Check if BODY is colliding with a screen boundary, and if so reverse its
      velocity to bounce. Bouncing off the wall is perfectly elastic.
    */

    collideWall = function(body) {
      if (Math.abs(body.mesh.position.x) > WIDTH / 2 - body.mesh.geometry.radiusTop) {
        body.vel.x *= -1;
      }
      if (Math.abs(body.mesh.position.y) > HEIGHT / 2 - body.mesh.geometry.radiusTop) {
        body.vel.y *= -1;
      }
      return null;
    };
    /*
      Calculate the sign of N. Return 1 if positive, -1 if negative
    */

    sign = function(n) {
      if (n >= 0) {
        return 1;
      } else {
        return -1;
      }
    };
    /*
      Record key press down in keys_down dictionary
    */

    handleKeyDown = function(event) {
      return keys_down[event.keyCode] = true;
    };
    /*
      Record key let up in keys_down dictionary
    */

    handleKeyUp = function(event) {
      return keys_down[event.keyCode] = false;
    };
    /*
      Handle user input based on state of keys_down dictionary
    */

    handleKeys = function() {
      if (keys_down[37]) {
        hero.force.setX(hero.force.x - HERO_ENGINE_FORCE);
      }
      if (keys_down[38]) {
        hero.force.setY(hero.force.y + HERO_ENGINE_FORCE);
      }
      if (keys_down[39]) {
        hero.force.setX(hero.force.x + HERO_ENGINE_FORCE);
      }
      if (keys_down[40]) {
        return hero.force.setY(hero.force.y - HERO_ENGINE_FORCE);
      }
    };
    /*
      Bodies are the physical entities in the scene.
    */

    Body = (function() {
      function Body(name, mass, vel, max_vel, mesh) {
        this.name = name;
        this.mass = mass || 0;
        this.vel = vel || new THREE.Vector3(0);
        this.mesh = mesh || null;
        this.max_vel = max_vel || 0;
      }

      Body.prototype.force = new THREE.Vector3(0);

      Body.prototype.update = function(delta) {
        var dv, dxy;
        if (this.mass === 0) {
          return null;
        }
        dv = this.force.clone();
        dv.divideScalar(this.mass);
        dv.multiplyScalar(delta);
        this.vel.add(dv);
        if (this.vel.length() > this.max_vel) {
          this.vel.sub(dv);
        }
        dxy = this.vel.clone();
        dxy.multiplyScalar(delta);
        this.mesh.position.add(dxy);
        this.force.set(0, 0, 0);
        return null;
      };

      return Body;

    })();
    /*
      Manifolds are objects packaging up information about a collision that
      needs resolving.
    */

    Manifold = (function() {
      function Manifold(a, b) {
        this.a = a;
        this.b = b;
      }

      Manifold.prototype.penetration = 0.0;

      Manifold.prototype.normal = new THREE.Vector3(0);

      return Manifold;

    })();
    return null;
  };

  $(function() {
    return DMOENCH.Fwoom.init();
  });

  this.DMOENCH = DMOENCH;

}).call(this);
