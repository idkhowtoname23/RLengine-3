local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        float x, y;
        uint8_t r, g, b, a;
    } Vertex;

    typedef struct {
        float x, y, z;
        float vx, vy, vz;
        float ox, oy, oz;
        float phase;
    } Particle;

    typedef struct {
        float x, y, z;
        float radius;
        float maxRadius;
        float speed;
        float force;
        bool active;
    } Shockwave;
]]

RLengine = {
    _VERSION = "3.0 Quantum Dynamics & PostFX",
    count = 0,
    maxCount = 3000000,
    fov = 600,
    bounds = {w = 1280, h = 720},
    
    cam = {
        x = 0, y = 0, z = -1000,
        pitch = 0, yaw = 0,
        orbit = false, orbitDist = 1100, orbitAngle = 0, orbitSpeed = 0.4
    },
    
    forceMode = 1,
    paletteMode = 1,
    shapeMode = 1,
    morphStrength = 0.0,
    targetMorph = 1.0,
    time = 0,
    
    useTrails = true,
    trailFade = 0.15,
    additiveBlend = true,
    pointSize = 1.5,
    showHUD = true,
    usePostFX = true,
    chromaticAberration = 1.5,

    maxShockwaves = 16,
    shockwaves = {}
}

local PALETTES = {
    function(t) return math.floor(255 * t), math.floor(255 * (1 - t)), 255, 255 end, -- Cyberpunk
    function(t) return 255, math.floor(230 * (t^1.5)), math.floor(70 * (1 - t)), 255 end, -- Inferno
    function(t) return math.floor(80 * t), 255, math.floor(110 * t), 255 end, -- Matrix
    function(t) return math.floor(120 * t), math.floor(220 * t), 255, 255 end, -- Plasma
    function(t) return math.floor(230 * t + 25), math.floor(30 * (1 - t)), 255, 255 end, -- Void
    function(t) return 255, math.floor(210 * t + 40), math.floor(40 * t), 255 end, -- Gold
    function(t) return math.floor(50 * (1 - t)), 255, math.floor(180 * t), 255 end, -- Acid Toxic
    function(t) return math.floor(255 * t), math.floor(120 * t), math.floor(220 * (1 - t)), 255 end -- Neon Synth
}

local Shapes = {
    cube = function(p, i)
        p.ox = (math.random() - 0.5) * 1800
        p.oy = (math.random() - 0.5) * 1800
        p.oz = (math.random() - 0.5) * 1800
    end,
    sphere = function(p, i)
        local u = (math.random() - 0.5) * 2
        local theta = math.random() * math.pi * 2
        local r = 600 * (math.random() ^ (1/3))
        local s = math.sqrt(math.max(0, 1 - u*u))
        p.ox = r * s * math.cos(theta)
        p.oy = r * u
        p.oz = r * s * math.sin(theta)
    end,
    galaxy = function(p, i)
        local arms = 4
        local armAngle = (i % arms) * ((math.pi * 2) / arms)
        local dist = (math.random() ^ 1.5) * 1100
        local theta = armAngle + dist * 0.004 + (math.random() - 0.5) * 0.3
        p.ox = math.cos(theta) * dist
        p.oz = math.sin(theta) * dist
        p.oy = (math.random() - 0.5) * (160 * (1 - dist / 1150))
    end,
    torus = function(p, i)
        local R, r_min = 550, 180
        local u = math.random() * math.pi * 2
        local v = math.random() * math.pi * 2
        p.ox = (R + r_min * math.cos(v)) * math.cos(u)
        p.oz = (R + r_min * math.cos(v)) * math.sin(u)
        p.oy = r_min * math.sin(v)
    end,
    lattice = function(p, i)
        local step, side = 95, 20
        local total = side * side * side
        local idx = i % total
        local gx = (idx % side) - side/2
        local gy = (math.floor(idx / side) % side) - side/2
        local gz = (math.floor(idx / (side * side))) - side/2
        p.ox = gx * step + (math.random() - 0.5) * 12
        p.oy = gy * step + (math.random() - 0.5) * 12
        p.oz = gz * step + (math.random() - 0.5) * 12
    end,
    tesseract = function(p, i)
        local scale = 450
        local corner = i % 16
        local x = (bit and bit.band(corner, 1) > 0) and 1 or -1
        local y = (bit and bit.band(corner, 2) > 0) and 1 or -1
        local z = (bit and bit.band(corner, 4) > 0) and 1 or -1
        local w = (bit and bit.band(corner, 8) > 0) and 1 or -1
        local jitter = (math.random() - 0.5) * 180
        p.ox = x * scale + jitter
        p.oy = y * scale + jitter
        p.oz = z * scale + w * 180 + jitter
    end,
    dna = function(p, i)
        local t = (i / RLengine.maxCount) * math.pi * 48
        local strand = (i % 2 == 0) and 0 or math.pi
        local r = 320
        p.ox = math.cos(t + strand) * r + (math.random() - 0.5) * 35
        p.oz = math.sin(t + strand) * r + (math.random() - 0.5) * 35
        p.oy = (t - math.pi * 24) * 22
    end,
    blackhole = function(p, i)
        local isDisk = (i % 10 ~= 0)
        if isDisk then
            local dist = 300 + (math.random() ^ 0.7) * 800
            local theta = math.random() * math.pi * 2
            p.ox = math.cos(theta) * dist
            p.oz = math.sin(theta) * dist
            p.oy = (math.random() - 0.5) * 30
        else
            local u = (math.random() - 0.5) * 2
            local theta = math.random() * math.pi * 2
            local r = 250
            local s = math.sqrt(math.max(0, 1 - u*u))
            p.ox = r * s * math.cos(theta)
            p.oy = r * u
            p.oz = r * s * math.sin(theta)
        end
    end
}

local postShaderCode = [[
    extern vec2 u_resolution;
    extern float u_chroma;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        vec2 dist = uv - vec2(0.5);
        float shift = length(dist) * 0.003 * u_chroma;

        float r = Texel(texture, uv + vec2(shift, 0.0)).r;
        float g = Texel(texture, uv).g;
        float b = Texel(texture, uv - vec2(shift, 0.0)).b;
        float a = Texel(texture, uv).a;

        return vec4(r, g, b, a) * color;
    }
]]

function RLengine.init(w, h)
    RLengine.bounds.w = w or love.graphics.getWidth()
    RLengine.bounds.h = h or love.graphics.getHeight()

    local vSize = ffi.sizeof("Vertex")
    local pSize = ffi.sizeof("Particle")

    RLengine.vertexData = love.data.newByteData(vSize * RLengine.maxCount)
    RLengine.particleData = love.data.newByteData(pSize * RLengine.maxCount)

    RLengine.vertexPtr = ffi.cast("Vertex*", RLengine.vertexData:getFFIPointer())
    RLengine.particles = ffi.cast("Particle*", RLengine.particleData:getFFIPointer())

    local layout = {
        {"VertexPosition", "float", 2},
        {"VertexColor", "byte", 4}
    }
    RLengine.mesh = love.graphics.newMesh(layout, RLengine.maxCount, "points", "stream")

    RLengine.colorLUT = ffi.new("uint8_t[8][256][4]")
    for pal = 1, 8 do
        for i = 0, 255 do
            local r, g, b, a = PALETTES[pal](i / 255)
            RLengine.colorLUT[pal - 1][i][0] = r
            RLengine.colorLUT[pal - 1][i][1] = g
            RLengine.colorLUT[pal - 1][i][2] = b
            RLengine.colorLUT[pal - 1][i][3] = a
        end
    end

    RLengine.shockwavePool = ffi.new("Shockwave[16]")

    RLengine.trailCanvas = love.graphics.newCanvas(RLengine.bounds.w, RLengine.bounds.h)
    RLengine.postShader = love.graphics.newShader(postShaderCode)

    RLengine.setParticleCount(1500000)
    RLengine.setShape(2)
end

function RLengine.setParticleCount(target)
    target = math.max(0, math.min(RLengine.maxCount, target))
    local p = RLengine.particles

    if target > RLengine.count then
        for i = RLengine.count, target - 1 do
            p[i].x = (math.random() - 0.5) * 1800
            p[i].y = (math.random() - 0.5) * 1800
            p[i].z = (math.random() - 0.5) * 1800
            p[i].vx = (math.random() - 0.5) * 40
            p[i].vy = (math.random() - 0.5) * 40
            p[i].vz = (math.random() - 0.5) * 40
            p[i].phase = math.random() * math.pi * 2
            p[i].ox, p[i].oy, p[i].oz = p[i].x, p[i].y, p[i].z
        end
        RLengine.applyShapeRange(RLengine.count, target - 1)
    end
    RLengine.count = target
end

function RLengine.applyShapeRange(first, last)
    local shapeFuncs = {Shapes.cube, Shapes.sphere, Shapes.galaxy, Shapes.torus, Shapes.lattice, Shapes.tesseract, Shapes.dna, Shapes.blackhole}
    local shapeFunc = shapeFuncs[RLengine.shapeMode]
    if not shapeFunc then return end

    local p = RLengine.particles
    for i = first, last do
        shapeFunc(p[i], i)
    end
end

function RLengine.setShape(mode)
    RLengine.shapeMode = mode
    RLengine.applyShapeRange(0, RLengine.count - 1)
    RLengine.targetMorph = 1.0
end

function RLengine.triggerShockwave(x, y, z, customForce)
    local pool = RLengine.shockwavePool
    for i = 0, RLengine.maxShockwaves - 1 do
        if not pool[i].active then
            pool[i].active = true
            pool[i].x = x or 0
            pool[i].y = y or 0
            pool[i].z = z or 0
            pool[i].radius = 10
            pool[i].maxRadius = 1800
            pool[i].speed = 2600
            pool[i].force = customForce or 1600
            break
        end
    end
end

function RLengine.update(dt)
    local count = RLengine.count
    if count == 0 then return end

    RLengine.time = RLengine.time + dt
    local tGlobal = RLengine.time
    local cx = RLengine.bounds.w * 0.5
    local cy = RLengine.bounds.h * 0.5
    local fov = RLengine.fov

    RLengine.morphStrength = RLengine.morphStrength + (RLengine.targetMorph - RLengine.morphStrength) * math.min(1.0, dt * 3.2)
    local morphStr = RLengine.morphStrength * 14.0

    local pool = RLengine.shockwavePool
    local activeShockwaves = 0
    for i = 0, RLengine.maxShockwaves - 1 do
        local sw = pool[i]
        if sw.active then
            sw.radius = sw.radius + sw.speed * dt
            if sw.radius > sw.maxRadius then
                sw.active = false
            else
                activeShockwaves = activeShockwaves + 1
            end
        end
    end

    local cam = RLengine.cam
    if cam.orbit then
        cam.orbitAngle = cam.orbitAngle + dt * cam.orbitSpeed
        cam.x = math.sin(cam.orbitAngle) * cam.orbitDist
        cam.z = math.cos(cam.orbitAngle) * cam.orbitDist
        cam.yaw = cam.orbitAngle + math.pi
        cam.pitch = 0.22
        cam.y = 220
    end

    local camX, camY, camZ = cam.x, cam.y, cam.z
    local cosY, sinY = math.cos(-cam.yaw), math.sin(-cam.yaw)
    local cosP, sinP = math.cos(-cam.pitch), math.sin(-cam.pitch)

    local m11, m12, m13 = cosY, 0, -sinY
    local m21, m22, m23 = sinP * sinY, cosP, sinP * cosY
    local m31, m32, m33 = cosP * sinY, -sinP, cosP * cosY

    local p = RLengine.particles
    local v = RLengine.vertexPtr
    local lut = RLengine.colorLUT[RLengine.paletteMode - 1]

    local isLmb = love.mouse.isDown(1)
    local fMode = RLengine.forceMode
    local damp = 1.0 - math.min(0.9, dt * 0.45)

    local cursorRayX, cursorRayY, cursorRayZ = 0, 0, 0
    if isLmb then
        local mx, my = love.mouse.getPosition()
        local ndx = (mx - cx) / fov
        local ndy = (my - cy) / fov
        local rx, ry, rz = ndx * 750, ndy * 750, 750
        cursorRayX = camX + (rx * cosY + rz * sinY)
        cursorRayY = camY + (ry * cosP - (-sinP) * (rx * -sinY + rz * cosY))
        cursorRayZ = camZ + (-rx * sinY + rz * cosY)
    end

    for i = 0, count - 1 do
        local pt = p[i]
        local x, y, z = pt.x, pt.y, pt.z
        local vx, vy, vz = pt.vx, pt.vy, pt.vz

        if morphStr > 0.001 then
            vx = vx + (pt.ox - x) * morphStr * dt
            vy = vy + (pt.oy - y) * morphStr * dt
            vz = vz + (pt.oz - z) * morphStr * dt
        end

        if isLmb then
            local dx = cursorRayX - x
            local dy = cursorRayY - y
            local dz = cursorRayZ - z
            local distSq = dx * dx + dy * dy + dz * dz + 1000

            if fMode == 1 then
                local force = 16000000 * dt / distSq
                vx = vx + dx * force; vy = vy + dy * force; vz = vz + dz * force
            elseif fMode == 2 then
                local force = 12000000 * dt / distSq
                vx = vx + (-dy * 18 + dx) * force
                vy = vy + (dx * 18 + dy) * force
                vz = vz + dz * force
            elseif fMode == 3 then
                local force = -22000000 * dt / distSq
                vx = vx + dx * force; vy = vy + dy * force; vz = vz + dz * force
            elseif fMode == 4 then
                vx = vx + math.sin(y * 0.009 + tGlobal * 6 + pt.phase) * 500 * dt
                vy = vy + math.cos(z * 0.009 + tGlobal * 6 + pt.phase) * 500 * dt
                vz = vz + math.sin(x * 0.009 + tGlobal * 6 + pt.phase) * 500 * dt
            elseif fMode == 5 then
                local dxM = -x; local dyM = -y; local dzM = -z
                local distM = math.sqrt(dxM*dxM + dyM*dyM + dzM*dzM) + 0.1
                vx = vx + (-dzM / distM) * 600 * dt
                vz = vz + (dxM / distM) * 600 * dt
            elseif fMode == 6 then
                local sigma, rho, beta = 10.0, 28.0, 2.666
                local lx, ly, lz = x * 0.01, y * 0.01, z * 0.01
                vx = vx + (sigma * (ly - lx)) * 12 * dt
                vy = vy + (lx * (rho - lz) - ly) * 12 * dt
                vz = vz + (lx * ly - beta * lz) * 12 * dt
            end
        end

        if activeShockwaves > 0 then
            for k = 0, RLengine.maxShockwaves - 1 do
                local sw = pool[k]
                if sw.active then
                    local sdx, sdy, sdz = x - sw.x, y - sw.y, z - sw.z
                    local sDistSq = sdx * sdx + sdy * sdy + sdz * sdz
                    local deltaRadius = math.abs(math.sqrt(sDistSq) - sw.radius)
                    if deltaRadius < 200 then
                        local push = (1.0 - deltaRadius / 200) * sw.force * dt
                        local invLen = 1.0 / (math.sqrt(sDistSq) + 0.001)
                        vx = vx + sdx * invLen * push * 55
                        vy = vy + sdy * invLen * push * 55
                        vz = vz + sdz * invLen * push * 55
                    end
                end
            end
        end

        vx = vx * damp; vy = vy * damp; vz = vz * damp
        x = x + vx * dt; y = y + vy * dt; z = z + vz * dt

        local bLimit = 1600
        if x < -bLimit then x = -bLimit; vx = -vx * 0.75 elseif x > bLimit then x = bLimit; vx = -vx * 0.75 end
        if y < -bLimit then y = -bLimit; vy = -vy * 0.75 elseif y > bLimit then y = bLimit; vy = -vy * 0.75 end
        if z < -bLimit then z = -bLimit; vz = -vz * 0.75 elseif z > bLimit then z = bLimit; vz = -vz * 0.75 end

        pt.x, pt.y, pt.z = x, y, z
        pt.vx, pt.vy, pt.vz = vx, vy, vz

        local tx = x - camX; local ty = y - camY; local tz = z - camZ
        local rx = tx * m11 + ty * m12 + tz * m13
        local ry = tx * m21 + ty * m22 + tz * m23
        local rz = tx * m31 + ty * m32 + tz * m33

        local vert = v[i]
        if rz > 15 then
            local invZ = fov / rz
            vert.x = cx + rx * invZ
            vert.y = cy + ry * invZ

            local speedSq = vx*vx + vy*vy + vz*vz
            local cIdx = math.min(255, math.max(0, math.floor(speedSq * 0.0022)))

            local depthAlpha = 255 - math.min(255, math.floor(rz * 0.07))
            if depthAlpha < 0 then depthAlpha = 0 end

            vert.r = lut[cIdx][0]
            vert.g = lut[cIdx][1]
            vert.b = lut[cIdx][2]
            vert.a = depthAlpha
        else
            vert.x = -99999
            vert.y = -99999
            vert.a = 0
        end
    end

    RLengine.mesh:setVertices(RLengine.vertexData, 1, count)
end

function RLengine.draw()
    if RLengine.useTrails then
        love.graphics.setCanvas(RLengine.trailCanvas)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0.01, 0.01, 0.02, RLengine.trailFade)
        love.graphics.rectangle("fill", 0, 0, RLengine.bounds.w, RLengine.bounds.h)
    else
        love.graphics.clear(0.01, 0.01, 0.02, 1)
    end

    if RLengine.count > 0 then
        if RLengine.additiveBlend then
            love.graphics.setBlendMode("add")
        else
            love.graphics.setBlendMode("alpha")
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setPointSize(RLengine.pointSize)
        RLengine.mesh:setDrawRange(1, RLengine.count)
        love.graphics.draw(RLengine.mesh)
    end

    if RLengine.useTrails then
        love.graphics.setCanvas()
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 1, 1, 1)

        if RLengine.usePostFX then
            RLengine.postShader:send("u_chroma", RLengine.chromaticAberration)
            love.graphics.setShader(RLengine.postShader)
        end

        love.graphics.draw(RLengine.trailCanvas, 0, 0)
        love.graphics.setShader()
    end

    if RLengine.showHUD then
        love.graphics.setBlendMode("alpha")
        local memMB = collectgarbage("count") / 1024
        love.graphics.setColor(0.02, 0.04, 0.08, 0.90)
        love.graphics.rectangle("fill", 15, 15, 510, 310, 8, 8)
        love.graphics.setColor(0.0, 0.8, 1.0, 0.6)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", 15, 15, 510, 310, 8, 8)

        local forceNames = {"Singularity", "Cosmic Vortex", "Anti-Gravity", "Quantum Waves", "Dipole Magnetic", "Lorenz Attractor"}
        local palNames = {"Cyberpunk", "Inferno", "Matrix", "Plasma", "Void", "Gold", "Acid Toxic", "Neon Synth"}
        local shapeNames = {"Cube Dust", "Sphere", "Galaxy", "Torus", "Lattice", "4D Tesseract", "DNA Helix", "Accretion Black Hole"}

        love.graphics.setColor(0, 1, 0.6)
        love.graphics.print("RLengine 3.0 // QUANTUM DYNAMICS", 28, 24)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.line(28, 44, 500, 44)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("FPS: %d (%.2f ms) | Lua RAM: %.2f MB", 
            love.timer.getFPS(), 1000 / math.max(1, love.timer.getFPS()), memMB), 28, 52)
        love.graphics.print(string.format("Particles: %s / %s (%.0f%%)", 
            RLengine.formatNumber(RLengine.count), RLengine.formatNumber(RLengine.maxCount), (RLengine.count / RLengine.maxCount) * 100), 28, 72)
        
        love.graphics.setColor(0.3, 0.9, 1.0)
        love.graphics.print("[1-6] Force Field: " .. forceNames[RLengine.forceMode], 28, 96)
        love.graphics.print("[F1-F8] Shape: " .. shapeNames[RLengine.shapeMode] .. (RLengine.targetMorph > 0 and " (LOCK)" or " (FREE)"), 28, 116)
        love.graphics.print("[7-0] Palette: " .. palNames[RLengine.paletteMode], 28, 136)
        
        love.graphics.setColor(0.9, 0.7, 0.2)
        love.graphics.print("[E / MMB] Shockwave Burst | [M] Morph Lock Toggle", 28, 160)
        love.graphics.print("[B] Blend: " .. (RLengine.additiveBlend and "Additive Neon" or "Alpha Soft") .. " | [T] Trails: " .. (RLengine.useTrails and "ON" or "OFF"), 28, 180)
        love.graphics.print("[P] PostFX Chromatic Aberration: " .. (RLengine.usePostFX and "ON" or "OFF"), 28, 200)
        love.graphics.print("[C] Orbit Camera: " .. (RLengine.cam.orbit and "CINEMATIC" or "FREE-FLY"), 28, 220)
        love.graphics.print("[UP / DOWN] Particles ±250k | [H] HUD Toggle", 28, 240)
        
        love.graphics.setColor(0.1, 0.2, 0.3)
        love.graphics.rectangle("fill", 28, 272, 480, 8, 4, 4)
        love.graphics.setColor(0.0, 1.0, 0.6)
        love.graphics.rectangle("fill", 28, 272, 480 * (RLengine.count / RLengine.maxCount), 8, 4, 4)
    end
end

function RLengine.formatNumber(n)
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

function love.load()
    love.window.setMode(1280, 720, {resizable = true, vsync = false, minwidth = 800, minheight = 600})
    love.window.setTitle("RLengine 3.0 - Quantum Dynamics Sandbox")
    RLengine.init()
end

function love.resize(w, h)
    RLengine.bounds.w = w
    RLengine.bounds.h = h
    RLengine.trailCanvas = love.graphics.newCanvas(w, h)
end

function love.update(dt)
    local cam = RLengine.cam
    local speed = 900 * dt

    if not cam.orbit then
        local forwardX = math.sin(cam.yaw) * speed
        local forwardZ = math.cos(cam.yaw) * speed
        local rightX = math.cos(cam.yaw) * speed
        local rightZ = -math.sin(cam.yaw) * speed

        if love.keyboard.isDown("w") then cam.x = cam.x + forwardX; cam.z = cam.z + forwardZ end
        if love.keyboard.isDown("s") then cam.x = cam.x - forwardX; cam.z = cam.z - forwardZ end
        if love.keyboard.isDown("a") then cam.x = cam.x - rightX; cam.z = cam.z - rightZ end
        if love.keyboard.isDown("d") then cam.x = cam.x + rightX; cam.z = cam.z + rightZ end
        if love.keyboard.isDown("space") then cam.y = cam.y + speed end
        if love.keyboard.isDown("lshift") then cam.y = cam.y - speed end
    end

    RLengine.update(dt)
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) and not RLengine.cam.orbit then
        local cam = RLengine.cam
        cam.yaw = cam.yaw + dx * 0.0035
        cam.pitch = math.max(-1.5, math.min(1.5, cam.pitch - dy * 0.0035))
    end
end

function love.wheelmoved(x, y)
    if RLengine.cam.orbit then
        RLengine.cam.orbitDist = math.max(200, math.min(3500, RLengine.cam.orbitDist - y * 70))
    else
        RLengine.fov = math.max(200, math.min(1400, RLengine.fov + y * 45))
    end
end

function love.keypressed(key)
    if key == "up" then RLengine.setParticleCount(RLengine.count + 250000)
    elseif key == "down" then RLengine.setParticleCount(RLengine.count - 250000)
    elseif key == "1" then RLengine.forceMode = 1
    elseif key == "2" then RLengine.forceMode = 2
    elseif key == "3" then RLengine.forceMode = 3
    elseif key == "4" then RLengine.forceMode = 4
    elseif key == "5" then RLengine.forceMode = 5
    elseif key == "6" then RLengine.forceMode = 6

    elseif key == "f1" then RLengine.setShape(1)
    elseif key == "f2" then RLengine.setShape(2)
    elseif key == "f3" then RLengine.setShape(3)
    elseif key == "f4" then RLengine.setShape(4)
    elseif key == "f5" then RLengine.setShape(5)
    elseif key == "f6" then RLengine.setShape(6)
    elseif key == "f7" then RLengine.setShape(7)
    elseif key == "f8" then RLengine.setShape(8)

    elseif key == "7" then RLengine.paletteMode = 1
    elseif key == "8" then RLengine.paletteMode = 2
    elseif key == "9" then RLengine.paletteMode = 3
    elseif key == "0" then RLengine.paletteMode = 4

    elseif key == "m" then RLengine.targetMorph = (RLengine.targetMorph > 0) and 0.0 or 1.0
    elseif key == "e" then RLengine.triggerShockwave(0, 0, 0, 2200)
    elseif key == "b" then RLengine.additiveBlend = not RLengine.additiveBlend
    elseif key == "t" then RLengine.useTrails = not RLengine.useTrails
    elseif key == "p" then RLengine.usePostFX = not RLengine.usePostFX
    elseif key == "c" then RLengine.cam.orbit = not RLengine.cam.orbit
    elseif key == "h" then RLengine.showHUD = not RLengine.showHUD
    end
end

function love.mousepressed(x, y, button)
    if button == 3 then
        RLengine.triggerShockwave(0, 0, 0, 2500)
    end
end

function love.draw()
    RLengine.draw()
end