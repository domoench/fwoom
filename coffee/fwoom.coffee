###

  Fwoom! A WebGL game by David Moench

###

DMOENCH = DMOENCH || {}
DMOENCH.Fwoom = new () ->
  # Constants
  WIDTH = 800
  HEIGHT = 600
  ACTORTYPE =
    puck: 0
    hunter: 1
    rock: 2
  Object.freeze ACTORTYPE
  FPMS = 60 / 1000

  # Game State
  camera      = null
  scene       = null
  renderer    = null
  $container  = $ '#container'
  actors      = [null, null, null, null]
  puck        = null
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

    # Create the Hero Puck
    radius = 20
    height = 5
    rad_segs = 32
    height_segs = 1
    open_ended = false
    puck_mat = new THREE.MeshLambertMaterial({color: 0xCC0000})
    puck_mesh = new THREE.Mesh(
      new THREE.CylinderGeometry(radius, radius, height, rad_segs,
                                 height_segs, open_ended),
      puck_mat)
    puck_mesh.position.set(100, 0, 0)
    puck_mesh.rotation.x = Math.PI / 2
    puck = new Puck(puck_mesh, 1.0, new THREE.Vector3(6, -2, 0))
    actors[0] = puck

    # Create Smart Hunter
    hunter_mat = new THREE.MeshLambertMaterial({color: 0xFFFFFF})
    smart_hunter = new THREE.Mesh(
      new THREE.CylinderGeometry(radius, radius, height, rad_segs,
                                 height_segs, open_ended),
      hunter_mat)
    smart_hunter.position.set(-140, 30, 0)
    smart_hunter.rotation.x = Math.PI / 2
    actors[1] = new SmartHunter(smart_hunter, 1.0, new THREE.Vector3(0,0,0))

    # Create Rocks
    rock_mat = new THREE.MeshLambertMaterial({color: 0xA66900})
    rock1 = new THREE.Mesh(
      new THREE.CylinderGeometry(3 * radius, 3 * radius, height, rad_segs,
                                 height_segs, open_ended),
      rock_mat)
    rock1.position.set(50, 200, 0)
    rock1.rotation.x = Math.PI / 2
    actors[2] = new Rock(rock1, 10.0, new THREE.Vector3(2,-4,0))

    rock2 = new THREE.Mesh(
      new THREE.CylinderGeometry(2.0 * radius, 2.0 * radius, height, rad_segs,
                                 height_segs, open_ended),
      rock_mat)
    rock2.position.set(50, -200, 0)
    rock2.rotation.x = Math.PI / 2
    actors[3] = new Rock(rock2, 2.0, new THREE.Vector3(0,3,0))

    # Create a point light
    pointLight = new THREE.PointLight(0xFFFFFF)
    pointLight.position.set(100, -250, 130)

    # Add everything to the scene
    scene.add(pointLight)
    _.each(actors, (actor) -> scene.add(actor.mesh))
    scene.add(camera)
    null

  ###
    Calculate all collisions in the scene and record that info into the
    collisions object for lookup by updateActors()
  ###
  detectCollisions = () ->
    collisions = []
    _.each(actors, (actor) ->
      coll_partner = detectCollision(actor)
      if coll_partner?
        collisions = _.union(collisions, [[actor, coll_partner]])
    )
    null

  ###
    Calculate if ACTOR is colliding with any other actors.
    Return the collision partner, or undefined if no collision.
  ###
  detectCollision = (actor) ->
    actor_pos = actor.mesh.position
    others = _.filter(actors, (e) -> e isnt actor)
    _.find(others, (other) ->
      dist = actor_pos.distanceTo(other.mesh.position)
      dist -= actor.mesh.geometry.radiusTop + other.mesh.geometry.radiusTop
      dist < 0
    )

  ###
    Move all actors for the next frame according to their various behaviors
  ###
  updateActors = (delta) ->
    _.each(actors, (actor) -> actor.update(delta))
    null

  ###
    Render Loop: Update all actors and render a frame
  ###
  render = () ->
    # Calculate time since last frame
    time_now = new Date().getTime()
    if time_last != 0
      delta = time_now - time_last
      detectCollisions()
      updateActors(delta)
    time_last = time_now
    renderer.render(scene, camera)
    requestAnimationFrame(render)
    null

  ###
    Check if ACTOR is colliding with a screen boundary, and if so reverse its
    velocity to bounce
  ###
  collideWall = (actor) ->
    if Math.abs(actor.mesh.position.x) > WIDTH / 2 - actor.mesh.geometry.radiusTop
      actor.vel.x *= -1
    if Math.abs(actor.mesh.position.y) > HEIGHT / 2 - actor.mesh.geometry.radiusTop
      actor.vel.y *= -1

  ###
    Update the velocities of ROCK1 and ROCK2 to reflect their collision.
    https://nicoschertler.wordpress.com/2013/10/07/elastic-collision-of-circles-and-spheres/
  ###
  collideRockRock = (rock1, rock2) ->
    # Establish consistent collision state
    # console.log "Rocks Colliding..."
    v = new THREE.Vector3()
    v.subVectors(rock1.mesh.position, rock2.mesh.position)
    v.normalize().multiplyScalar(rock1.mesh.geometry.radiusTop + rock2.mesh.geometry.radiusTop + 1.5)
    rock1.mesh.position.addVectors(rock2.mesh.position, v)

    # Resolve collision
    m1 = rock1.mass
    m2 = rock2.mass
    v1 = rock1.vel.clone()
    v2 = rock2.vel.clone()
    # Calculate the normal of the collision plane
    c_norm = rock2.mesh.position.clone().sub(rock1.mesh.position).normalize()
    # Decompose each rock velocities into collision component and remainder
    v1_dot = c_norm.dot(v1)
    v1_coll = c_norm.clone().multiplyScalar(v1_dot)
    v1_rem = v1.clone().sub(v1_coll)
    v2_dot = c_norm.dot(v2)
    v2_coll = c_norm.clone().multiplyScalar(v2_dot)
    v2_rem = v2.clone().sub(v2_coll)

    # Calculate collision
    v1_len = v1_coll.length() * sign(v1_dot)
    v2_len = v2_coll.length() * sign(v2_dot)
    common_vel = 2 * (m1 * v1_len + m2 * v2_len) / (m1 + m2)
    v1_len_after = common_vel - v1_len
    v2_len_after = common_vel - v2_len
    v1_coll.multiplyScalar(v1_len_after / v1_len)
    v2_coll.multiplyScalar(v2_len_after / v2_len)

    rock1.vel.addVectors(v1_coll, v1_rem)
    rock2.vel.addVectors(v2_coll, v2_rem)
    # Collision has been handled, remove the pair from the frame's collision list
    clearCollisionPair(rock1, rock2)
    null

  ###
    Update the velocities of and ROCK and HUNTER to reflect their collision.
    Current behavior: Rock doesn't care, just blocks hunter
  ###
  collideRockHunter = (rock, hunter) ->
    # Establish consistent collision state
    v = new THREE.Vector3()
    v.subVectors(hunter.mesh.position, rock.mesh.position)
    v.normalize().multiplyScalar(hunter.mesh.geometry.radiusTop + rock.mesh.geometry.radiusTop + 1.5)
    hunter.mesh.position.addVectors(rock.mesh.position, v)
    clearCollisionPair(rock, hunter)
    null

  ###
    Update the velocities of and ROCK and PUCK to reflect their collision.
  ###
  collideRockPuck = (rock, puck) ->
    # console.log "Rock Puck Collision"
    clearCollisionPair(rock, puck)
    null

  ###
    Removes the collision pair from the current collisions list.
  ###
  clearCollisionPair = (actor1, actor2) ->
    collisions = _.filter(collisions, (coll_tuple) ->
      (coll_tuple[0] isnt actor1) and (coll_tuple[0] isnt actor2)
    )

  ###
    Calculate the sign of N. Return 1 if positive, -1 if negative
  ###
  sign = (n) ->
    if n >= 0 then 1 else -1

  ###
    Actors are things that move and interact in the scene. There are many
    subtypes of actors.
  ###
  class Actor
    constructor: (name, mass, vel) ->
      @name = name
      @mass = mass || 1
      @vel = vel || THREE.Vector3(0)
    update: -> throw new Error('Actor is an abstract class')
    mesh: null

  ###
    Puck: The hero!
    actor_mesh: The THREE.Mesh for this actor
  ###
  class Puck extends Actor
    constructor: (puck_mesh, mass, vel) ->
      super puck_mesh.uuid, mass, vel
      @mesh = puck_mesh
      @type = ACTORTYPE.puck
    update: (delta) ->
      frames_elapsed = delta * FPMS
      # Check for collision with other actors
      coll_tuple = _.find(collisions, (tuple) ->
        tuple[0] is @
      , @)
      if coll_tuple?
        partner = coll_tuple[1]
        if partner.type is ACTORTYPE.rock
          collideRockPuck(partner, @)
          #scene.remove(puck.mesh)

      collideWall(@)

      # Update position
      vt = @vel.clone().multiplyScalar(frames_elapsed)
      @mesh.position.add(vt)
      null

  class SmartHunter extends Actor
    constructor: (hunter_mesh, mass, vel) ->
      super hunter_mesh.uuid, mass, vel
      @mesh = hunter_mesh
      @type = ACTORTYPE.hunter
    update: (delta) ->
      frames_elapsed = delta * FPMS
      coll_tuple = _.find(collisions, (tuple) ->
        tuple[0] is @
      , @)
      if coll_tuple?
        partner = coll_tuple[1]
        if partner.type is ACTORTYPE.rock
          collideRockHunter(partner, @)
      else
        puck_pos = puck.mesh.position
        @vel.subVectors(puck_pos, @mesh.position)
        dist = @mesh.position.distanceTo(puck_pos)
        @vel.normalize().multiplyScalar(2.5)
        vt = @vel.clone().multiplyScalar(frames_elapsed)
        @mesh.position.add(vt)
      null

  class Rock extends Actor
    constructor: (rock_mesh, mass, vel) ->
      super rock_mesh.uuid, mass, vel
      @mesh = rock_mesh
      @type = ACTORTYPE.rock
    update: (delta) ->
      frames_elapsed = delta * FPMS
      coll_tuple = _.find(collisions, (tuple) ->
        tuple[0] is @
      , @)
      if coll_tuple?
        partner = coll_tuple[1]
        if partner.type is ACTORTYPE.rock
          collideRockRock(@, partner)
        else if partner.type is ACTORTYPE.puck
          collideRockPuck(@, partner)

      collideWall(@)
      vt = @vel.clone().multiplyScalar(frames_elapsed)
      @mesh.position.add(vt)
      null

  null

# Once document is ready, DO IT
$ ->
  DMOENCH.Fwoom.init()

# Attach to window for debugging. TODO: Remove
this.DMOENCH = DMOENCH
