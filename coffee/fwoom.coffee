###

  Fwoom! A WebGL game by David Moench

###

DMOENCH = DMOENCH || {}
DMOENCH.Fwoom = new () ->
  # Constants
  WIDTH = 800
  HEIGHT = 600
  HERO_ENGINE_FORCE = 1000
  BODYTYPE =
    hero: 0
    rock: 1
    obstacle: 2
  Object.freeze BODYTYPE
  FPMS = 60 / 1000

  # Game State
  camera      = null
  scene       = null
  renderer    = null
  $container  = $ '#container'
  bodies      = []
  fwooms      = []
  hero        = null
  time_last   = 0
  keys_down   = {}

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
    renderer = new THREE.WebGLRenderer()
    scene = new THREE.Scene()

    # Set up camera
    view_angle = 90
    aspect = WIDTH / HEIGHT
    near = 0.1
    far = 10000
    camera = new THREE.PerspectiveCamera(view_angle, aspect, near, far)
    camera.position.z = 300

    # Start the renderer
    renderer.setSize(WIDTH, HEIGHT)

    # Attach the render-supplied DOM element
    $container.append(renderer.domElement)

    # Create point lights
    pointLight1 = new THREE.PointLight(0xFFFFFF, 2, 2000)
    pointLight1.position.set(800, -800, 600)
    pointLight2 = new THREE.PointLight(0xFF0000, 7, 2000)
    pointLight2.position.set(-800, 800, 400)

    # Create the Hero Puck
    hero_radius = 20
    hero_segs = 64
    hero_bump_map = THREE.ImageUtils.loadTexture("./img/rocky-normal-small.jpg")
    hero_mat = new THREE.MeshPhongMaterial(
      color: 0x00ff00
      bumpMap: hero_bump_map
    )
    console.log hero_mat
    hero_geom = new THREE.CircleGeometry(hero_radius, hero_segs)
    hero_mesh = new THREE.Mesh(hero_geom, hero_mat)
    hero_mesh.position.set(0, 0, 0)
    max_vel = 400
    hero_density = 0.002
    hero_mass = hero_density * Math.PI * hero_radius * hero_radius
    hero = new Body('hero', hero_mass, new THREE.Vector3(0), max_vel, hero_mesh)
    bodies[bodies.length] = hero

    # Create an Obstacle
    obst_radius = 40
    obst_segs = 32
    obst_mat = new THREE.MeshLambertMaterial({color: 0x0B61A4})
    obst_geom = new THREE.SphereGeometry(obst_radius, obst_segs, obst_segs)
    obst_mesh = new THREE.Mesh(obst_geom, obst_mat)
    obst_mesh.position.set(-100, 0, 0)
    obst_mass = 0
    obst = new Body('obst', obst_mass, new THREE.Vector3(0), 0, obst_mesh)
    bodies[bodies.length] = obst

    # Create an Rock
    rock_radius = 20
    rock_segs = 32
    rock_mat = new THREE.MeshLambertMaterial({color: 0xFF4900})
    rock_geom = new THREE.CircleGeometry(rock_radius, rock_segs)
    rock_mesh = new THREE.Mesh(rock_geom, rock_mat)
    rock_mesh.position.set(100, 50, 0)
    rock_density = 0.002
    rock_mass = rock_density * Math.PI * rock_radius * rock_radius
    max_vel = 900
    rock = new Body('rock', rock_mass, new THREE.Vector3(80, 40, 0), max_vel, rock_mesh)
    bodies[bodies.length] = rock

    # Add everything to the scene
    scene.add(pointLight1)
    scene.add(pointLight2)
    _.each(bodies, (body) -> scene.add(body.mesh))
    scene.add(camera)
    null

  ###
    Move each body for the next frame according to its current velocity and
    the net force acting on it.
  ###
  updateBodies = (delta) ->
    handleFwooms()
    _.each(bodies, (body) -> body.update(delta))
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

    renderer.render(scene, camera)
    requestAnimationFrame(render)
    null

  ###
    Detect and resolve collisions between all bodies.
  ###
  handleCollisions = (delta) ->
    _.each(bodies, (body) -> collideWall(body))
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
    a_pos = a.mesh.position
    b_pos = b.mesh.position
    # Collision normal vector n = B - A.
    n = b_pos.clone()
    n.sub(a_pos)
    # Max distance between centers for a collision
    r_sum = a.mesh.geometry.radius + b.mesh.geometry.radius
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
      collision.penetration = a.mesh.geometry.radius
      collision.normal = new THREE.Vector3(1,0,0)
    collision

  ###
    Determine if the bounding boxes of bodies A and B intersect.
  ###
  bbIntersects = (a, b) ->
    # Model BBs
    a.mesh.geometry.computeBoundingBox()
    b.mesh.geometry.computeBoundingBox()
    a_BB = a.mesh.geometry.boundingBox
    b_BB = b.mesh.geometry.boundingBox
    # World BBs
    a_BB.min.add(a.mesh.position)
    a_BB.max.add(a.mesh.position)
    b_BB.min.add(b.mesh.position)
    b_BB.max.add(b.mesh.position)
    # Check X axis projection
    x_intersect = (a_BB.min.x <= b_BB.max.x) and
                  (a_BB.max.x >= b_BB.min.x)
    # Check Y axis projection
    y_intersect = (a_BB.min.y <= b_BB.max.y) and
                  (a_BB.max.y >= b_BB.min.y)
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
    if Math.abs(body.mesh.position.x) > WIDTH / 2 - body.mesh.geometry.radius
      body.vel.x *= -1
    if Math.abs(body.mesh.position.y) > HEIGHT / 2 - body.mesh.geometry.radius
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
      _.each(bodies, (body) ->
        # Ignore hero
        if body is hero
          return
        # Find distance from fwoom origin to body origin
        dist_vect = new THREE.Vector3(0)
        dist_vect.subVectors(body.mesh.position, fwoom.pos)
        d = dist_vect.length()
        # If affected, apply force as function of distance
        if d < fwoom.radius
          console.log "Fwooming body", body
          console.log "dist: ", dist_vect
          console.log "d: ", d
          force_vect = dist_vect.clone()
          force_vect.normalize()
          force_vect.multiplyScalar(fwoom.power / d)
          body.force.add(force_vect)
          console.log "body.force", body.force
        null
      )
      null
    )
    # Clear any expired fwooms
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
      fwooms.push(new Fwoom(150, 400000, hero.mesh.position))

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
    Bodies are the physical entities in the scene.
  ###
  class Body
    constructor: (name, mass, vel, max_vel, mesh) ->
      @name = name
      # Zero mass means infinite mass => immovable object
      @mass = mass || 0
      @vel =  vel  || new THREE.Vector3(0)
      @mesh = mesh || null
      @max_vel = max_vel || 0
      @force = new THREE.Vector3(0)
    update: (delta) ->
      if @mass == 0
        return null
      # Calculate new velocity
      dv = @force.clone()
      dv.divideScalar(@mass)
      dv.multiplyScalar(delta)
      @vel.add(dv)
      # TODO: Enforce max velocity?

      # Calculate new position
      dxy = @vel.clone()
      dxy.multiplyScalar(delta)
      @mesh.position.add(dxy)

      @force.set(0,0,0)
      null

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
