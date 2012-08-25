
PLAYER_HEIGHT = 300
FOG = true
NUM_BUILDINGS = 50
FLYMODE = true

class Utils

    @time = (fn, label = "") ->
        start = new Date()
        x = fn()
        console.log "#{label} elapsed in #{(new Date() - start) / 1000}s"
        x


# These are some performance enchancing cached geometries        

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
            @add_building()

        @init_renderer()

    draw_sector: (x, y, resolution) =>

        geometry = new THREE.Geometry()

        dx = x * @sector_size
        while dx < (x + 1) * @sector_size
            slice = @data[ dx ]

            dy = y * @sector_size
            while dy < (y + 1) * @sector_size
                column = slice[dy]

                dz = 0
                while dz < column.length - 1
                    cell = column[dz]

                    if cell == 1

                        nx = not ~~@data[dx - resolution]?[dy][dz]
                        px = not ~~@data[dx + resolution]?[dy][dz]
                        nz = not ~~slice[dy - resolution]?[dz]
                        pz = not ~~slice[dy + resolution]?[dz]
                        ny = not ~~column[dz - resolution]
                        py = not ~~column[dz + resolution]

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
                dy += resolution
            dx += resolution
        # mesh.castShadow = true
        # mesh.receiveShadow = true

        geometry.mergeVertices()
        mesh = new THREE.Mesh geometry, new THREE.MeshFaceMaterial()
        mesh.position.x += resolution * 50
        mesh.position.z += resolution * 50
        mesh


    init_renderer: =>

        @camera.position.x = @width * 100 / 2
        @camera.position.z = @width * 100 / 2
        if FOG then @scene.fog = new THREE.FogExp2 0xff0000, 0.00002

        geometry = new THREE.Geometry()

        i = 0
        while i < 5
            j = 0
            while j < 5
                #if i isnt 2 or j isnt 2
                resolution = Math.pow 2, Math.max(Math.abs(2 - i), Math.abs(2 - j))
                THREE.GeometryUtils.merge geometry, Utils.time (=> @draw_sector i, j, Math.ceil resolution), "Generated geometry (#{i}, #{j}) at #{resolution}"
                j++
            i++

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

    add_building: =>
        width = 10

        x = Math.floor Math.random() * (@width - width)
        y = Math.floor Math.random() * (@height - width)

        console.log "#{x} #{y}"

        for xx in [x .. x + width]
            for yy in [y .. y + width]
                @data[xx][yy] =
                    for zz in [0 .. @data[xx][yy].length - 1]
                        if zz % 2 == 0 then 1 else @data[xx][yy][zz]
                @data[xx][yy][@depth - 1] = 0

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


        for x in [ 0 .. @width - 1 ]
            for y in [ 0 .. @height - 1 ]

                is_underground = true

                buffer = new Uint16Array @depth

                for z in [ 0 .. @depth - 1 ]
                    if z > ((data[ x * @width + y ] - min) / (max - min)) * (@depth - 30) then is_underground = false
                    if is_underground then buffer[z] = 1 else buffer[z] = 0

                buffer

    getY = (x, z) => ~~(data[x + z * @world_width] * 0.2)



# Game instance

class Application

    container: document.getElementById "container"
  
    renderer: new THREE.WebGLRenderer(clearColor: 0xff0000)
    stats:    new Stats()
    clock:    new THREE.Clock()
    camera:   new THREE.PerspectiveCamera 50, window.innerWidth / window.innerHeight, 1, 500000
    controls: undefined
    scene:    new THREE.Scene()
    
    constructor: ->
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

        @world = new World @, 1000, 1000, 100, 200

        setTimeout @animate, 0

    gravity: 5
    delta_y: 0

    
    animate: =>
        requestAnimationFrame @animate

        x = Math.max(Math.floor((@camera.position.x - 50) / 100), 0)
        z = Math.max(Math.floor((@camera.position.z - 50) / 100), 0)

        column = @world.data[x][z]

        if not FLYMODE
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

window.onload = -> new Application

