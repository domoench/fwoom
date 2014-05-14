###

  Fwoom! A WebGL game by David Moench

###

DMOENCH = DMOENCH || {}
DMOENCH.Fwoom = new () ->
  # Constants
  WIDTH = 800
  HEIGHT = 600
  HERO_ENGINE_FORCE = 400
  BODYTYPE =
    hero: 0
    hunter: 1
    rock: 2
  Object.freeze BODYTYPE
  FPMS = 60 / 1000

  # Game State
  camera      = null
  scene       = null
  renderer    = null
  $container  = $ '#container'
  bodies      = [null, null]
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

    # Create a point light
    pointLight = new THREE.PointLight(0xFFFFFF)
    pointLight.position.set(100, -250, 130)

    # Create the Hero Puck
    radius = 20
    rad_segs = 64
    hero_mat = new THREE.MeshLambertMaterial({color: 0xCC0000})
    hero_mesh = new THREE.Mesh(
      new THREE.CircleGeometry(radius, rad_segs),
      hero_mat)
    hero_mesh.position.set(0, 0, 0)
    hero = new Body('hero', 1.0, new THREE.Vector3(0), 300, hero_mesh)
    bodies[0] = hero

    # Create a Rock
    radius = 30
    rad_segs = 16
    rock_mat = new THREE.MeshLambertMaterial({color: 0xFFFF00})
    rock_mesh = new THREE.Mesh(
      new THREE.CircleGeometry(radius, rad_segs),
      rock_mat)
    rock_mesh.position.set(-100, 0, 0)
    rock = new Body('rock', 0.0, new THREE.Vector3(0), 0, rock_mesh)
    bodies[1] = rock
    # console.log bodies

    # Add everything to the scene
    scene.add(pointLight)
    _.each(bodies, (body) -> scene.add(body.mesh))
    scene.add(camera)
    null

  ###
    Move each body for the next frame according to its current velocity and
    the net force acting on it.
  ###
  updateBodies = (delta) ->
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
      handleCollisions(delta)
      updateBodies(delta)
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
    # console.log collisions
    resolveBodyCollisions(delta, collisions)
    null

  ###
    Detect collisions between bodies in the scene and generate a manifold
    object for each collision

    Returns a list of manifold objects
  ###
  detectBodyCollisions = (delta) ->
    candidates = [] # Candidates for collision
    _.each(bodies, (a) ->
      _.each(bodies, (b) ->
        # SAT Bounding-Box collision test
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

        if a != b and bbIntersects(a_BB, b_BB)
          candidates[candidates.length] = new Manifold(a, b)
        null
      )
      null
    )
    # Remove duplicates

    # Fine tuned collision test
    candidates

  ###
    Determine if two bounding boxes intersect.
  ###
  bbIntersects = (a_BB, b_BB) ->
    # Check X axis projection
    x_intersect = (a_BB.min.x <= b_BB.max.x) and
                  (a_BB.max.x >= b_BB.min.x)
    # Check Y axis projection
    y_intersect = (a_BB.min.y <= b_BB.max.y) and
                  (a_BB.max.y >= b_BB.min.y)

    # If both axes projections intersect, then BBs intersect
    x_intersect and y_intersect

  ###
    Resolve collisions between bodies in the scene.
  ###
  resolveBodyCollisions = (delta, collisions) ->
    # TODO
    # For each manifold
    #   Calulate impulse
    #   Correct penetration and adjust velocities
    null

  ###
    Check if BODY is colliding with a screen boundary, and if so reverse its
    velocity to bounce. Bouncing off the wall is perfectly elastic.
  ###
  collideWall = (body) ->
    # TODO: Add penetration correction to prevent getting stuck in the wall
    if Math.abs(body.mesh.position.x) > WIDTH / 2 - body.mesh.geometry.radiusTop
      body.vel.x *= -1
    if Math.abs(body.mesh.position.y) > HEIGHT / 2 - body.mesh.geometry.radiusTop
      body.vel.y *= -1
    null

  ###
    Calculate the sign of N. Return 1 if positive, -1 if negative
  ###
  sign = (n) ->
    if n >= 0 then 1 else -1

  ###
    Record key press down in keys_down dictionary
  ###
  handleKeyDown = (event) ->
    keys_down[event.keyCode] = true

  ###
    Record key let up in keys_down dictionary
  ###
  handleKeyUp = (event) ->
    keys_down[event.keyCode] = false

  ###
    Handle user input based on state of keys_down dictionary
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
    force: new THREE.Vector3(0)
    update: (delta) ->
      if @mass == 0
        return null
      # Calculate new velocity
      dv = @force.clone()
      dv.divideScalar(@mass)
      dv.multiplyScalar(delta)
      @vel.add(dv)
      # Enforce max velocity
      if @vel.length() > @max_vel
        @vel.sub(dv)

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
    normal: new THREE.Vector3(0)
  null

# Once document is ready, DO IT
$ ->
  DMOENCH.Fwoom.init()

# Attach to window for debugging. TODO: Remove
this.DMOENCH = DMOENCH
