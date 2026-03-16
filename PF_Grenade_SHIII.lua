local tracked = {}
local miscFolder
local lastCheck = 0

local grenadeData = {}
grenadeData['rbxassetid://115486373217832'] = {Name='M67 FRAG', BlastRadius=30, KillRadius=22, FuseTime=5}
grenadeData['rbxassetid://130715368011981'] = {Name='MK2 FRAG', BlastRadius=28, KillRadius=23, FuseTime=4}
grenadeData['rbxassetid://110699405244834'] = {Name='DYNAMITE', BlastRadius=33, KillRadius=29, FuseTime=5}
grenadeData['rbxassetid://80065411824420'] = {Name='DYNAMITE-3', BlastRadius=37, KillRadius=33, FuseTime=5}
grenadeData['rbxassetid://117031955489991'] = {Name='M24 STICK', BlastRadius=30, KillRadius=17, FuseTime=4.5}
grenadeData['rbxassetid://75352201928166'] = {Name='M26 FRAG', BlastRadius=30, KillRadius=20, FuseTime=4.4}
grenadeData['rbxassetid://130375815890697'] = {Name='M560 MINI', BlastRadius=35, KillRadius=21, FuseTime=5}
grenadeData['rbxassetid://138740231502592'] = {Name='V40 MINI', BlastRadius=37, KillRadius=16, FuseTime=4}
grenadeData['rbxassetid://126781349308699'] = {Name='ROLY HG', BlastRadius=30, KillRadius=22, FuseTime=5}
grenadeData['rbxassetid://112296354272570'] = {Name='RGD-5 HE', BlastRadius=52, KillRadius=22, FuseTime=3.8}
grenadeData['rbxassetid://118140965706714'] = {Name='SEMTEX', BlastRadius=40, KillRadius=26, FuseTime=4}
grenadeData['rbxassetid://136737867397437'] = {Name='PB GRENADE', BlastRadius=42, KillRadius=40, FuseTime=7}
grenadeData['rbxassetid://123204164966116'] = {Name='BUNDLE CHARGE', BlastRadius=50, KillRadius=48, FuseTime=4.5}

grenadeData['default'] = {Name='GRENADE', BlastRadius=30, KillRadius=22, FuseTime=5}

local function getNade(part)
    local mesh = part.MeshId
    if mesh and grenadeData[mesh] then return grenadeData[mesh] end
    local tex = part.TextureId
    if tex and grenadeData[tex] then return grenadeData[tex] end
    return grenadeData['default']
end

local function drawRadius(cam, origin, rad, col, a)
    local lastPt, lastVis
    for i = 0, 72 do
        local theta = (i/72) * 6.2831853
        local pt = Vector3.new(origin.X + rad * math.cos(theta), origin.Y, origin.Z + rad * math.sin(theta))
        local s, v = cam:WorldToScreenPoint(pt)
        if v and lastVis then
            DrawingImmediate.Line(lastPt, Vector2.new(s.X, s.Y), col, a, 1, 2)
        end
        lastPt = Vector2.new(s.X, s.Y)
        lastVis = v
    end
end

game:GetService("RunService").Render:Connect(function()
    local now = tick()
    local cam = workspace.CurrentCamera
    if not cam then return end

    if now - lastCheck > 0.3 then
        lastCheck = now

        if not miscFolder then
            local ign = workspace:FindFirstChild("Ignore")
            if ign then miscFolder = ign:FindFirstChild("Misc") end
        end

        if miscFolder then
            local existing = {}
            for _, entry in tracked do existing[entry.part] = true end

            for _, child in miscFolder:GetChildren() do
                if existing[child] then continue end
                if child.Name == "Trigger" and child.ClassName == "MeshPart" and child:FindFirstChild("Ticking") then
                    tracked[#tracked+1] = {part = child, start = now, data = getNade(child)}
                end
            end

            for i = #tracked, 1, -1 do
                local e = tracked[i]
                if now - e.start > 8 or not e.part.Parent then
                    table.remove(tracked, i)
                end
            end
        end
    end

    local camPos = cam.Position
    for _, nade in tracked do
        local pos = nade.part.Position
        local dx, dy, dz = pos.X - camPos.X, pos.Y - camPos.Y, pos.Z - camPos.Z
        local d = math.sqrt(dx*dx + dy*dy + dz*dz)
        local meters = d * 0.28
        if meters > 20 then continue end

        local screenPt, onScreen = cam:WorldToScreenPoint(pos)
        if not onScreen then continue end

        local timeLeft = nade.data.FuseTime - (now - nade.start)
        if timeLeft < 0 then timeLeft = 0 end

        DrawingImmediate.OutlinedText(
            Vector2.new(screenPt.X, screenPt.Y - 4), 13, Color3.fromRGB(255, 255, 255), 1,
            nade.data.Name .. " [" .. math.floor(meters) .. "m]", true
        )

        local fuseCol = timeLeft > 3 and Color3.fromRGB(50, 255, 50)
            or timeLeft > 1.5 and Color3.fromRGB(255, 255, 50)
            or Color3.fromRGB(255, 50, 50)
        DrawingImmediate.OutlinedText(
            Vector2.new(screenPt.X, screenPt.Y + 10), 13, fuseCol, 1,
            string.format("%.1fs", timeLeft), true
        )

        drawRadius(cam, pos, nade.data.BlastRadius, Color3.fromRGB(255, 255, 255), 0.7)
        drawRadius(cam, pos, nade.data.KillRadius, Color3.fromRGB(0, 255, 255), 0.86)
    end
end)

