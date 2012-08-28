
window = {}
importScripts "ImprovedNoise.js", "three.min.js", "underscore-min.js"


# Static configuration variables, working

PLAYER_HEIGHT     = 250
PLAYER_SPEED      = 500
FOG               = true
FOG_DENSITY       = 0.00008
NUM_BUILDINGS     = 50
FLYMODE           = false
PLAYER_LIMIT_VIEW = false
WORLD_SIZE        = 750
WORLD_HEIGHT      = 128
SECTOR_SIZE       = 150

# probably not working ...

UV_COPY           = false
SHADOWS           = false
CHUNK_SIZE        = [ 16, 16, 128 ]



class Utils  # var Utils = function() {

    @time = (fn, label = "") -> # this.time = function(fn, label) { if (typeof label == 'undefined') label = "";
        start = new Date()
        x = fn()
        console.log "#{label} elapsed in #{(new Date() - start) / 1000}s"
        x



# Optimized extension to THREE.js, caching the materials map since it is static
# and is O(n) on reads.  This is copied directly from the THREE.js source code
# at [fill me in]

geo1MaterialsMap = {}
old_index = 0

THREE.GeometryUtils.merge_batch = (geometry1, object2) ->

    matrix         = undefined
    matrixRotation = undefined
    vertexOffset   = geometry1.vertices.length
    uvPosition     = geometry1.faceVertexUvs[0].length
    geometry2      = if object2 instanceof THREE.Mesh then object2.geometry else object2
    vertices1      = geometry1.vertices
    vertices2      = geometry2.vertices
    faces1         = geometry1.faces
    faces2         = geometry2.faces
    uvs1           = geometry1.faceVertexUvs[0]
    uvs2           = geometry2.faceVertexUvs[0]

    i = old_index
    
    while i < geometry1.materials.length
        id = geometry1.materials[i].id
        geo1MaterialsMap[id] = i
        i++

    old_index = geometry1.materials.length

    if object2 instanceof THREE.Mesh
        object2.matrixAutoUpdate and object2.updateMatrix()
        matrix = object2.matrix
        matrixRotation = new THREE.Matrix4()
        matrixRotation.extractRotation matrix, object2.scale
    
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
        else if face instanceof THREE.Face4
            faceCopy = new THREE.Face4(face.a + vertexOffset, face.b + vertexOffset, face.c + vertexOffset, face.d + vertexOffset)

        faceCopy.normal.copy face.normal
        matrixRotation.multiplyVector3 faceCopy.normal  if matrixRotation

        j = 0
        jl = faceVertexNormals.length
    
        while j < jl
            normal = faceVertexNormals[j] #.clone()
            matrixRotation.multiplyVector3 normal  if matrixRotation
            faceCopy.vertexNormals.push normal
            j++

        faceCopy.color.copy face.color

        j = 0
        jl = faceVertexColors.length
    
        while j < jl
             color = faceVertexColors[j]
             faceCopy.vertexColors.push color #.clone()
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
  
        if UV_COPY
            uvCopy = []
            j = 0
            jl = uv.length
          
            while j < jl
                uvCopy.push new THREE.UV(uv[j].u, uv[j].v)
                j++

            uv = ucCopy
  
        uvs1.push uv
        i++
    
    null
    



# These are some performance enchancing cached geometries - don't
# recalculate every possible variation on the cube mesh representing
# a single cell, given its neighbors.

class WorldPrimitives

    @cube_specs = 

        for nx in [ 0, 1 ]
            for px in [ 0, 1 ]
                for ny in [ 0, 1 ]
                    for py in [ 0, 1 ]
                        for nz in [ 0, 1 ]
                            for pz in [ 0, 1 ]
    
                                { nx: nx, px: px, ny: ny, py: py, nz: nz, pz: pz }

    material = new THREE.MeshLambertMaterial color: 0xffffff

    @cubes =

        for spec in _.flatten @cube_specs
            new THREE.CubeGeometry 100, 100, 100, 1, 1, 1, material, spec



# This class is (currently) responsible for both generating the logical
# array representing the acutal world structure, and generating a
# THREE.Mesh from it.

class World



    # Creating a new world is a costly process, as it generates a new
    # world from scratch *and* initializes the THREE.Mesh instances.

    constructor: (app, @width, @height, @depth, @sector_size) ->

        { @renderer, @scene, @camera } = app

        @data = Utils.time @generate_terrain, "Generated terrain"

        for i in [0..NUM_BUILDINGS]
            width = Math.floor Math.random() * 10 + 8
            height = Math.floor Math.random() * 30 + 1

            x = Math.floor Math.random() * (@width - width)
            y = Math.floor Math.random() * (@height - width)

            Utils.time (=> @add_building x, y, width, height), "Added building (type A) at (#{x}, #{y})"

    #    Utils.time @init_renderer, "Initialized #{@width}x#{@height}x#{@depth} world with #{@sector_size} sectors"



    # Draws a specific sector of the world's geometry.   The world geometry
    # is an argument for memory efficiency, as mutations are dramatically
    # more memory efficient than naive array copies ...

    # TODO geometry should be an instance var

    draw_sector: (x, y, resolution) =>

    	geometry = new THREE.Geometry()

        for dx in [x * @sector_size .. (x + 1) * @sector_size - 1] by resolution
            for dy in  [y * @sector_size .. (y + 1) * @sector_size - 1] by resolution
                for dz in [0 .. @depth - 1] by resolution
                    cell = @data[dx][dy][dz]
    
                    if cell == 1
    
                        nx = not ~~@data[dx - resolution]?[dy][dz]
                        px = not ~~@data[dx + resolution]?[dy][dz]
                        nz = not ~~@data[dx][dy - resolution]?[dz] 
                        pz = not ~~@data[dx][dy + resolution]?[dz] 
                        ny = not ~~@data[dx][dy][dz - resolution]
                        py = not ~~@data[dx][dy][dz + resolution] 
    
                        index = nx*32 + px*16 + ny*8 + py*4 + nz*2 + pz
    
                        if index != 0
                            geo = WorldPrimitives.cubes[index]
                            mesh = new THREE.Mesh geo
                            mesh.scale.x = resolution
                            mesh.scale.y = resolution
                            mesh.scale.z = resolution
                            mesh.position.x = dx * 100 + resolution * 50
                            mesh.position.y = dz * 100 + resolution * 50
                            mesh.position.z = dy * 100 + resolution * 50

                            THREE.GeometryUtils.merge_batch @geometry, mesh
    
        geometry



    # Initialize the canvas, camera, skybox, fog, particles, lights, etc.

    init_renderer: =>

        
        @geometry = new THREE.Geometry()
        mid = Math.floor (@width / @sector_size) / 2

        for i in [0 .. @width / @sector_size - 1]
            for j in [0 .. @height / @sector_size - 1]
                resolution = Math.pow 2, Math.max(Math.abs(mid - i), Math.abs(mid - j))
                Utils.time (=> @draw_sector i, j, Math.ceil resolution), "Generated geometry (#{i}, #{j}) at #{resolution}"
                
        @scene.add new THREE.Mesh(@geometry, new THREE.MeshFaceMaterial())

       





    # Generate a random building

    add_building: (x, y, width, height) =>

        for xx in [x .. x + width]
            for yy in [y .. y + width]
                for zz in [0 .. @depth - height]
                    @data[xx][yy][zz] = 1 if zz % 2 == 0
                @data[xx][yy][@depth - 1] = 0

        null

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


        buffer =
            for i in [0 .. @width]
                for j in [0 .. @height]
                   # new Uint8Array @depth
                    for k in [0 .. @depth]
                        0

        for x in [ 0 .. @width - 1 ]
            for y in [ 0 .. @height - 1 ]

                is_underground = true

                for z in [ 0 .. @depth - 1 ]
                    if z > ((data[ x * @width + y ] - min) / (max - min)) * (@depth - 30) then is_underground = false
                    if is_underground then buffer[x][y][z] = 1 else buffer[x][y][z] = 0

        buffer

world = new World @, WORLD_SIZE, WORLD_SIZE, WORLD_HEIGHT, SECTOR_SIZE


post = (e) ->
	self.postMessage 'message', (world.draw_sector e.data.x, e.data.y, e.data.resolution)

self.addEventListener 'message', post, false





