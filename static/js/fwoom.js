// Generated by CoffeeScript 1.6.3
/*

  Fwoom! A WebGL game by David Moench
*/


(function() {
  var DMOENCH,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DMOENCH = DMOENCH || {};

  DMOENCH.Fwoom = new function() {
    var $container, BODYTYPE, Blob, Body, Fwoom, HEIGHT, HERO_ENGINE_FORCE, Hero, Manifold, MeshBody, Particle, Rock, WIDTH, applyFwoomToBodies, bbIntersects, bodies, camera, circleCircleCollide, clearExpiredFwooms, collideWall, detectBodyCollisions, fwooms, handleCollisions, handleFwooms, handleKeyDown, handleKeyUp, handleKeys, hero, initObjects, keys_down, particle_sys, particles, render, renderer, resolveBodyCollision, resolveBodyCollisions, scene, sign, time_last, updateBodies, _ref, _ref1, _ref2;
    WIDTH = 960;
    HEIGHT = 630;
    HERO_ENGINE_FORCE = 1500;
    BODYTYPE = {
      hero: 0,
      blob: 1,
      rock: 2
    };
    Object.freeze(BODYTYPE);
    camera = null;
    scene = null;
    renderer = null;
    $container = $('#container');
    bodies = [];
    particles = [];
    particle_sys = null;
    fwooms = [];
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
      var attributes, bg_mesh, bg_texture, blob, blob_density, blob_geom, blob_mass, blob_mat, blob_mesh, blob_radius, blob_segs, blob_shader, blob_uniforms, blob_verts, hero_bump_map, hero_density, hero_geom, hero_mass, hero_mat, hero_mesh, hero_radius, hero_segs, i, max_vel, num_particles, part_mat, part_sprite, particle_pos, particles_geom, pointLight1, pointLight2, rock, rock_geom, rock_mass, rock_mat, rock_mesh, rock_radius, rock_segs, uniforms, x, y, _i;
      renderer = new THREE.WebGLRenderer();
      scene = new THREE.Scene();
      camera = new THREE.OrthographicCamera(WIDTH / -2, WIDTH / 2, HEIGHT / 2, HEIGHT / -2, -10000, 10000);
      camera.position.z = 1500;
      renderer.setSize(WIDTH, HEIGHT);
      $container.append(renderer.domElement);
      pointLight1 = new THREE.PointLight(0xFFFFFF, 1, 2000);
      pointLight1.position.set(0, 0, 600);
      pointLight2 = new THREE.PointLight(0xFF3F3F, 3, 2000);
      pointLight2.position.set(-800, 800, 500);
      hero_radius = 20;
      hero_segs = 64;
      hero_bump_map = THREE.ImageUtils.loadTexture("./img/rocky-normal-small.jpg");
      hero_mat = new THREE.MeshPhongMaterial({
        color: 0x7AB02C,
        bumpMap: hero_bump_map
      });
      hero_geom = new THREE.CircleGeometry(hero_radius, hero_segs);
      hero_mesh = new THREE.Mesh(hero_geom, hero_mat);
      hero_mesh.position.set(0, 0, 0);
      max_vel = 400;
      hero_density = 0.002;
      hero_mass = hero_density * Math.PI * hero_radius * hero_radius;
      hero = new Hero('hero', hero_mass, new THREE.Vector3(0), max_vel, hero_mesh);
      bodies[bodies.length] = hero;
      rock_radius = 40;
      rock_segs = 32;
      rock_mat = new THREE.MeshLambertMaterial({
        color: 0x216477
      });
      rock_geom = new THREE.SphereGeometry(rock_radius, rock_segs, rock_segs);
      rock_mesh = new THREE.Mesh(rock_geom, rock_mat);
      rock_mesh.position.set(-100, 0, 0);
      rock_mass = 0;
      rock = new Rock('rock', rock_mass, new THREE.Vector3(0), 0, rock_mesh);
      bodies[bodies.length] = rock;
      blob_radius = 20;
      blob_segs = 32;
      attributes = {
        displacement: {
          type: 'f',
          value: []
        }
      };
      uniforms = {
        amplitude: {
          type: 'f',
          value: 0
        }
      };
      blob_shader = customShaders['blob'];
      blob_uniforms = THREE.UniformsUtils.clone(blob_shader.uniforms);
      blob_mat = new THREE.ShaderMaterial({
        uniforms: _.extend(blob_uniforms, uniforms),
        attributes: attributes,
        vertexShader: blob_shader.vertexShader,
        fragmentShader: blob_shader.fragmentShader,
        lights: true
      });
      blob_geom = new THREE.SphereGeometry(blob_radius, blob_segs, blob_segs);
      blob_mesh = new THREE.Mesh(blob_geom, blob_mat);
      blob_mesh.position.set(100, 50, 0);
      blob_verts = blob_mesh.geometry.vertices;
      attributes.displacement.value = (function() {
        var _i, _ref, _results;
        _results = [];
        for (i = _i = 0, _ref = blob_verts.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          _results.push(Math.random() * 10);
        }
        return _results;
      })();
      blob_density = 0.002;
      blob_mass = blob_density * Math.PI * blob_radius * blob_radius;
      max_vel = 900;
      blob = new Blob('blob', blob_mass, new THREE.Vector3(80, 40, 0), max_vel, blob_mesh);
      console.log('Blob', blob);
      bodies[bodies.length] = blob;
      num_particles = 300;
      particles_geom = new THREE.Geometry();
      part_sprite = THREE.ImageUtils.loadTexture("img/snowflake1.png");
      part_mat = new THREE.ParticleSystemMaterial({
        color: 0xFFFFFF,
        map: part_sprite,
        size: 20,
        blending: THREE.AdditiveBlending,
        transparent: true
      });
      for (i = _i = 0; 0 <= num_particles ? _i < num_particles : _i > num_particles; i = 0 <= num_particles ? ++_i : --_i) {
        x = Math.random() * WIDTH - WIDTH / 2;
        y = Math.random() * HEIGHT - HEIGHT / 2;
        particle_pos = new THREE.Vector3(x, y, 0.0);
        particles.push(new Particle(i, particle_pos));
        particles_geom.vertices.push(particle_pos);
      }
      particle_sys = new THREE.ParticleSystem(particles_geom, part_mat);
      bg_texture = THREE.ImageUtils.loadTexture('img/space-background.jpg');
      bg_mesh = new THREE.Mesh(new THREE.PlaneGeometry(WIDTH, HEIGHT), new THREE.MeshBasicMaterial({
        map: bg_texture
      }));
      bg_mesh.position.z = -100;
      scene.add(pointLight1);
      scene.add(pointLight2);
      scene.add(particle_sys);
      scene.add(bg_mesh);
      _.each(bodies, function(body) {
        return scene.add(body.mesh);
      });
      scene.add(camera);
      console.log(scene);
      return null;
    };
    /*
      Move each body for the next frame according to its current velocity and
      the net force acting on it.
    */

    updateBodies = function(delta) {
      handleFwooms();
      _.each(bodies, function(body) {
        return body.update(delta);
      });
      _.each(particles, function(particle) {
        return particle.update(delta);
      });
      particle_sys.geometry.verticesNeedUpdate = true;
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
        updateBodies(delta);
        handleCollisions(delta);
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
      _.each(particles, function(particle) {
        return collideWall(particle);
      });
      collisions = detectBodyCollisions(delta);
      resolveBodyCollisions(collisions);
      return null;
    };
    /*
      Detect collisions between bodies in the scene and generate a manifold
      object for each collision
    
      Returns a list of manifold objects
    */

    detectBodyCollisions = function(delta) {
      var a, b, collision, collisions, i, j, n, _i, _j, _ref;
      collisions = [];
      n = bodies.length;
      for (i = _i = 0; 0 <= n ? _i < n : _i > n; i = 0 <= n ? ++_i : --_i) {
        for (j = _j = _ref = i + 1; _ref <= n ? _j < n : _j > n; j = _ref <= n ? ++_j : --_j) {
          a = bodies[i];
          b = bodies[j];
          if (a !== b && bbIntersects(a, b)) {
            collision = circleCircleCollide(a, b);
            if (collision != null) {
              collisions[collisions.length] = collision;
            }
          }
        }
      }
      return collisions;
    };
    /*
      Determine if two circular bodies intersect and generate a manifold object
      for the collision.
    
      Returns:
        A Manifold object OR null if no collision.
    */

    circleCircleCollide = function(a, b) {
      var a_pos, b_pos, collision, d, n, r_sum;
      a_pos = a.getPos();
      b_pos = b.getPos();
      n = b_pos.clone();
      n.sub(a_pos);
      r_sum = a.mesh.geometry.radius + b.mesh.geometry.radius;
      d = n.length();
      if (d > r_sum) {
        return null;
      }
      collision = new Manifold(a, b);
      if (d !== 0) {
        collision.penetration = r_sum - d;
        n.normalize();
        collision.normal = n;
      } else {
        collision.penetration = a.mesh.geometry.radius;
        collision.normal = new THREE.Vector3(1, 0, 0);
      }
      return collision;
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
      a_BB.min.add(a.getPos());
      a_BB.max.add(a.getPos());
      b_BB.min.add(b.getPos());
      b_BB.max.add(b.getPos());
      x_intersect = (a_BB.min.x <= b_BB.max.x) && (a_BB.max.x >= b_BB.min.x);
      y_intersect = (a_BB.min.y <= b_BB.max.y) && (a_BB.max.y >= b_BB.min.y);
      return x_intersect && y_intersect;
    };
    /*
      Resolve all collisions between bodies in the scene specified by the list of
      Manifold objects.
    */

    resolveBodyCollisions = function(collisions) {
      if (collisions.length === 0) {
        return;
      }
      _.each(collisions, function(collision) {
        return resolveBodyCollision(collision);
      });
      return null;
    };
    /*
      Resolve a single collision between 2 bodies, updating their velocities as
      appropriate.
    */

    resolveBodyCollision = function(collision) {
      var a, a_diff, a_inv_mass, a_mass_ratio, b, b_diff, b_inv_mass, b_mass_ratio, imp, imp_vect, mass_sum, rest, rv, rv_n;
      a = collision.a;
      b = collision.b;
      a_inv_mass = a.mass === 0 ? 0 : 1 / a.mass;
      b_inv_mass = b.mass === 0 ? 0 : 1 / b.mass;
      mass_sum = a.mass + b.mass;
      a_mass_ratio = a.mass / mass_sum;
      b_mass_ratio = 1.0 - a_mass_ratio;
      rv = new THREE.Vector3(0);
      rv.subVectors(b.vel, a.vel);
      rv_n = rv.dot(collision.normal);
      if (rv_n > 0) {
        return;
      }
      rest = 0.85;
      imp = -(1 + rest) * rv_n;
      imp /= a_inv_mass + b_inv_mass;
      imp_vect = collision.normal.clone();
      imp_vect.multiplyScalar(imp);
      a_diff = imp_vect.clone();
      a_diff.multiplyScalar(a_inv_mass);
      a.vel.sub(a_diff);
      b_diff = imp_vect.clone();
      b_diff.multiplyScalar(b_inv_mass);
      b.vel.add(b_diff);
      return null;
    };
    /*
      Check if BODY is colliding with a screen boundary, and if so reverse its
      velocity to bounce. Bouncing off the wall is perfectly elastic.
    */

    collideWall = function(body) {
      var pos;
      pos = body.getPos();
      if (body instanceof MeshBody) {
        if (Math.abs(pos.x) > WIDTH / 2 - body.mesh.geometry.radius) {
          body.vel.x *= -1;
        }
        if (Math.abs(pos.y) > HEIGHT / 2 - body.mesh.geometry.radius) {
          body.vel.y *= -1;
        }
      } else if (body instanceof Particle) {
        if (Math.abs(pos.x) > WIDTH / 2) {
          body.vel.x *= -1;
        }
        if (Math.abs(pos.y) > HEIGHT / 2) {
          body.vel.y *= -1;
        }
      }
      return null;
    };
    /*
      Apply any existing fwoom forces to bodies in the scene
    */

    handleFwooms = function() {
      if (fwooms.length === 0) {
        return;
      }
      _.each(fwooms, function(fwoom) {
        applyFwoomToBodies(fwoom, bodies);
        return applyFwoomToBodies(fwoom, particles);
      });
      return clearExpiredFwooms();
    };
    applyFwoomToBodies = function(fwoom, bodies) {
      _.each(bodies, function(body) {
        var d, dist_vect, force_vect;
        if (body === hero) {
          return;
        }
        dist_vect = new THREE.Vector3(0);
        dist_vect.subVectors(body.getPos(), fwoom.pos);
        d = dist_vect.length();
        if (d < fwoom.radius) {
          force_vect = dist_vect.clone();
          force_vect.normalize();
          force_vect.multiplyScalar(fwoom.power / d);
          body.force.add(force_vect);
        }
        return null;
      });
      return null;
    };
    /*
      Clear any expired fwooms
    */

    clearExpiredFwooms = function() {
      var time_now;
      time_now = new Date().getTime();
      if (time_now > fwooms[0].death_time) {
        fwooms.shift();
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
      Record key press down in keys_down dictionary and handle one-off keys.
    */

    handleKeyDown = function(event) {
      keys_down[event.keyCode] = true;
      if (event.keyCode === 32) {
        return fwooms.push(new Fwoom(150, 400000, hero.getPos()));
      }
    };
    /*
      Record key let up in keys_down dictionary
    */

    handleKeyUp = function(event) {
      return keys_down[event.keyCode] = false;
    };
    /*
      Handle user input based on state of keys_down dictionary. This applies to
      keys pressed over durations.
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
      Bodies represent physical entities in the scene. They package physics
      properties with rendering properties.
    */

    Body = (function() {
      function Body(name, mass, vel, max_vel) {
        this.name = name;
        this.mass = mass || 0;
        this.vel = vel || new THREE.Vector3(0);
        this.max_vel = max_vel || 0;
        this.force = new THREE.Vector3(0);
      }

      /*
        Update's this Body's velocity based on its physical properties and the
        forces acting on it.
      
        Args:
          delta: {Number} Time delta since last frame. TODO: Necessary?
        Return:
          null
      */


      Body.prototype.update = function(delta) {
        var dv;
        if (this.mass === 0) {
          return null;
        }
        dv = this.force.clone();
        dv.divideScalar(this.mass);
        dv.multiplyScalar(delta);
        this.vel.add(dv);
        this.force.set(0, 0, 0);
        return null;
      };

      return Body;

    })();
    /*
      MeshBody is a Body subclass that maintains threejs rendering info via a
      Mesh.
    */

    MeshBody = (function(_super) {
      __extends(MeshBody, _super);

      function MeshBody(name, mass, vel, max_vel, mesh) {
        this.mesh = mesh || null;
        MeshBody.__super__.constructor.call(this, name, mass, vel, max_vel);
      }

      /*
        Updates this MeshBody's velocity and position based on its physical
        properties and the forces acting on it.
      
        Args:
          delta: {Number} Time delta since last frame. TODO: Necessary?
        Return:
          null
      */


      MeshBody.prototype.update = function(delta) {
        var dxy;
        MeshBody.__super__.update.call(this, delta);
        dxy = this.vel.clone();
        dxy.multiplyScalar(delta);
        return this.mesh.position.add(dxy);
      };

      /*
        Return a reference to this MeshBody's position vector
      */


      MeshBody.prototype.getPos = function() {
        return this.mesh.position;
      };

      return MeshBody;

    })(Body);
    Blob = (function(_super) {
      __extends(Blob, _super);

      function Blob() {
        _ref = Blob.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      /*
        Updates this Body's velocity and position and animates its normals.
      
        Args:
          delta: {Number} Time delta since last frame. TODO: Necessary?
        Return:
          null
      */


      Blob.prototype.update = function(delta) {
        Blob.__super__.update.call(this, delta);
        return this.mesh.material.uniforms.amplitude.value = Math.sin(new Date().getMilliseconds() / 300);
      };

      return Blob;

    })(MeshBody);
    Hero = (function(_super) {
      __extends(Hero, _super);

      function Hero() {
        _ref1 = Hero.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      return Hero;

    })(MeshBody);
    Rock = (function(_super) {
      __extends(Rock, _super);

      function Rock() {
        _ref2 = Rock.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      return Rock;

    })(MeshBody);
    Particle = (function(_super) {
      __extends(Particle, _super);

      /*
        Create a particle with a random position
      
        Args:
          pos: A reference to the position object within a threejs Particle
               instance
      */


      function Particle(name, pos) {
        var mass, max_vel, vel, x_vel, y_vel;
        this.pos = pos;
        mass = 8;
        max_vel = 35;
        x_vel = Math.random() * max_vel - max_vel / 2;
        y_vel = Math.random() * max_vel - max_vel / 2;
        vel = new THREE.Vector3(x_vel, y_vel, 0.0);
        Particle.__super__.constructor.call(this, name, mass, vel, max_vel);
      }

      /*
        Updates this Particle's velocity and position.
      
        Args:
          delta: {Number} Time delta since last frame. TODO: Necessary?
        Return:
          null
      */


      Particle.prototype.update = function(delta) {
        var dv, dxy, vel_mag;
        if (this.mass === 0) {
          return null;
        }
        if (this.force.length() !== 0) {
          dv = this.force.clone();
          dv.divideScalar(this.mass);
          dv.multiplyScalar(delta);
          this.vel.add(dv);
          this.force.set(0, 0, 0);
        } else {
          vel_mag = this.vel.length();
          if (vel_mag > this.max_vel) {
            this.vel.normalize();
            this.vel.multiplyScalar(vel_mag - 2);
          }
        }
        dxy = this.vel.clone();
        dxy.multiplyScalar(delta);
        return this.pos.add(dxy);
      };

      /*
        Return a reference to this Particle's position vector
      */


      Particle.prototype.getPos = function() {
        return this.pos;
      };

      return Particle;

    })(Body);
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

      Manifold.prototype.normal = null;

      return Manifold;

    })();
    null;
    /*
      A force explosion that radially pushes all bodies in its range, except for
      the heros.
    */

    Fwoom = (function() {
      function Fwoom(radius, power, position) {
        this.radius = radius;
        this.power = power;
        this.pos = position;
        this.death_time = new Date().getTime() + 250;
      }

      return Fwoom;

    })();
    return null;
  };

  $(function() {
    return DMOENCH.Fwoom.init();
  });

  this.DMOENCH = DMOENCH;

}).call(this);
