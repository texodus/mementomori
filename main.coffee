
PLAYER_HEIGHT = 300
FOG = true
NUM_BUILDINGS = 2
FLYMODE = true

class Utils

    @time = (fn, label = "") ->
        start = new Date()
        x = fn()
        console.log "#{label} elapsed in #{(new Date() - start) / 1000}s"
        x

THREE.GeometryUtils.merge_batch = (geometry1, geometries) ->

    matrix = undefined
    matrixRotation = undefined
    vertexOffset = geometry1.vertices.length
    uvPosition = geometry1.faceVertexUvs[0].length
    vertices1 = geometry1.vertices
    faces1 = geometry1.faces
    uvs1 = geometry1.faceVertexUvs[0]
    geo1MaterialsMap = {}
    i = 0
  
    while i < geometry1.materials.length
      id = geometry1.materials[i].id
      geo1MaterialsMap[id] = i
      i++
  
    for object2 in geometries
  
        geometry2 = (if object2 instanceof THREE.Mesh then object2.geometry else object2)
        vertices2 = geometry2.vertices
        faces2 = geometry2.faces
        uvs2 = geometry2.faceVertexUvs[0]
      
        if object2 instanceof THREE.Mesh
          object2.matrixAutoUpdate and object2.updateMatrix()
          matrix = object2.matrix
          matrixRotation = new THREE.Matrix4()
          matrixRotation.extractRotation matrix, object2.scale
        
        # vertices
        i = 0
        il = vertices2.length
      
        while i < il
          vertex = vertices2[i]
          vertexCopy = vertex.clone()
          matrix.multiplyVector3 vertexCopy  if matrix
          vertices1.push vertexCopy
          i++
        
        # faces
        i = 0
        il = faces2.length
      
        while i < il
          face = faces2[i]
          faceCopy = undefined
          normal = undefined
          color = undefined
          faceVertexNormals = face.vertexNormals
          faceVertexColors = face.vertexColors
          if face instanceof THREE.Face3
            faceCopy = new THREE.Face3(face.a + vertexOffset, face.b + vertexOffset, face.c + vertexOffset)
          else faceCopy = new THREE.Face4(face.a + vertexOffset, face.b + vertexOffset, face.c + vertexOffset, face.d + vertexOffset)  if face instanceof THREE.Face4
          faceCopy.normal.copy face.normal
          matrixRotation.multiplyVector3 faceCopy.normal  if matrixRotation
          j = 0
          jl = faceVertexNormals.length
      
          while j < jl
            normal = faceVertexNormals[j].clone()
            matrixRotation.multiplyVector3 normal  if matrixRotation
            faceCopy.vertexNormals.push normal
            j++
          faceCopy.color.copy face.color
          j = 0
          jl = faceVertexColors.length
      
          while j < jl
            color = faceVertexColors[j]
            faceCopy.vertexColors.push color.clone()
            j++
          if face.materialIndex isnt `undefined`
            material2 = geometry2.materials[face.materialIndex]
            materialId2 = material2.id
            materialIndex = geo1MaterialsMap[materialId2]
            if materialIndex is `undefined`
              materialIndex = geometry1.materials.length
              geo1MaterialsMap[materialId2] = materialIndex
              geometry1.materials.push material2
            faceCopy.materialIndex = materialIndex
          faceCopy.centroid.copy face.centroid
          matrix.multiplyVector3 faceCopy.centroid  if matrix
          faces1.push faceCopy
          i++
        
        # uvs
        i = 0
        il = uvs2.length
      
        while i < il
          uv = uvs2[i]
          uvCopy = []
          j = 0
          jl = uv.length
      
          while j < jl
            uvCopy.push new THREE.UV(uv[j].u, uv[j].v)
            j++
          uvs1.push uvCopy
          i++

    null





#   These are some performance enchancing cached geometries        

class WorldPrimitives

    @cube_specs = 

        for nx in [ 0, 1 ]
            for px in [ 0, 1 ]
                for ny in [ 0, 1 ]
                    for py in [ 0, 1 ]
                        for nz in [ 0, 1 ]
                            for pz in [ 0, 1 ]
    
                                { nx: nx, px: px, ny: ny, py: py, nz: nz, pz: pz }

    material = new THREE.MeshLambertMaterial color: 0xff0000

    @cubes =

        for spec in _.flatten @cube_specs
            new THREE.CubeGeometry 100, 100, 100, 1, 1, 1, material, spec


class World

    constructor: (app, @width, @height, @depth, @sector_size) ->

        { @renderer, @scene, @camera } = app

        @data = Utils.time @generate_terrain, "Generated terrain"

        for i in [0..NUM_BUILDINGS]
            width = 10

            x = Math.floor Math.random() * (@width - width)
            y = Math.floor Math.random() * (@height - width)

            Utils.time (=> @add_building x, y, width), "Added building (type A) at (#{x}, #{y})"

        Utils.time @init_renderer, "Initialized #{@width}x#{@height}x#{@depth} world with #{@sector_size} sectors"

    draw_sector: (x, y, resolution) =>

        geometry = new THREE.Geometry()

        dx = x * @sector_size
        while dx < (x + 1) * @sector_size
            dy = y * @sector_size
            while dy < (y + 1) * @sector_size
                dz = 0
                while dz < @depth - 1
                    cell = @data.get(dx, dy, dz)

                    if cell == 1

                        nx = not ~~@data.get(dx - resolution, dy, dz)
                        px = not ~~@data.get(dx + resolution, dy, dz)
                        nz = not ~~@data.get(dx, dy - resolution, dz)
                        pz = not ~~@data.get(dx, dy + resolution, dz)
                        ny = not ~~@data.get(dx, dy, dz - resolution)
                        py = not ~~@data.get(dx, dy, dz + resolution)

                        index = nx*32 + px*16 + ny*8 + py*4 + nz*2 + pz

                        #geo = new THREE.CubeGeometry 100, 100, 100, 1, 1, 1, new THREE.MeshLambertMaterial({color: 0xff0000})
                        if index != 0
                            geo = WorldPrimitives.cubes[index]
                            mesh = new THREE.Mesh geo
                            mesh.scale.x = resolution
                            mesh.scale.y = resolution
                            mesh.scale.z = resolution
                            mesh.position.x = dx * 100
                            mesh.position.y = dz * 100
                            mesh.position.z = dy * 100
    
                            THREE.GeometryUtils.merge geometry, mesh

                    dz += resolution
                    #geometry.mergeVertices()
                dy += resolution
            dx += resolution
        # mesh.castShadow = true
        # mesh.receiveShadow = true

        geometry


    init_renderer: =>

        @camera.position.x = @width * 100 / 2
        @camera.position.z = @width * 100 / 2
        if FOG then @scene.fog = new THREE.FogExp2 0xff0000, 0.00002

        geometry = new THREE.Geometry()

        mid = Math.floor (@width / @sector_size) / 2

        geos = 
            for i in [0 .. @width / @sector_size - 1]
                for j in [0 .. @height / @sector_size - 1]
    
                    resolution = Math.pow 2, Math.max(Math.abs(mid - i), Math.abs(mid - j))
                    geo = Utils.time (=> @draw_sector i, j, Math.ceil resolution), "Generated geometry (#{i}, #{j}) at #{resolution}"
                    
                    mesh = new THREE.Mesh geo, new THREE.MeshFaceMaterial()
                    mesh.position.x += resolution * 50
                    mesh.position.z += resolution * 50
                    mesh

        THREE.GeometryUtils.merge_batch geometry, _.flatten geos

        @scene.add new THREE.Mesh(geometry, new THREE.MeshFaceMaterial())

        directionalLight = new THREE.DirectionalLight(0xff0000, 1)
        directionalLight.position.set 1, 1, 0.5
        directionalLight.target.position.set(-1 , -1 , -0.5)
        @scene.add directionalLight

        directionalLight = new THREE.DirectionalLight(0xff7c00, 2)
        directionalLight.position.set(0, 0, 1)
        @scene.add directionalLight

        # for x in [0 .. 1]
        #     for y in [0]

        #         light = @create_shadow (x * 5000) + 1000, 6000, (y * 5000) + 1000, (x * 5000) - 1000, 0, (y * 5000) - 1000, 2500

        skybox = new THREE.Mesh( new THREE.SphereGeometry( 90000, 60, 40 ), new THREE.MeshBasicMaterial( { map: THREE.ImageUtils.loadTexture( 'skybox.png' ), fog: false } ) );
        skybox.scale.x = -1;
        skybox.position = @camera.position
        @scene.add skybox





    #### Private

    # Convenience to load a texture & do some wiring

    loadTexture = (path, callback) ->
        image        = new Image()
        image.onload = callback
        image.src    = path
        image



    # Generate a random building

    add_building: (x, y, width) =>

        for xx in [x .. x + width]
            for yy in [y .. y + width]
                for zz in [0 .. @depth - 1]
                    @data.set(xx, yy, zz, 1) if zz % 2 == 0
                @data.set(xx, yy, @depth - 1, 0)

    create_shadow: (x1, y1, z1, x2, y2, z2, s) =>
        shadow = new THREE.DirectionalLight(0x000000, 0)

        shadow.position.set(x1, y1, z1)
        shadow.target.position.set(x2, y2, z2)
        shadow.castShadow = true
        shadow.shadowDarkness = 0.8
        shadow.shadowCameraVisible = true
        shadow.shadowCameraLeft = -s;
        shadow.shadowCameraRight = s;
        shadow.shadowCameraTop = s;
        shadow.shadowCameraBottom = -s;
        shadow.shadowCameraFar = 20000
        shadow.shadowMapWidth = 4096
        shadow.shadowMapHeight = 4096
        shadow.shadowBias = 0.0005

        shadow



    # Generates the world array.

    generate_terrain: =>
        data    = []
        perlin  = new ImprovedNoise()
        size    = @width * @height
        quality = 2

        z = Math.random() * 100
        j = 0
        min = 10000000000
        max = -10000000000
      
        while j < 4
            if j is 0
                i = 0
      
            while i < size
                data[i] = 0
                i++

            i = 0
      
            while i < size
                x = i % @width
                y = ~~(i / @width)
                data[i] += perlin.noise(x / quality, y / quality, z) * quality
                i++

            quality *= 4
            j++

        for item in data
            min = Math.min item, min
            max = Math.max item, max


        buffer = new UnboxedArray(@width, @height, @depth)

        for x in [ 0 .. @width - 1 ]
            for y in [ 0 .. @height - 1 ]

                is_underground = true

                for z in [ 0 .. @depth - 1 ]
                    if z > ((data[ x * @width + y ] - min) / (max - min)) * (@depth - 30) then is_underground = false
                    if is_underground then buffer.set(x, y, z, 1) else buffer.set(x, y, z, 0)

        buffer


class UnboxedArray

    constructor: (@width, @height, @depth) ->

        @array =
            for i in [0 .. @width]
                for j in [0 .. @height]
                    for k in [0 .. @depth]
                        0
                #new Array @height * @depth


    get: (x, y, z) =>
        if 0 <= x <= @width and 0 <= y <= @height and 0 <= z <= @depth
            @array[x][y][z]

    set: (x, y, z, q) =>
        @array[x][y][z] = q


# Game instance

class Application

    renderer: new THREE.WebGLRenderer(clearColor: 0xff0000)
    stats:    new Stats()
    clock:    new THREE.Clock()
    camera:   new THREE.PerspectiveCamera 50, window.innerWidth / window.innerHeight, 1, 500000
    controls: undefined
    scene:    new THREE.Scene()
    
    constructor: ->

        @container = document.getElementById "container"

        @controls = new THREE.FirstPersonControls @camera
        @renderer.setSize window.innerWidth, window.innerHeight
        # @renderer.shadowMapEnabled = true
        # @renderer.shadowMapSoft = true
        # @renderer.shadowMapBias = 10
        # @renderer.shadowCameraNear = 3;
        # @renderer.shadowCameraFar = @camera.far;
        # @renderer.shadowCameraFov = 90;

        @renderer.autoClear = false

        @container.innerHTML = ""
        @container.appendChild @renderer.domElement
        @stats.domElement.style.position = "absolute"
        @stats.domElement.style.top = "0px"
        @container.appendChild @stats.domElement
    
        @controls.movementSpeed = 1000
        @controls.lookSpeed = 0.125
        @controls.lookVertical = true
        @controls.constrainVertical = true
        # @controls.verticalMin = 1.1
        # @controls.verticalMax = 2.2

        window.addEventListener "resize", @onWindowResize, false

        @world = new World @, 100, 100, 100, 100

        setTimeout @animate, 0

    gravity: 5
    delta_y: 0

    
    animate: =>
        requestAnimationFrame @animate

        x = Math.max(Math.floor((@camera.position.x - 50) / 100), 0)
        z = Math.max(Math.floor((@camera.position.z - 50) / 100), 0)


        if not FLYMODE
            column = @world.data[x][z]
            height = 0
            while column[height] == 1
                height++
    
            ground = (height * 100) + PLAYER_HEIGHT
    
            if @camera.position.y > ground
                @delta_y += @gravity
                @camera.position.y -= @delta_y
                if @camera.position.y < ground then @camera.position.y = ground
            else if @camera.position.y < ground
                @delta_y = 0
                @camera.position.y = (ground - @camera.position.y) * 0.5 + @camera.position.y

        @render()
        @stats.update()
    
    render: =>
        @controls.update @clock.getDelta()
        @renderer.render @scene, @camera

    onWindowResize: =>
        console.log "Resize event"
        @camera.aspect = window.innerWidth / window.innerHeight
        @camera.updateProjectionMatrix()
        @renderer.setSize window.innerWidth, window.innerHeight
        @controls.handleResize()

unless Detector.webgl
    Detector.addGetWebGLMessage()
    document.getElementById("container").innerHTML = ""

$ -> new Application

