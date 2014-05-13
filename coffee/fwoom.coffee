###

  Fwoom! A WebGL game by David Moench

###

DMOENCH = DMOENCH || {}
DMOENCH.Fwoom = new () ->
  # Constants
  WIDTH = 800
  HEIGHT = 600
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
  bodies      = [null]
  hero        = null
  collisions  = null
  time_last   = 0

  ###
    Initialize and start the game
  ###
  @init = () ->
    initObjects()
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
    height = 0
    rad_segs = 64
    height_segs = 1
    open_ended = false
    hero_mat = new THREE.MeshLambertMaterial({color: 0xCC0000})
    hero_mesh = new THREE.Mesh(
      new THREE.CylinderGeometry(radius, radius, height, rad_segs,
                                 height_segs, open_ended),
      hero_mat)
    hero_mesh.position.set(100, 0, 0)
    hero_mesh.rotation.x = Math.PI / 2
    hero = new Body('hero', 1.0, new THREE.Vector3(0),
                    10, hero_mesh)
    hero.force = new THREE.Vector3(20,30,0)
    bodies[0] = hero
    console.log bodies[0]

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
    null

  ###
    Check if BODY is colliding with a screen boundary, and if so reverse its
    velocity to bounce. Bouncing off the wall is perfectly elastic.
  ###
  collideWall = (body) ->
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
      # Calculate new velocity
      dv = @force.clone()
      dv.divideScalar(@mass)
      dv.multiplyScalar(delta)
      # TODO: Account for max_vel scalar
      @vel.add(dv)
      # Calculate new position
      dxy = @vel.clone()
      dxy.multiplyScalar(delta)
      @mesh.position.add(dxy)
      null

  null

# Once document is ready, DO IT
$ ->
  DMOENCH.Fwoom.init()

# Attach to window for debugging. TODO: Remove
this.DMOENCH = DMOENCH
