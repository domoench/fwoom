###

  Fwoom! A WebGL game by David Moench

###

DMOENCH = DMOENCH || {}
DMOENCH.Fwoom = new () ->
  # Constants
  WIDTH = 960
  HEIGHT = 630
  HERO_ENGINE_FORCE = 1000
  BODYTYPE =
    hero: 0
    blob: 1
    rock: 2
  Object.freeze BODYTYPE

  # Game State
  camera      = null
  scene       = null
  renderer    = null
  $container  = $ '#container'
  bodies      = []
  particles   = []
  particle_sys = null
  fwooms      = []
  hero        = null
  time_last   = 0
  keys_down   = {}

  stats = null

  ###
    Initialize and start the game
  ###
  @init = () ->
    # Build Scene
    initObjects()
    # Init Key Handling
    document.onkeydown = handleKeyDown
    document.onkeyup   = handleKeyUp
    # Start game loop
    render()
    null

  ###
    Create WebGL renderer, camera, and a scene.
  ###
  initObjects = () ->
    renderer = new THREE.WebGLRenderer(antialias: true)
    scene = new THREE.Scene()

    # Set up camera
    camera = new THREE.OrthographicCamera(WIDTH / -2, WIDTH / 2,
                                          HEIGHT / 2, HEIGHT / -2,
                                          -10000, 10000)
    camera.position.z = 1500

    # Start the renderer
    renderer.setSize(WIDTH, HEIGHT)
    renderer.shadowMapEnabled = true
    renderer.shadowMapType = THREE.PCFShadowMap

    # Attach the render-supplied DOM element
    $container.append(renderer.domElement)

    # Lights
    amblight = new THREE.AmbientLight(0xE0E0E0)

    spotlight = new THREE.SpotLight(0xFFFFFF, 1, 0, Math.PI /2, 1)
    spotlight.position.set(-300, 40, 2000)
    spotlight.castShadow = true
    spotlight.shadowDarkness = 0.2
    spotlight.onlyShadow = true
    spotlight.shadowCameraNear = 1000
    spotlight.shadowCameraFar = 3000

    # Create the Hero Puck
    hero_radius = 20
    hero_segs = 32
    hero_mat = new THREE.MeshPhongMaterial(
      color: 0xFF00FF
      ambient: 0x83A136
    )
    hero_geom = new THREE.CylinderGeometry(hero_radius, hero_radius, 1, hero_segs, 1, false)
    hero_mesh = new THREE.Mesh(hero_geom, hero_mat)
    hero_mesh.castShadow = true
    hero_mesh.receiveShadow = false
    hero_mesh.position.set(0, 0, 0)
    hero_mesh.rotation.x = Math.PI / 2
    max_vel = 400
    hero_density = 0.002
    hero_mass = hero_density * Math.PI * hero_radius * hero_radius
    hero = new Hero('hero', hero_mass, new THREE.Vector3(0), max_vel, hero_mesh)
    bodies[bodies.length] = hero

    # Create an Rock
    rock_radius = 40
    rock_segs = 32
    rock_mat = new THREE.MeshPhongMaterial(
      color: 0x246C60
      ambient: 0x246C60
    )
    rock_geom = new THREE.CylinderGeometry(rock_radius, rock_radius, 1, rock_segs, 1, false)
    rock_mesh = new THREE.Mesh(rock_geom, rock_mat)
    rock_mesh.castShadow = true
    rock_mesh.position.set(-100, 0, 0)
    rock_mesh.rotation.x = Math.PI / 2
    rock_mass = 0
    rock = new Rock('rock', rock_mass, new THREE.Vector3(0), 0, rock_mesh)
    bodies[bodies.length] = rock

    # Create a Blob
    blob_radius = 20
    blob_segs = 32
    blob_mat = new THREE.MeshPhongMaterial(
      color: 0xA33643
      ambient: 0xA22643
    )
    blob_geom = new THREE.CylinderGeometry(blob_radius, blob_radius, 1, blob_segs, 1, false)
    blob_mesh = new THREE.Mesh(blob_geom, blob_mat)
    blob_mesh.castShadow = true
    blob_mesh.position.set(100, 50, 0)
    blob_mesh.rotation.x = Math.PI / 2
    # Assign random displacement factor to each vertex for shader animation
    blob_verts = blob_mesh.geometry.vertices
    blob_density = 0.002
    blob_mass = blob_density * Math.PI * blob_radius * blob_radius
    max_vel = 900
    blob = new Blob('blob', blob_mass, new THREE.Vector3(80, 40, 0), max_vel, blob_mesh)
    bodies[bodies.length] = blob

    # Create debris particles
    num_particles = 300
    particles_geom = new THREE.Geometry()
    part_sprite = THREE.ImageUtils.loadTexture( "img/snowflake1.png" )
    part_mat  = new THREE.ParticleSystemMaterial(
                  color: 0xFFFFFF
                  map: part_sprite
                  size: 20
                  blending: THREE.AdditiveBlending
                  transparent: true
                )
    for i in [0...num_particles]
      x = Math.random() * WIDTH  - WIDTH / 2
      y = Math.random() * HEIGHT - HEIGHT / 2
      particle_pos = new THREE.Vector3(x, y, 0.0)
      particles.push(new Particle(i, particle_pos))
      particles_geom.vertices.push(particle_pos)
    particle_sys = new THREE.ParticleSystem(particles_geom, part_mat)

    # Create background billboard
    plane_mat = new THREE.MeshLambertMaterial(color: 0x333333)
    plane_mat.ambient = plane_mat.color
    plane_mesh = new THREE.Mesh(
      new THREE.PlaneGeometry(WIDTH, HEIGHT),
      plane_mat
    )
    plane_mesh.position.z = -100
    plane_mesh.castShadow = false
    plane_mesh.receiveShadow = true

    # Add everything to the scene
    scene.add(amblight)
    scene.add(spotlight)
    scene.add(particle_sys)
    scene.add(plane_mesh)
    _.each(bodies, (body) -> scene.add(body.mesh))
    scene.add(camera)

    stats = new Stats()
    stats.domElement.style.position = 'absolute'
    stats.domElement.style.top = '0px'
    $('body').append(stats.domElement)
    null

  ###
    Move each body for the next frame according to its current velocity and
    the net force acting on it.
  ###
  updateBodies = (delta) ->
    handleFwooms()
    _.each(bodies, (body) -> body.update(delta))
    _.each(particles, (particle) -> particle.update(delta))
    particle_sys.geometry.verticesNeedUpdate = true
    null

  ###
    Render Loop: Update scene, render it, and request next iteration
  ###
  render = () ->
    # Calculate time since last frame
    time_now = new Date().getTime()
    if time_last != 0
      # Time delta in seconds
      delta = (time_now - time_last) / 1000
      handleKeys()
      updateBodies(delta)
      handleCollisions(delta)
    time_last = time_now

    requestAnimationFrame(render)
    renderer.render(scene, camera)
    stats.update()
    null

  ###
    Detect and resolve collisions between all bodies.
  ###
  handleCollisions = (delta) ->
    _.each(bodies, (body) -> collideWall(body))
    _.each(particles, (particle) -> collideWall(particle))
    collisions = detectBodyCollisions(delta)
    resolveBodyCollisions(collisions)
    null

  ###
    Detect collisions between bodies in the scene and generate a manifold
    object for each collision

    Returns a list of manifold objects
  ###
  detectBodyCollisions = (delta) ->
    collisions = []
    n = bodies.length
    for i in [0...n]
      for j in [i+1...n]
        a = bodies[i]
        b = bodies[j]
        # SAT Bounding-Box collision test
        if a != b and bbIntersects(a, b)
          # Fully test circle collision
          collision = circleCircleCollide(a,b)
          if collision?
            collisions[collisions.length] = collision
    collisions

  ###
    Determine if two circular bodies intersect and generate a manifold object
    for the collision.

    Returns:
      A Manifold object OR null if no collision.
  ###
  circleCircleCollide = (a, b) ->
    a_pos = a.getPos()
    b_pos = b.getPos()
    # Collision normal vector n = B - A.
    n = b_pos.clone()
    n.sub(a_pos)
    # Max distance between centers for a collision
    r_sum = a.getRadius() + b.getRadius()
    d = n.length()
    if d > r_sum
      return null
    # We have a true collision. Populate a Manifold.
    collision = new Manifold(a, b)
    if d != 0
      collision.penetration = r_sum - d
      n.normalize()
      collision.normal = n
    else # Circles are in same position
      collision.penetration = a.getRadius()
      collision.normal = new THREE.Vector3(1,0,0)
    collision

  ###
    Determine if the bounding boxes of bodies A and B intersect.
  ###
  bbIntersects = (a, b) ->
    a_rad = a.getRadius()
    b_rad = b.getRadius()
    a_pos = a.getPos()
    b_pos = b.getPos()
    a_min_x = a_pos.x - a_rad
    a_min_y = a_pos.y - a_rad
    a_max_x = a_pos.x + a_rad
    a_max_y = a_pos.y + a_rad
    b_min_x = b_pos.x - b_rad
    b_min_y = b_pos.y - b_rad
    b_max_x = b_pos.x + b_rad
    b_max_y = b_pos.y + b_rad

    # Check X axis projection
    x_intersect = (a_min_x <= b_max_x) and
                  (a_max_x >= b_min_x)
    # Check Y axis projection
    y_intersect = (a_min_y <= b_max_y) and
                  (a_max_y >= b_min_y)
    # If both axes projections intersect, then BBs intersect
    x_intersect and y_intersect

  ###
    Resolve all collisions between bodies in the scene specified by the list of
    Manifold objects.
  ###
  resolveBodyCollisions = (collisions) ->
    if collisions.length == 0
      return
    _.each(collisions, (collision) -> resolveBodyCollision(collision))
    null

  ###
    Resolve a single collision between 2 bodies, updating their velocities as
    appropriate.
  ###
  resolveBodyCollision = (collision) ->
    a = collision.a
    b = collision.b
    a_inv_mass = if (a.mass == 0) then 0 else 1 / a.mass
    b_inv_mass = if (b.mass == 0) then 0 else 1 / b.mass
    mass_sum = a.mass + b.mass
    a_mass_ratio = a.mass / mass_sum
    b_mass_ratio = 1.0 - a_mass_ratio
    # Relative velocity
    rv = new THREE.Vector3(0)
    rv.subVectors(b.vel, a.vel)
    # Relative velocity scalar projection along collision normal
    rv_n = rv.dot(collision.normal)
    # No resolution required if bodies are already separating
    if rv_n > 0
      return
    # Coefficient of restitution. Harcoded for now.
    rest = 0.85
    # Calculate impulse scalar value
    imp = -(1 + rest) * rv_n
    imp /= (a_inv_mass + b_inv_mass)
    # Apply impulse and update bodies' velocities
    imp_vect = collision.normal.clone()
    imp_vect.multiplyScalar(imp)
    a_diff = imp_vect.clone()
    a_diff.multiplyScalar(a_inv_mass)
    a.vel.sub(a_diff)
    b_diff = imp_vect.clone()
    b_diff.multiplyScalar(b_inv_mass)
    b.vel.add(b_diff)
    null

  ###
    Check if BODY is colliding with a screen boundary, and if so reverse its
    velocity to bounce. Bouncing off the wall is perfectly elastic.
  ###
  collideWall = (body) ->
    # TODO: Add penetration correction to prevent getting stuck in the wall
    pos = body.getPos()
    if body instanceof MeshBody
      if Math.abs(pos.x) > WIDTH / 2 - body.getRadius()
        body.vel.x *= -1
      if Math.abs(pos.y) > HEIGHT / 2 - body.getRadius()
        body.vel.y *= -1
    else if body instanceof Particle
      if Math.abs(pos.x) > WIDTH / 2
        body.vel.x *= -1
      if Math.abs(pos.y) > HEIGHT / 2
        body.vel.y *= -1
    null

  ###
    Apply any existing fwoom forces to bodies in the scene
  ###
  handleFwooms = () ->
    if fwooms.length == 0
      return
    _.each(fwooms, (fwoom) ->
      # Apply force to all bodies affected by this fwoom.
      applyFwoomToBodies(fwoom, bodies)
      applyFwoomToBodies(fwoom, particles)
    )
    clearExpiredFwooms()

  applyFwoomToBodies = (fwoom, bodies) ->
    dist_vect = new THREE.Vector3(0)
    _.each(bodies, (body) ->
      # Ignore hero
      if body is hero
        return
      # Find distance from fwoom origin to body origin
      dist_vect.set(0)
      dist_vect.subVectors(body.getPos(), fwoom.pos)
      d = dist_vect.length()
      # If affected, apply force as function of distance
      if d < fwoom.radius
        force_vect = dist_vect.clone()
        force_vect.normalize()
        force_vect.multiplyScalar(fwoom.power / d)
        body.force.add(force_vect)
      null
    )
    null

  ###
    Clear any expired fwooms
  ###
  clearExpiredFwooms = () ->
    time_now = new Date().getTime()
    if time_now > fwooms[0].death_time
      fwooms.shift()
    null

  ###
    Calculate the sign of N. Return 1 if positive, -1 if negative
  ###
  sign = (n) ->
    if n >= 0 then 1 else -1

  ###
    Record key press down in keys_down dictionary and handle one-off keys.
  ###
  handleKeyDown = (event) ->
    # Record in dictionary
    keys_down[event.keyCode] = true
    # Handle one-off key presses
    # Fwooms
    if event.keyCode == 32 # Space Bar
      fwooms.push(new Fwoom(150, 400000, hero.getPos()))

  ###
    Record key let up in keys_down dictionary
  ###
  handleKeyUp = (event) ->
    keys_down[event.keyCode] = false

  ###
    Handle user input based on state of keys_down dictionary. This applies to
    keys pressed over durations.
  ###
  handleKeys = () ->
    # Hero controls
    if keys_down[37] # Left Arrow
      hero.force.setX(hero.force.x - HERO_ENGINE_FORCE)
    if keys_down[38] # Up Arrow
      hero.force.setY(hero.force.y + HERO_ENGINE_FORCE)
    if keys_down[39] # Right Arrow
      hero.force.setX(hero.force.x + HERO_ENGINE_FORCE)
    if keys_down[40] # Down Arrow
      hero.force.setY(hero.force.y - HERO_ENGINE_FORCE)

  ###
    Bodies represent physical entities in the scene. They package physics
    properties with rendering properties.
  ###
  class Body
    constructor: (name, mass, vel, max_vel) ->
      @name = name
      # Zero mass means infinite mass => immovable object
      @mass = mass || 0
      @vel =  vel  || new THREE.Vector3(0)
      @max_vel = max_vel || 0
      @force = new THREE.Vector3(0)

    ###
      Update's this Body's velocity based on its physical properties and the
      forces acting on it.

      Args:
        delta: {Number} Time delta since last frame. TODO: Necessary?
      Return:
        null
    ###
    update: (delta) ->
      if @mass == 0
        return null
      # Calculate new velocity
      dv = @force.clone()
      dv.divideScalar(@mass)
      dv.multiplyScalar(delta)
      @vel.add(dv)
      # TODO: Enforce max velocity?

      @force.set(0,0,0)
      null

  ###
    MeshBody is a Body subclass that maintains threejs rendering info via a
    Mesh.
  ###
  class MeshBody extends Body
    constructor: (name, mass, vel, max_vel, mesh) ->
      @mesh = mesh || null
      super(name, mass, vel, max_vel)

    ###
      Updates this MeshBody's velocity and position based on its physical
      properties and the forces acting on it.

      Args:
        delta: {Number} Time delta since last frame. TODO: Necessary?
      Return:
        null
    ###
    update: (delta) ->
      # Update velocity
      super(delta)
      # Calculate new position
      dxy = @vel.clone()
      dxy.multiplyScalar(delta)
      @mesh.position.add(dxy)

    ###
      Return a reference to this MeshBody's position vector
    ###
    getPos: ->
      @mesh.position

    ###
      Get the radius of this MeshBody's mesh.
    ###
    getRadius: ->
      @mesh.geometry.boundingSphere.radius

  class Blob extends MeshBody
    ###
      Updates this Body's velocity and position.

      Args:
        delta: {Number} Time delta since last frame.
      Return:
        null
    ###
    update: (delta) ->
      # Update velocity and position
      super(delta)

  class Hero extends MeshBody

  class Rock extends MeshBody

  class Particle extends Body
    ###
      Create a particle with a random position

      Args:
        pos: A reference to the position object within a threejs Particle
             instance
    ###
    constructor: (name, pos) ->
      @pos = pos
      mass = 8
      max_vel = 35
      x_vel = Math.random() * max_vel - max_vel/2
      y_vel = Math.random() * max_vel - max_vel/2
      vel = new THREE.Vector3(x_vel, y_vel, 0.0)
      super(name, mass, vel, max_vel)

    ###
      Updates this Particle's velocity and position.

      Args:
        delta: {Number} Time delta since last frame. TODO: Necessary?
      Return:
        null
    ###
    update: (delta) ->
      if @mass == 0
        return null
      # Calculate new velocity
      if @force.length() != 0
        dv = @force.clone()
        dv.divideScalar(@mass)
        dv.multiplyScalar(delta)
        @vel.add(dv)
        @force.set(0,0,0)
      else
        vel_mag = @vel.length()
        if vel_mag > @max_vel
          @vel.normalize()
          @vel.multiplyScalar(vel_mag - 2)
      # Calculate new position
      dxy = @vel.clone()
      dxy.multiplyScalar(delta)
      @pos.add(dxy)

    ###
      Return a reference to this Particle's position vector
    ###
    getPos: ->
      @pos


  ###
    Manifolds are objects packaging up information about a collision that
    needs resolving.
  ###
  class Manifold
    constructor: (a, b) ->
      @a = a
      @b = b
    penetration: 0.0
    normal: null
  null

  ###
    A force explosion that radially pushes all bodies in its range, except for
    the heros.
  ###
  class Fwoom
    constructor: (radius, power, position) ->
      @radius = radius
      @power = power
      @pos = position
      # Fwooms live for .25 seconds
      @death_time = new Date().getTime() + 250
  null

# Once document is ready, DO IT
$ ->
  DMOENCH.Fwoom.init()

# Attach to window for debugging. TODO: Remove
this.DMOENCH = DMOENCH
