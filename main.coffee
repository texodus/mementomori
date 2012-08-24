
fogExp2 = true
container = undefined
stats = undefined
camera = undefined
controls = undefined
scene = undefined
renderer = undefined
mesh = undefined
mat = undefined
worldWidth = 400
worldDepth = 400
texture_placeholder = undefined
worldHalfWidth = worldWidth / 2
worldHalfDepth = worldDepth / 2
data = undefined

init = ->
  
  #m_d   = generateMegamaterialDebug(),
  
  # map of UV indices for faces of partially defined cubes
  
  # all possible combinations of corners and sides
  # mapped to mixed tiles
  # 	(including corners overlapping sides)
  # 	(excluding corner alone and sides alone)
  
  # looks ugly, but allows to squeeze all
  # combinations for one texture into just 3 rows
  # instead of 16
  
  # mapping from 256 possible corners + sides combinations
  # into 3 x 16 tiles
  setUVTile = (face, s, t) ->
    j = undefined
    uv = cube.faceVertexUvs[0][face]
    j = 0
    while j < uv.length
      uv[j].u += s * (unit + 2 * padding)
      uv[j].v += t * (unit + 2 * padding)
      j++
  container = document.getElementById("container")
  camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 1, 40000)
  camera.position.y = getY(worldHalfWidth, worldHalfDepth) * 100 + 100
  controls = new THREE.FirstPersonControls(camera)
  controls.movementSpeed = 1000
  controls.lookSpeed = 0.125
  controls.lookVertical = true
  controls.constrainVertical = true
  controls.verticalMin = 1.1
  controls.verticalMax = 2.2
  scene = new THREE.Scene()
  scene.fog = new THREE.FogExp2(0xff0000, 0.00008)
  debug_texture = false
  debug_numbers = false
  debug_corner_colors = false
  strength = 2
  textures =
    side:   "blank.png"
    top:    "blank.png"
    bottom: "blank.png"

  m_aot = generateMegamaterialAO(textures, strength, debug_texture, debug_numbers, debug_corner_colors)
  m_ao = generateMegamaterialAO(textures, strength, true, debug_numbers, debug_corner_colors)
  m_t = generateMegamaterialPlain(textures)
  mat = generateMegamaterialAO(textures, strength, debug_texture, debug_numbers, debug_corner_colors)
  materials = [mat, mat, mat, mat, mat, mat]
  i = undefined
  j = undefined
  x = undefined
  z = undefined
  h = undefined
  h2 = undefined
  uv = undefined
  px = undefined
  nx = undefined
  pz = undefined
  nz = undefined
  sides = undefined
  right = undefined
  left = undefined
  bottom = undefined
  top = undefined
  nright = undefined
  nleft = undefined
  nback = undefined
  nfront = undefined
  nleftup = undefined
  nrightup = undefined
  nbackup = undefined
  nfrontup = undefined
  nrb = undefined
  nrf = undefined
  nlb = undefined
  nlf = undefined
  nrbup = undefined
  nrfup = undefined
  face_px = undefined
  face_nx = undefined
  face_py = undefined
  face_ny = undefined
  face_pz = undefined
  face_nz = undefined
  ti = undefined
  ri = undefined
  li = undefined
  bi = undefined
  fi = undefined
  ci = undefined
  mi = undefined
  mm = undefined
  column = undefined
  row = undefined
  cube = undefined
  unit = 1 / 16 * 0.95
  padding = 1 / 16 * 0.025
  p = undefined
  s = undefined
  t = undefined
  hash = undefined
  N = -1
  uv_index_map =
    0:
      nx: N
      px: N
      py: 0
      ny: N
      pz: N
      nz: N

    1:
      nx: N
      px: N
      py: 0
      ny: N
      pz: N
      nz: 1

    2:
      nx: N
      px: N
      py: 0
      ny: N
      pz: 1
      nz: N

    3:
      nx: N
      px: N
      py: 0
      ny: N
      pz: 1
      nz: 2

    4:
      nx: N
      px: 0
      py: 1
      ny: N
      pz: N
      nz: N

    5:
      nx: N
      px: 0
      py: 1
      ny: N
      pz: N
      nz: 2

    6:
      nx: N
      px: 0
      py: 1
      ny: N
      pz: 2
      nz: N

    7:
      nx: N
      px: 0
      py: 1
      ny: N
      pz: 2
      nz: 3

    8:
      nx: 0
      px: N
      py: 1
      ny: N
      pz: N
      nz: N

    9:
      nx: 0
      px: N
      py: 1
      ny: N
      pz: N
      nz: 2

    10:
      nx: 0
      px: N
      py: 1
      ny: N
      pz: 2
      nz: N

    11:
      nx: 0
      px: N
      py: 1
      ny: N
      pz: 2
      nz: 3

    12:
      nx: 0
      px: 1
      py: 2
      ny: N
      pz: N
      nz: N

    13:
      nx: 0
      px: 1
      py: 2
      ny: N
      pz: N
      nz: 3

    14:
      nx: 0
      px: 1
      py: 2
      ny: N
      pz: 3
      nz: N

    15:
      nx: 0
      px: 1
      py: 2
      ny: N
      pz: 3
      nz: 4

  mixmap =
    "1_1": 0
    "1_3": 0
    "1_9": 0
    "1_11": 0
    "1_4": 1
    "1_6": 1
    "1_12": 1
    "1_14": 1
    "2_2": 2
    "2_3": 2
    "2_6": 2
    "2_7": 2
    "2_8": 3
    "2_9": 3
    "2_12": 3
    "2_13": 3
    "4_1": 4
    "4_5": 4
    "4_9": 4
    "4_13": 4
    "4_2": 5
    "4_6": 5
    "4_10": 5
    "4_14": 5
    "8_4": 6
    "8_5": 6
    "8_6": 6
    "8_7": 6
    "8_8": 7
    "8_9": 7
    "8_10": 7
    "8_11": 7
    "1_5": 8
    "1_7": 8
    "1_13": 8
    "1_15": 8
    "2_10": 9
    "2_11": 9
    "2_14": 9
    "2_15": 9
    "4_3": 10
    "4_7": 10
    "4_11": 10
    "4_15": 10
    "8_12": 11
    "8_13": 11
    "8_14": 11
    "8_15": 11
    "5_1": 12
    "5_3": 12
    "5_7": 12
    "5_9": 12
    "5_11": 12
    "5_13": 12
    "5_15": 12
    "6_2": 13
    "6_3": 13
    "6_6": 13
    "6_7": 13
    "6_10": 13
    "6_11": 13
    "6_14": 13
    "6_15": 13
    "9_4": 14
    "9_5": 14
    "9_6": 14
    "9_7": 14
    "9_12": 14
    "9_13": 14
    "9_14": 14
    "9_15": 14
    "10_8": 15
    "10_9": 15
    "10_10": 15
    "10_11": 15
    "10_12": 15
    "10_13": 15
    "10_14": 15
    "10_15": 15

  tilemap = {}
  top_row_corners = 0
  top_row_mixed = 1
  top_row_sides = 2
  sides_row = 3
  bottom_row = 4
  geometry = new THREE.Geometry()
  i = 0
  while i < 16
    j = 0
    while j < 16
      mm = i + "_" + j
      if i is 0
        row = top_row_corners
      else unless mixmap[mm] is `undefined`
        row = top_row_mixed
      else
        row = top_row_sides
      tilemap[mm] = row
      j++
    i++
  z = 0
  while z < worldDepth
    x = 0
    while x < worldWidth
      h = getY(x, z)
      
      # direct neighbors
      h2 = getY(x - 1, z)
      nleft = h2 is h or h2 is h + 1
      h2 = getY(x + 1, z)
      nright = h2 is h or h2 is h + 1
      h2 = getY(x, z + 1)
      nback = h2 is h or h2 is h + 1
      h2 = getY(x, z - 1)
      nfront = h2 is h or h2 is h + 1
      
      # corner neighbors
      nrb = (if getY(x - 1, z + 1) is h and x > 0 and z < worldDepth - 1 then 1 else 0)
      nrf = (if getY(x - 1, z - 1) is h and x > 0 and z > 0 then 1 else 0)
      nlb = (if getY(x + 1, z + 1) is h and x < worldWidth - 1 and z < worldDepth - 1 then 1 else 0)
      nlf = (if getY(x + 1, z - 1) is h and x < worldWidth - 1 and z > 0 then 1 else 0)
      
      # up neighbors
      nleftup = (if getY(x - 1, z) > h and x > 0 then 1 else 0)
      nrightup = (if getY(x + 1, z) > h and x < worldWidth - 1 then 1 else 0)
      nbackup = (if getY(x, z + 1) > h and z < worldDepth - 1 then 1 else 0)
      nfrontup = (if getY(x, z - 1) > h and z > 0 then 1 else 0)
      
      # up corner neighbors
      nrbup = (if getY(x - 1, z + 1) > h and x > 0 and z < worldDepth - 1 then 1 else 0)
      nrfup = (if getY(x - 1, z - 1) > h and x > 0 and z > 0 then 1 else 0)
      nlbup = (if getY(x + 1, z + 1) > h and x < worldWidth - 1 and z < worldDepth - 1 then 1 else 0)
      nlfup = (if getY(x + 1, z - 1) > h and x < worldWidth - 1 and z > 0 then 1 else 0)
      
      # textures
      ti = nleftup * 8 + nrightup * 4 + nfrontup * 2 + nbackup * 1
      ri = nrf * 8 + nrb * 4 + 1
      li = nlb * 8 + nlf * 4 + 1
      bi = nrb * 8 + nlb * 4 + 1
      fi = nlf * 8 + nrf * 4 + 1
      ci = nlbup * 8 + nlfup * 4 + nrbup * 2 + nrfup * 1
      
      # cube sides
      px = nx = pz = nz = 0
      px = (if not nright or x is 0 then 1 else 0)
      nx = (if not nleft or x is worldWidth - 1 then 1 else 0)
      pz = (if not nback or z is worldDepth - 1 then 1 else 0)
      nz = (if not nfront or z is 0 then 1 else 0)
      sides =
        px: px
        nx: nx
        py: true
        ny: false
        pz: pz
        nz: nz

      cube = new THREE.CubeGeometry(100, 100, 100, 1, 1, 1, materials, sides)
      
      # revert back to old flipped UVs
      i = 0
      while i < cube.faceVertexUvs[0].length
        uv = cube.faceVertexUvs[0][i]
        j = 0
        while j < uv.length
          uv[j].v = 1 - uv[j].v
          j++
        i++
      
      # set UV tiles
      i = 0
      while i < cube.faceVertexUvs[0].length
        uv = cube.faceVertexUvs[0][i]
        j = 0
        while j < uv.length
          p = (if uv[j].u is 0 then padding else -padding)
          uv[j].u = uv[j].u * unit + p
          p = (if uv[j].v is 0 then padding else -padding)
          uv[j].v = uv[j].v * unit + p
          j++
        i++
      hash = px * 8 + nx * 4 + pz * 2 + nz
      face_px = uv_index_map[hash].px
      face_nx = uv_index_map[hash].nx
      face_py = uv_index_map[hash].py
      face_ny = uv_index_map[hash].ny
      face_pz = uv_index_map[hash].pz
      face_nz = uv_index_map[hash].nz
      setUVTile face_px, ri, sides_row  unless face_px is N
      setUVTile face_nx, li, sides_row  unless face_nx is N
      unless face_py is N
        mm = ti + "_" + ci
        switch tilemap[mm]
          when top_row_sides
            column = ti
          when top_row_corners
            column = ci
          when top_row_mixed
            column = mixmap[mm]
        setUVTile face_py, column, tilemap[mm]
      setUVTile face_ny, 0, bottom_row  unless face_ny is N
      setUVTile face_pz, bi, sides_row  unless face_pz is N
      setUVTile face_nz, fi, sides_row  unless face_nz is N
      mesh = new THREE.Mesh(cube)
      mesh.position.x = x * 100 - worldHalfWidth * 100
      mesh.position.y = h * 100
      mesh.position.z = z * 100 - worldHalfDepth * 100
      THREE.GeometryUtils.merge geometry, mesh
      x++
    z++
  mesh = new THREE.Mesh(geometry, new THREE.MeshFaceMaterial())
  scene.add mesh
  #ambientLight = new THREE.AmbientLight(0xff0000)
  #scene.add ambientLight
  directionalLight = new THREE.DirectionalLight(0xff0000, 2)
  directionalLight.position.set(1, 1, 0.5).normalize()
  scene.add directionalLight

  directionalLight = new THREE.DirectionalLight(0xff7c00, 2)
  directionalLight.position.set(0, 0, -1).normalize()
  scene.add directionalLight

  skybox = new THREE.Mesh( new THREE.SphereGeometry( 22000, 60, 40 ), new THREE.MeshBasicMaterial( { map: THREE.ImageUtils.loadTexture( 'skybox.png' ) } ) );
  skybox.scale.x = -1;
  skybox.position = camera.position
  scene.add skybox


  renderer = new THREE.WebGLRenderer(clearColor: 0xff0000)
  renderer.setSize window.innerWidth, window.innerHeight
  container.innerHTML = ""
  container.appendChild renderer.domElement
  stats = new Stats()
  stats.domElement.style.position = "absolute"
  stats.domElement.style.top = "0px"
  container.appendChild stats.domElement
  document.getElementById("bao").addEventListener "click", (->
    mat.map = m_ao.map
  ), false
  document.getElementById("baot").addEventListener "click", (->
    mat.map = m_aot.map
  ), false
  document.getElementById("bt").addEventListener "click", (->
    mat.map = m_t.map
  ), false
  
  #
  window.addEventListener "resize", onWindowResize, false
onWindowResize = ->
  camera.aspect = window.innerWidth / window.innerHeight
  camera.updateProjectionMatrix()
  renderer.setSize window.innerWidth, window.innerHeight
  controls.handleResize()
generateMegamaterialAO = (textures, strength, debug_texture, debug_numbers, debug_corner_colors) ->
  generateTexture = ->
    if count is 3
      i = 0

      while i < 16
        drawAOCorners ctx, tex_top, 0, i, i, tile, strength, debug_texture, debug_numbers, debug_corner_colors
        drawAOMixed ctx, tex_top, 1, i, i, tile, strength, debug_texture, debug_numbers, debug_corner_colors
        drawAOSides ctx, tex_top, 2, i, i, tile, strength, debug_texture, debug_numbers
        drawAOSides ctx, tex_side, 3, i, i, tile, strength, debug_texture, debug_numbers
        drawAOSides ctx, tex_bottom, 4, i, i, tile, strength, debug_texture, debug_numbers
        i++
      texture.needsUpdate = true
  count = 0
  tex_side = loadTexture(textures.side, ->
    count++
    generateTexture()
  )
  tex_top = loadTexture(textures.top, ->
    count++
    generateTexture()
  )
  tex_bottom = loadTexture(textures.bottom, ->
    count++
    generateTexture()
  )
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")
  size = 256
  tile = 16
  canvas.width = canvas.height = size
  texture = new THREE.Texture(canvas, new THREE.UVMapping(), THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.NearestFilter, THREE.LinearMipMapLinearFilter)
  texture.flipY = false
  new THREE.MeshLambertMaterial(
    map: texture
    ambient: 0xbbbbbb
  )
generateMegamaterialPlain = (textures) ->
  generateTexture = ->
    if count is 3
      i = undefined
      sx = undefined
      i = 0
      while i < 16
        sx = i * tile
        drawBase ctx, tex_top, sx, 0 * tile, tile, false
        drawBase ctx, tex_top, sx, 1 * tile, tile, false
        drawBase ctx, tex_top, sx, 2 * tile, tile, false
        drawBase ctx, tex_side, sx, 3 * tile, tile, false
        drawBase ctx, tex_bottom, sx, 4 * tile, tile, false
        i++
      texture.needsUpdate = true
  count = 0
  tex_side = loadTexture(textures.side, ->
    count++
    generateTexture()
  )
  tex_top = loadTexture(textures.top, ->
    count++
    generateTexture()
  )
  tex_bottom = loadTexture(textures.bottom, ->
    count++
    generateTexture()
  )
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")
  size = 256
  tile = 16
  canvas.width = canvas.height = size
  texture = new THREE.Texture(canvas, new THREE.UVMapping(), THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.NearestFilter, THREE.LinearMipMapLinearFilter)
  texture.flipY = false
  new THREE.MeshLambertMaterial(map: texture)
generateMegamaterialDebug = ->
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")
  size = 256
  tile = 16
  i = undefined
  j = undefined
  h = undefined
  s = undefined
  canvas.width = size
  canvas.height = size
  ctx.textBaseline = "top"
  ctx.font = "8pt arial"
  i = 0
  while i < tile
    j = 0
    while j < tile
      h = i * tile + j
      ctx.fillStyle = "hsl(" + h + ",90%, 50%)"
      ctx.fillRect i * tile, j * tile, tile, tile
      drawHex ctx, h, i * tile + 2, j * tile + 2
      j++
    i++
  texture = new THREE.Texture(canvas, new THREE.UVMapping(), THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.NearestFilter, THREE.LinearMipMapLinearFilter)
  texture.needsUpdate = true
  new THREE.MeshLambertMaterial(map: texture)
drawHex = (ctx, n, x, y) ->
  ctx.fillStyle = "black"
  ctx.font = "8pt arial"
  ctx.textBaseline = "top"
  s = n.toString(16)
  s = (if n < 16 then "0" + s else s)
  ctx.fillText s, x, y
drawBase = (ctx, image, sx, sy, tile, debug_texture) ->
  if debug_texture
    ctx.fillStyle = "#888"
    ctx.fillRect sx, sy, tile, tile
  else
    ctx.drawImage image, sx, sy, tile, tile
drawCorner = (ctx, sx, sy, sa, ea, color, step, n) ->
  i = 0

  while i < n
    ctx.strokeStyle = color + step * (n - i) + ")"
    ctx.beginPath()
    ctx.arc sx, sy, i, sa, ea, 0
    ctx.stroke()
    i++
drawSide = (ctx, sx, sy, a, b, n, width, height, color, step) ->
  i = 0

  while i < n
    ctx.fillStyle = color + step * (n - i) + ")"
    ctx.fillRect sx + a * i, sy + b * i, width, height
    i++
drawAOSides = (ctx, image, row, column, sides, tile, strength, debug_texture, debug_numbers) ->
  sx = column * tile
  sy = row * tile
  drawBase ctx, image, sx, sy, tile, debug_texture
  drawAOSidesImp ctx, image, row, column, sides, tile, strength
  drawHex ctx, row * tile + sides, sx + 2, sy + 2  if debug_numbers
drawAOCorners = (ctx, image, row, column, corners, tile, strength, debug_texture, debug_numbers, debug_corner_colors) ->
  sx = column * tile
  sy = row * tile
  drawBase ctx, image, sx, sy, tile, debug_texture
  drawAOCornersImp ctx, image, row, column, corners, tile, strength, debug_corner_colors
  drawHex ctx, row * tile + corners, sx + 2, sy + 2  if debug_numbers
drawAOMixed = (ctx, image, row, column, elements, tile, strength, debug_texture, debug_numbers, debug_corner_colors) ->
  sx = column * tile
  sy = row * tile
  mmap =
    0: [1, 1]
    1: [1, 4]
    2: [2, 2]
    3: [2, 8]
    4: [4, 1]
    5: [4, 2]
    6: [8, 4]
    7: [8, 8]
    8: [1, 5]
    9: [2, 10]
    10: [4, 3]
    11: [8, 12]
    12: [5, 1]
    13: [6, 2]
    14: [9, 4]
    15: [10, 8]

  drawBase ctx, image, sx, sy, tile, debug_texture
  drawAOCornersImp ctx, image, row, column, mmap[elements][1], tile, strength, debug_corner_colors
  drawAOSidesImp ctx, image, row, column, mmap[elements][0], tile, strength
  drawHex ctx, row * tile + elements, sx + 2, sy + 2  if debug_numbers
drawAOSidesImp = (ctx, image, row, column, sides, tile, strength) ->
  sx = column * tile
  sy = row * tile
  full = tile
  step = 1 / full
  half = full / 2 + strength
  color = "rgba(0, 0, 0, "
  left = (sides & 8) is 8
  right = (sides & 4) is 4
  bottom = (sides & 2) is 2
  top = (sides & 1) is 1
  drawSide ctx, sx, sy, 0, 1, half, tile, 1, color, step  if bottom
  drawSide ctx, sx, sy + full - 1, 0, -1, half, tile, 1, color, step  if top
  drawSide ctx, sx, sy, 1, 0, half, 1, tile, color, step  if left
  drawSide ctx, sx + full - 1, sy, -1, 0, half, 1, tile, color, step  if right
drawAOCornersImp = (ctx, image, row, column, corners, tile, strength, debug_corner_colors) ->
  sx = column * tile
  sy = row * tile
  full = tile
  step = 1 / full
  half = full / 2 + strength
  color = "rgba(0, 0, 0, "
  bottomright = (corners & 8) is 8
  topright = (corners & 4) is 4
  bottomleft = (corners & 2) is 2
  topleft = (corners & 1) is 1
  if topleft
    color = "rgba(200, 0, 0, "  if debug_corner_colors
    drawCorner ctx, sx, sy, 0, Math.PI / 2, color, step, half
  if bottomleft
    color = "rgba(0, 200, 0, "  if debug_corner_colors
    drawCorner ctx, sx, sy + full, 1.5 * Math.PI, 2 * Math.PI, color, step, half
  if bottomright
    color = "rgba(0, 0, 200, "  if debug_corner_colors
    drawCorner ctx, sx + full, sy + full, Math.PI, 1.5 * Math.PI, color, step, half
  if topright
    color = "rgba(200, 0, 200, "  if debug_corner_colors
    drawCorner ctx, sx + full, sy, Math.PI / 2, Math.PI, color, step, half
loadTexture = (path, callback) ->
  image = new Image()
  image.onload = ->
    callback()

  image.src = path
  image
generateHeight = (width, height) ->
  data = []
  perlin = new ImprovedNoise()
  size = width * height
  quality = 2
  z = Math.random() * 100
  j = 0

  while j < 4
      if j is 0
          i = 0

      while i < size
        data[i] = 0
        i++
      i = 0

      while i < size
        x = i % width
        y = ~~(i / width)
        data[i] += perlin.noise(x / quality, y / quality, z) * quality
        i++
      quality *= 4
      j++
  data
getY = (x, z) ->
  ~~(data[x + z * worldWidth] * 0.2)

loadSkybox = ( path ) ->

        texture = new THREE.Texture( texture_placeholder );
        material = new THREE.MeshBasicMaterial( { map: texture, overdraw: true } );

        image = new Image();
        image.onload = () ->

          texture.needsUpdate = true;
          material.map.image = @

          render();

        
        image.src = path;

        material;

      


#
animate = ->
  requestAnimationFrame animate
  render()
  stats.update()
render = ->
  controls.update clock.getDelta()
  renderer.render scene, camera
unless Detector.webgl
  Detector.addGetWebGLMessage()
  document.getElementById("container").innerHTML = ""

clock = new THREE.Clock()

data = generateHeight(worldWidth, worldDepth)

init()
animate()