pcall(function()
    local g = getgenv and getgenv() or _G
    if g and g.BSP32 and g.BSP32.Shutdown then
        g.BSP32:Shutdown()
    end
end)
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TeleportService   = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local STUDS_PER_METER = 3.571428
local MS_PER_MPH      = 0.44704
local MPH_TO_STUDS    = MS_PER_MPH * STUDS_PER_METER
local KMH_TO_STUDS    = (1000 / 3600) * STUDS_PER_METER
local RAMP_TIME       = 5
local CONFIG_FILE     = "BikeScannerPro_v32.json"
local ESP_BELOW       = Color3.fromRGB(137, 207, 240)
local ESP_ABOVE       = Color3.fromRGB(220, 20, 60)
local ESP_UPDATE_SECS = 0.5
local DEFAULTS = {
    SpeedMPH   = 250,
    Grip       = 1,
    Boost      = true,
    AutoAlign  = true,
    Autosave   = true,
    ESP        = false,
    SpeedHUD   = true,
    Cruise     = false,
    AntiLoop   = false,
    AntiFling  = false,
}
local S = {
    SpeedMPH   = DEFAULTS.SpeedMPH,
    Grip       = DEFAULTS.Grip,
    Boost      = DEFAULTS.Boost,
    AutoAlign  = DEFAULTS.AutoAlign,
    Autosave   = DEFAULTS.Autosave,
    ESP = false,
    SpeedHUD = true,
    Cruise = false,
    AntiLoop = false,
    AntiFling = false,
    cruiseLatched = false,
    rampSpeed  = 0,
    pushI      = 0,
    wasDriving = false,
    lastBike   = nil,
    dirX       = nil,
    dirZ       = nil,
    boostForce = nil,
    boostAttach = nil,
    forceChassis = nil,
    tippedWarn = 0,
    anchoredWarnedFor = nil,
}
local Conns = {}
local UIRefs = {}
local WHeld = false
local OwnerAccum = 0
local StuckSince = nil
local LastStatus = ""
local function track(conn)
    table.insert(Conns, conn)
    return conn
end
local Rayfield = nil
local API = nil
local MyClaim = HttpService:GenerateGUID(false)
pcall(function()
    LocalPlayer:SetAttribute("BSP_OWNER", MyClaim)
end)
local function hasFileAPI()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end
local function colorToTable(c)
    if typeof(c) ~= "Color3" then return nil end
    return { R = c.R, G = c.G, B = c.B }
end
local function tableToColor(t)
    if type(t) ~= "table" then return nil end
    local r, g, b = tonumber(t.R), tonumber(t.G), tonumber(t.B)
    if not (r and g and b) then return nil end
    r = math.clamp(r, 0, 1); g = math.clamp(g, 0, 1); b = math.clamp(b, 0, 1)
    return Color3.new(r, g, b)
end
local function sanitizeConfig(d)
    local out = {}
    if type(d) ~= "table" then return out end
    if tonumber(d.SpeedMPH) then
        out.SpeedMPH = math.clamp(tonumber(d.SpeedMPH), 0, 250)
    end
    if tonumber(d.Grip) then
        out.Grip = math.clamp(tonumber(d.Grip), 0, 1)
    end
    if type(d.Boost) == "boolean" then out.Boost = d.Boost end
    if type(d.AutoAlign) == "boolean" then out.AutoAlign = d.AutoAlign end
    if type(d.Autosave) == "boolean" then out.Autosave = d.Autosave end
    if type(d.ESP) == "boolean" then out.ESP = d.ESP end
    if type(d.SpeedHUD) == "boolean" then out.SpeedHUD = d.SpeedHUD end
    if type(d.Cruise) == "boolean" then out.Cruise = d.Cruise end
    if type(d.AntiLoop) == "boolean" then out.AntiLoop = d.AntiLoop end
    if type(d.AntiFling) == "boolean" then out.AntiFling = d.AntiFling end
    return out
end
local function applyConfig(c)
    if c.SpeedMPH   then S.SpeedMPH = c.SpeedMPH end
    if c.Grip       then S.Grip = c.Grip end
    if c.Boost      ~= nil then S.Boost = c.Boost end
    if c.AutoAlign  ~= nil then S.AutoAlign = c.AutoAlign end
    if c.Autosave   ~= nil then S.Autosave = c.Autosave end
    if c.ESP        ~= nil then S.ESP = c.ESP end
    if c.SpeedHUD  ~= nil then S.SpeedHUD = c.SpeedHUD end
    if c.Cruise    ~= nil then S.Cruise = c.Cruise end
    if c.AntiLoop  ~= nil then S.AntiLoop = c.AntiLoop end
    if c.AntiFling ~= nil then S.AntiFling = c.AntiFling end
end
local function currentConfigTable()
    return {
        SpeedMPH   = S.SpeedMPH,
        Grip       = S.Grip,
        Boost      = S.Boost,
        AutoAlign  = S.AutoAlign,
        Autosave   = S.Autosave,
        ESP        = S.ESP,
        SpeedHUD   = S.SpeedHUD,
        Cruise     = S.Cruise,
        AntiLoop   = S.AntiLoop,
        AntiFling  = S.AntiFling,
    }
end
local function saveConfig(silent)
    if not hasFileAPI() then
        return false
    end
    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(currentConfigTable()))
    end)
    return ok
end
local function loadConfig()
    if not hasFileAPI() then return false end
    local ok, raw = pcall(function()
        if isfile(CONFIG_FILE) then return readfile(CONFIG_FILE) end
        return nil
    end)
    if not (ok and raw) then return false end
    local ok2, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not (ok2 and type(decoded) == "table") then return false end
    applyConfig(sanitizeConfig(decoded))
    return true
end
local SavePending, SaveAt = false, 0
local function maybeAutosave()
    if S.Autosave and hasFileAPI() then
        SavePending, SaveAt = true, os.clock() + 2
    end
end
local function flushAutosave()
    if SavePending and os.clock() >= SaveAt then
        SavePending = false
        saveConfig(true)
    end
end
loadConfig()
S.SpeedMPH = 250
S.Boost = true
local CachedChar, CachedHum = nil, nil
local function getHumanoid()
    if CachedHum and CachedHum.Parent then return CachedHum end
    local ch = LocalPlayer and LocalPlayer.Character
    CachedChar = ch
    CachedHum = ch and ch:FindFirstChildOfClass("Humanoid") or nil
    return CachedHum
end
pcall(function()
    track(LocalPlayer.CharacterAdded:Connect(function(ch)
        CachedChar = ch
        CachedHum = ch:WaitForChild("Humanoid", 10)
    end))
end)
local FallbackCache = { t = 0, bike = nil, seat = nil }
local function getSeatedBike()
    local hum = getHumanoid()
    if hum and hum.SeatPart then
        local seat = hum.SeatPart
        local model = seat:FindFirstAncestorOfClass("Model")
        if model and seat.Occupant == hum then
            return model, seat
        end
    end
    return nil, nil
end
local function getBike()
    local model, seat = getSeatedBike()
    if model then return model, seat end
    local now = os.clock()
    if now - FallbackCache.t < 5 then
        return FallbackCache.bike, FallbackCache.seat
    end
    FallbackCache.t = now
    local ch = LocalPlayer and LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    local best, bestSeat, bestD = nil, nil, 25
    for _, m in ipairs(Workspace:GetChildren()) do
        if m:IsA("Model") then
            for _, d in ipairs(m:GetDescendants()) do
                if (d:IsA("VehicleSeat") or d:IsA("Seat")) and d.Occupant == nil then
                    local ok, dist = pcall(function()
                        return (d.Position - hrp.Position).Magnitude
                    end)
                    if ok and dist < bestD then
                        best, bestSeat, bestD = m, d, dist
                    end
                    break
                end
            end
        end
    end
    FallbackCache.bike, FallbackCache.seat = best, bestSeat
    return best, bestSeat
end
local function getChassis(bike)
    if not bike then return nil end
    local c = bike:FindFirstChild("Chassis")
    if c and c:IsA("BasePart") then return c end
    if bike.PrimaryPart and bike.PrimaryPart:IsA("BasePart") then
        return bike.PrimaryPart
    end
    local seat = bike:FindFirstChild("DriverSeat", true)
    if seat and seat:IsA("BasePart") then
        local root = seat.AssemblyRootPart
        if root and root:IsA("BasePart") then return root end
        return seat
    end
    return nil
end
local function isNativeGame()
    if ReplicatedStorage:FindFirstChild("ScooterPhysics") then return true end
    local bike = getSeatedBike()
    if bike and (bike:GetAttribute("MaxSpeedKmh") or bike:GetAttribute("IsScooterSeat")) then
        return true
    end
    return false
end
local AnchoredCache = { bike = nil, t = 0, val = false }
local function bikeIsAnchored(bike)
    local now = os.clock()
    if AnchoredCache.bike == bike and now - AnchoredCache.t < 2 then
        return AnchoredCache.val
    end
    local anchored = false
    for _, d in ipairs(bike:GetDescendants()) do
        if d:IsA("BasePart") and d.Anchored then
            anchored = true
            break
        end
    end
    AnchoredCache.bike, AnchoredCache.t, AnchoredCache.val = bike, now, anchored
    return anchored
end
local function studsToMph(studs)
    return (studs / STUDS_PER_METER) * 2.23694
end
local function flipBike()
    local bike, seat = getBike()
    local chassis = bike and getChassis(bike) or nil
    if not (bike and chassis) then
        return
    end
    local hum = getHumanoid()
    if not hum then return end
    local seatedMine = seat and seat.Occupant == hum
    if not seatedMine then
        local ch = hum.Parent
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local near = hrp and (chassis.Position - hrp.Position).Magnitude < 20
        local slow = chassis.AssemblyLinearVelocity.Magnitude < 8
        local occ = seat and seat.Occupant or nil
        if not (near and slow and (occ == nil or occ == hum)) then
            return
        end
    end
    local pos = chassis.Position
    local _, yaw, _ = chassis.CFrame:ToEulerAnglesYXZ()
    pcall(function()
        chassis.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
        chassis.AssemblyLinearVelocity = Vector3.zero
        chassis.AssemblyAngularVelocity = Vector3.zero
    end)
    S.rampSpeed = 0
end
local function scanBike()
    local bike, seat = getBike()
    if not bike then return "No bike detected. Sit on your bike first." end
    local parts, seats, mass = 0, {}, 0
    for _, d in ipairs(bike:GetDescendants()) do
        if d:IsA("BasePart") then
            parts += 1
            local ok, m = pcall(function() return d:GetMass() end)
            if ok and m then mass += m end
        end
        if d:IsA("Seat") or d:IsA("VehicleSeat") then
            local occ = d.Occupant
            table.insert(seats, d.Name .. " (occ: "
                .. ((occ and occ.Parent and occ.Parent.Name) or "none") .. ")")
        end
    end
    local lines = {
        "Model: " .. bike.Name,
        "Mode: " .. (isNativeGame() and "Native (Bike Universe)" or "Generic"),
        "Parts: " .. parts .. "   Mass: " .. string.format("%.1f", mass),
        "Seats: " .. (#seats > 0 and table.concat(seats, ", ") or "none"),
    }
    local attrs = bike:GetAttributes()
    local keys = {}
    for k in pairs(attrs) do table.insert(keys, k) end
    table.sort(keys)
    for _, k in ipairs(keys) do
        if k == "MaxSpeedKmh" or k == "LaunchAccel" or k == "PowerPerKg"
            or k == "MaxSteerDeg" or k == "MaxLeanDeg" or k == "BrakeDecel"
            or k == "TireGrip" or k == "DisplayName" or k == "Kind" then
            table.insert(lines, k .. " = " .. tostring(attrs[k]))
        end
    end
    local chassis = getChassis(bike)
    if chassis then
        table.insert(lines, "Chassis: " .. chassis.Name
            .. "  Speed: " .. string.format("%.0f mph", studsToMph(chassis.AssemblyLinearVelocity.Magnitude)))
        if chassis:FindFirstChild("DriveForce") then
            table.insert(lines, "DriveForce: present")
        end
    end
    local txt = table.concat(lines, "\n")
    print("[BikeScannerPro] Scan:\n" .. txt)
    return txt
end
local ESPEntries = {}
local ESPAccum = 0
local STAT_PRIORITY = {
    "Money", "Cash", "Coins", "Bucks", "Gems", "Wins",
    "Score", "Points", "Kills", "Level",
}
local function formatStatNum(n)
    if type(n) ~= "number" then return tostring(n) end
    if n ~= n or math.abs(n) == math.huge then return "0" end
    local neg = n < 0
    n = math.floor(math.abs(n) + 0.5)
    local s = tostring(n)
    local out = ""
    while #s > 3 do
        out = "," .. string.sub(s, -3) .. out
        s = string.sub(s, 1, -4)
    end
    out = s .. out
    if neg then out = "-" .. out end
    return out
end
local function getLeaderStat(plr)
    local ok, folder = pcall(function()
        return plr and plr:FindFirstChild("leaderstats")
    end)
    if not (ok and folder) then return "Money", 0 end
    local firstName, firstVal = nil, nil
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("IntValue") or child:IsA("NumberValue") then
            if firstName == nil then
                firstName, firstVal = child.Name, (child.Value or 0)
            end
            local lname = string.lower(child.Name)
            for _, want in ipairs(STAT_PRIORITY) do
                if lname == string.lower(want) then
                    return child.Name, (child.Value or 0)
                end
            end
        end
    end
    if firstName ~= nil then return firstName, firstVal end
    return "Money", 0
end
local function getRiderInfo(plr)
    local bikeName, speedMph = "On foot", 0
    local ok, char = pcall(function() return plr.Character end)
    if not (ok and char) then return bikeName, speedMph end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart or nil
    if seat then
        local model = seat:FindFirstAncestorOfClass("Model")
        if model then
            bikeName = model.Name
            local chassis = getChassis(model)
            local part = (chassis and chassis:IsA("BasePart")) and chassis or seat
            local okV, v = pcall(function() return part.AssemblyLinearVelocity end)
            if okV and v then
                speedMph = studsToMph(Vector3.new(v.X, 0, v.Z).Magnitude)
            end
        else
            bikeName = "Bike"
        end
    else
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local okV, v = pcall(function() return hrp.AssemblyLinearVelocity end)
            if okV and v then
                speedMph = studsToMph(Vector3.new(v.X, 0, v.Z).Magnitude)
            end
        end
    end
    return bikeName, speedMph
end
local function removeEspFor(plr)
    local e = ESPEntries[plr]
    if not e then return end
    pcall(function() if e.gui then e.gui:Destroy() end end)
    ESPEntries[plr] = nil
end
local function clearAllEsp()
    for plr in pairs(ESPEntries) do
        removeEspFor(plr)
    end
end
local function ensureEspFor(plr, char)
    local e = ESPEntries[plr]
    if e and e.char == char and e.gui and e.gui.Parent and e.label and e.label.Parent then
        return e
    end
    if e then removeEspFor(plr) end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return nil end
    local okGui, gui, label = pcall(function()
        local g = Instance.new("BillboardGui")
        g.Name = "BSP_ESPTag"
        g.Adornee = head
        g.Size = UDim2.new(0, 200, 0, 50)
        g.StudsOffset = Vector3.new(0, 2.6, 0)
        g.AlwaysOnTop = true
        g.MaxDistance = 100000
        local t = Instance.new("TextLabel")
        t.Name = "Tag"
        t.Size = UDim2.fromScale(1, 1)
        t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextStrokeTransparency = 0.5
        t.TextSize = 13
        t.Font = Enum.Font.GothamBold
        t.TextWrapped = true
        t.Parent = g
        g.Parent = char
        return g, t
    end)
    if not (okGui and gui and label) then
        return nil
    end
    e = { char = char, gui = gui, label = label }
    ESPEntries[plr] = e
    return e
end
local function refreshESP()
    if not S.ESP then return end
    local _, myScore = getLeaderStat(LocalPlayer)
    myScore = tonumber(myScore) or 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                local e = ensureEspFor(plr, char)
                if e then
                    local statName, score = getLeaderStat(plr)
                    score = tonumber(score) or 0
                    local col = (score > myScore) and ESP_ABOVE or ESP_BELOW
                    pcall(function()
                        e.label.TextColor3 = col
                    end)
                    local bikeName, speedMph = getRiderInfo(plr)
                    local disp = plr.Name
                    pcall(function()
                        if plr.DisplayName and plr.DisplayName ~= "" then
                            disp = plr.DisplayName
                        end
                    end)
                    local title = (disp ~= plr.Name)
                        and (disp .. " (@" .. plr.Name .. ")") or plr.Name
                    pcall(function()
                        e.label.Text = string.format("%s\n%s: %s | %s\n%.0f MPH",
                            title, tostring(statName),
                            formatStatNum(score), tostring(bikeName), speedMph)
                    end)
                end
            else
                removeEspFor(plr)
            end
        end
    end
    for plr in pairs(ESPEntries) do
        if plr.Parent == nil then
            removeEspFor(plr)
        end
    end
end
local function updateEspStatus()
    if not (S.ESP and UIRefs.ESPStatus) then return end
    local statName, myScore = getLeaderStat(LocalPlayer)
    myScore = tonumber(myScore) or 0
    local above, belowOrTied, total = 0, 0, 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            total = total + 1
            local _, s = getLeaderStat(plr)
            if (tonumber(s) or 0) > myScore then above = above + 1
            else belowOrTied = belowOrTied + 1 end
        end
    end
    pcall(function()
        UIRefs.ESPStatus:Set({ Title = "Your Standing",
            Content = string.format("You: %s %s (#%d of %d) - Red above: %d - Blue below/tied: %d",
                tostring(statName), formatStatNum(myScore),
                above + 1, total + 1, above, belowOrTied) })
    end)
end
local function setESPEnabled(on)
    S.ESP = on and true or false
    if not S.ESP then
        clearAllEsp()
        pcall(function()
            if UIRefs.ESPStatus then
                UIRefs.ESPStatus:Set({ Title = "Your Standing", Content = "ESP off." })
            end
        end)
    else
        pcall(refreshESP)
        pcall(updateEspStatus)
    end
end
local function rejoinNow()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end
local HUD = { gui = nil, label = nil }
local HUDAccum = 0
local function destroyHUD()
    pcall(function() if HUD.gui then HUD.gui:Destroy() end end)
    HUD = { gui = nil, label = nil }
end
local function ensureHUD()
    if HUD.gui and HUD.gui.Parent and HUD.label and HUD.label.Parent then
        return true
    end
    destroyHUD()
    local ok, pg = pcall(function()
        return LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end)
    if not (ok and pg) then return false end
    local ok2, gui, label = pcall(function()
        local g = Instance.new("ScreenGui")
        g.Name = "BSP_HUD"
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.Parent = pg
        local t = Instance.new("TextLabel")
        t.Name = "Speed"
        t.AnchorPoint = Vector2.new(0.5, 1)
        t.Position = UDim2.new(0.5, 0, 1, -70)
        t.Size = UDim2.new(0, 220, 0, 44)
        t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextStrokeTransparency = 0.4
        t.TextSize = 30
        t.Font = Enum.Font.GothamBold
        t.Text = "0 MPH"
        t.Parent = g
        return g, t
    end)
    if not (ok2 and gui and label) then return false end
    HUD = { gui = gui, label = label }
    return true
end
local function refreshHUD()
    if not S.SpeedHUD then return end
    if not ensureHUD() then return end
    local mph = 0
    local hum = getHumanoid()
    local bike, seat = getSeatedBike()
    local chassis = bike and getChassis(bike) or nil
    if hum and bike and seat and seat.Occupant == hum and chassis then
        local ok, v = pcall(function() return chassis.AssemblyLinearVelocity end)
        if ok and v then
            mph = studsToMph(Vector3.new(v.X, 0, v.Z).Magnitude)
        end
    else
        local ch = LocalPlayer and LocalPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            local ok, v = pcall(function() return hrp.AssemblyLinearVelocity end)
            if ok and v then
                mph = studsToMph(Vector3.new(v.X, 0, v.Z).Magnitude)
            end
        end
    end
    pcall(function()
        HUD.label.Text = string.format("%.0f MPH", mph)
    end)
end
local function setSpeedHUD(on)
    S.SpeedHUD = on and true or false
    if S.SpeedHUD then
        pcall(refreshHUD)
    else
        destroyHUD()
    end
end
local function destroyBoost()
    if S.boostForce then
        pcall(function() S.boostForce:Destroy() end)
        S.boostForce = nil
    end
    if S.boostAttach then
        pcall(function() S.boostAttach:Destroy() end)
        S.boostAttach = nil
    end
    S.forceChassis = nil
end
local function zeroBoost()
    if S.boostForce then
        pcall(function() S.boostForce.Force = Vector3.zero end)
    end
end
local function ensureBoostForce(chassis)
    if S.boostForce and S.forceChassis == chassis
        and S.boostForce.Parent and S.boostAttach and S.boostAttach.Parent then
        if S.boostForce.Attachment0 ~= S.boostAttach then
            pcall(function() S.boostForce.Attachment0 = S.boostAttach end)
        end
        return S.boostForce
    end
    destroyBoost()
    local ok, att = pcall(function()
        local a = Instance.new("Attachment")
        a.Name = "BSP_BoostAttach"
        a.Parent = chassis
        return a
    end)
    if not (ok and att) then return nil end
    local ok2, vf = pcall(function()
        local f = Instance.new("VectorForce")
        f.Name = "BSP_Boost"
        f.RelativeTo = Enum.ActuatorRelativeTo.World
        f.ApplyAtCenterOfMass = true
        f.Force = Vector3.zero
        f.Attachment0 = att
        f.Parent = chassis
        return f
    end)
    if not (ok2 and vf) then
        pcall(function() att:Destroy() end)
        return nil
    end
    S.boostAttach, S.boostForce, S.forceChassis = att, vf, chassis
    return vf
end
local function stepDrive(dt)
    zeroBoost()
    if not S.Boost then
        S.wasDriving = false
        return
    end
    local hum = getHumanoid()
    local bike, seat = getSeatedBike()
    if not (hum and bike and seat) then
        S.wasDriving, S.rampSpeed, S.cruiseLatched = false, 0, false
        return
    end
    if seat.Occupant ~= hum then
        S.wasDriving, S.rampSpeed, S.cruiseLatched = false, 0, false
        return
    end
    local chassis = getChassis(bike)
    if not chassis then
        S.wasDriving, S.rampSpeed = false, 0
        return
    end
    if chassis.Anchored or bikeIsAnchored(bike) then
        if S.anchoredWarnedFor ~= bike then
            S.anchoredWarnedFor = bike
        end
        S.wasDriving, S.rampSpeed = false, 0
        return
    end
    local thr = seat.ThrottleFloat or 0
    if thr == 0 and WHeld then thr = 1 end
    local braking = thr < -0.1
    if braking then
        S.wasDriving, S.rampSpeed, S.cruiseLatched = false, 0, false
        return
    end
    if S.Cruise and thr > 0.1 then
        S.cruiseLatched = true
    elseif not S.Cruise then
        S.cruiseLatched = false
    end
    local driving = (thr > 0.1) or (S.Cruise and S.cruiseLatched)
    if not driving then
        S.wasDriving, S.rampSpeed = 0, 0
        return
    end
    local upY = chassis.CFrame.UpVector.Y
    if upY < 0.35 then
        if S.AutoAlign and thr < 0.5 then
            local spd = chassis.AssemblyLinearVelocity.Magnitude
            if spd < 6 then
                local pos = chassis.Position
                local _, yaw, _ = chassis.CFrame:ToEulerAnglesYXZ()
                local want = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
                pcall(function()
                    chassis.CFrame = chassis.CFrame:Lerp(want, math.min(1, 3 * dt))
                end)
            end
        elseif os.clock() - S.tippedWarn > 5 then
            S.tippedWarn = os.clock()
        end
        S.wasDriving, S.rampSpeed = false, 0
        return
    end
    local target = S.SpeedMPH * MPH_TO_STUDS
    local accel = math.max(target, 10) / RAMP_TIME
    local v = chassis.AssemblyLinearVelocity
    local hvx, hvz = v.X, v.Z
    local hspeed = math.sqrt(hvx * hvx + hvz * hvz)
    local look3 = chassis.CFrame.LookVector
    local lx, lz = look3.X, look3.Z
    local lm = math.sqrt(lx * lx + lz * lz)
    if lm < 0.01 then lx, lz, lm = 0, -1, 1 end
    lx, lz = lx / lm, lz / lm
    local tdx, tdz = lx, lz
    if hspeed > 6 then tdx, tdz = hvx / hspeed, hvz / hspeed end
    if S.dirX == nil then S.dirX, S.dirZ = tdx, tdz end
    local turn = math.min(1, 8 * dt)
    local dx, dz = S.dirX + (tdx - S.dirX) * turn, S.dirZ + (tdz - S.dirZ) * turn
    local dm = math.sqrt(dx * dx + dz * dz)
    if dm < 0.01 then dx, dz, dm = tdx, tdz, 1 end
    S.dirX, S.dirZ = dx / dm, dz / dm
    local dirX, dirZ = S.dirX, S.dirZ
    local fwd = hvx * dirX + hvz * dirZ
    local latX, latZ = hvx - dirX * fwd, hvz - dirZ * fwd
    local effTarget = target
    if S.AntiLoop then
        local noseUp = chassis.CFrame.LookVector.Y
        if noseUp and noseUp > 0.6 and hspeed > 20 then
            effTarget = math.min(effTarget, hspeed)
        end
    end
    if S.AntiFling then
        local vNow = chassis.AssemblyLinearVelocity
        if vNow and vNow.Magnitude > 900 then
            S.wasDriving, S.rampSpeed = false, 0
            return
        end
    end
    if not S.wasDriving then
        S.rampSpeed = hspeed
        S.pushI = 0
    end
    local newSpeed
    if S.rampSpeed < effTarget then
        newSpeed = math.min(effTarget, S.rampSpeed + accel * dt)
    else
        newSpeed = math.max(effTarget, S.rampSpeed - (math.max(target, 30) / 2) * dt)
    end
    S.rampSpeed, S.wasDriving = newSpeed, true
    local mass = chassis.AssemblyMass
    if not (mass and mass > 1) then mass = 100 end
    local bf = ensureBoostForce(chassis)
    if not bf then
        S.wasDriving, S.rampSpeed = false, 0
        return
    end
    local err = newSpeed - fwd
    S.pushI = math.clamp((S.pushI or 0) + err * dt * 2, -15, 25)
    local aF = math.clamp(err * 3 + S.pushI, -12, 60)
    local effGrip = math.clamp(S.Grip, 0, 1) * math.clamp(hspeed / 40, 0, 1)
    local latAx = -latX * (effGrip * 8)
    local latAz = -latZ * (effGrip * 8)
    local Fx = mass * (dirX * aF + latAx)
    local Fz = mass * (dirZ * aF + latAz)
    if Fx ~= Fx or Fz ~= Fz then Fx, Fz = 0, 0 end
    local capF = mass * 60
    if Fx > capF then Fx = capF elseif Fx < -capF then Fx = -capF end
    if Fz > capF then Fz = capF elseif Fz < -capF then Fz = -capF end
    pcall(function()
        bf.Force = Vector3.new(Fx, 0, Fz)
    end)
end
Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Bike Scanner Pro v53",
    LoadingTitle = "Bike Scanner Pro",
    LoadingSubtitle = "by qwilner - W = boost, S = brake",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,
    ConfigurationSaving = { Enabled = false },
})
local TabRide = Window:CreateTab("Ride")
local TabBike = Window:CreateTab("Bike")
UIRefs.Speed = TabRide:CreateSlider({
    Name = "Speed (MPH)",
    Range = { 0, 250 },
    Increment = 1,
    Suffix = " MPH",
    CurrentValue = S.SpeedMPH,
    Flag = "BSP_Speed",
    Callback = function(v)
        S.SpeedMPH = math.clamp(math.floor(v + 0.5), 0, 250)
        maybeAutosave()
    end,
})
UIRefs.Grip = TabRide:CreateSlider({
    Name = "Steering Grip",
    Range = { 0, 1 },
    Increment = 0.01,
    CurrentValue = S.Grip,
    Flag = "BSP_Grip",
    Callback = function(v)
        S.Grip = math.clamp(v, 0, 1)
        maybeAutosave()
    end,
})
UIRefs.Boost = TabRide:CreateToggle({
    Name = "Speed Boost (hold W)",
    CurrentValue = S.Boost,
    Flag = "BSP_Boost",
    Callback = function(v)
        S.Boost = v and true or false
        if not S.Boost then S.wasDriving, S.rampSpeed = false, 0 end
        maybeAutosave()
    end,
})
UIRefs.AutoAlign = TabRide:CreateToggle({
    Name = "Auto Align (stand up when tipped & slow)",
    CurrentValue = S.AutoAlign,
    Flag = "BSP_AutoAlign",
    Callback = function(v)
        S.AutoAlign = v and true or false
        maybeAutosave()
    end,
})
TabRide:CreateLabel("Free Y: LOCKED ON (vertical motion untouched)")
UIRefs.SpeedHUD = TabRide:CreateToggle({
    Name = "Speed HUD (MPH overlay)",
    CurrentValue = S.SpeedHUD,
    Flag = "BSP_SpeedHUD",
    Callback = function(v)
        setSpeedHUD(v and true or false)
        maybeAutosave()
    end,
})
UIRefs.Cruise = TabRide:CreateToggle({
    Name = "Cruise Control (W latches, S cancels)",
    CurrentValue = S.Cruise,
    Flag = "BSP_Cruise",
    Callback = function(v)
        S.Cruise = v and true or false
        if not S.Cruise then S.cruiseLatched = false end
        maybeAutosave()
    end,
})
UIRefs.AntiLoop = TabRide:CreateToggle({
    Name = "Anti Loop-Out (bleed on wheelie)",
    CurrentValue = S.AntiLoop,
    Flag = "BSP_AntiLoop",
    Callback = function(v)
        S.AntiLoop = v and true or false
        maybeAutosave()
    end,
})
UIRefs.AntiFling = TabRide:CreateToggle({
    Name = "Anti-Fling (cut boost on spike)",
    CurrentValue = S.AntiFling,
    Flag = "BSP_AntiFling",
    Callback = function(v)
        S.AntiFling = v and true or false
        maybeAutosave()
    end,
})
TabRide:CreateButton({
    Name = "Flip Bike Upright",
    Callback = flipBike,
})
TabRide:CreateButton({
    Name = "Force Stand (unstick from seat)",
    Callback = function()
        StuckSince = nil
        local hum = getHumanoid()
        if hum then
            pcall(function()
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
            local ch = hum.Parent
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end)
            end
        end
    end,
})
UIRefs.ScanResult = TabBike:CreateParagraph({ Title = "Bike Scan", Content = "Press Scan Bike." })
TabBike:CreateButton({
    Name = "Scan Bike",
    Callback = function()
        local txt = scanBike()
        pcall(function()
            UIRefs.ScanResult:Set({ Title = "Bike Scan", Content = txt })
        end)
    end,
})
local TabESP = Window:CreateTab("ESP")
UIRefs.ESP = TabESP:CreateToggle({
    Name = "ESP (rank colors + info text)",
    CurrentValue = S.ESP,
    Flag = "BSP_ESP",
    Callback = function(v)
        setESPEnabled(v and true or false)
        maybeAutosave()
    end,
})
TabESP:CreateLabel("Baby blue = at/below you - Red = above you")
TabESP:CreateLabel("Tag: username - money - bike - MPH")
UIRefs.ESPStatus = TabESP:CreateParagraph({ Title = "Your Standing", Content = "ESP off." })
local TabServer = Window:CreateTab("Server")
TabServer:CreateButton({ Name = "Rejoin This Server", Callback = rejoinNow })
TabServer:CreateButton({ Name = "Copy JobId", Callback = function()
    local job = tostring(game.JobId or "")
    pcall(function()
        if type(setclipboard) == "function" then setclipboard(job) end
    end)
    pcall(function()
        if type(toclipboard) == "function" then toclipboard(job) end
    end)
end })
if S.ESP then
    pcall(function() refreshESP() end)
    pcall(function() updateEspStatus() end)
end
if S.SpeedHUD then
    pcall(function() refreshHUD() end)
end
function syncUIFromState()
    pcall(function() UIRefs.Speed:Set(S.SpeedMPH) end)
    pcall(function() UIRefs.Grip:Set(S.Grip) end)
    pcall(function() UIRefs.Boost:Set(S.Boost) end)
    pcall(function() UIRefs.AutoAlign:Set(S.AutoAlign) end)
    pcall(function() if UIRefs.ESP then UIRefs.ESP:Set(S.ESP) end end)
    pcall(function() if UIRefs.SpeedHUD then UIRefs.SpeedHUD:Set(S.SpeedHUD) end end)
    pcall(function() if UIRefs.Cruise then UIRefs.Cruise:Set(S.Cruise) end end)
    pcall(function() if UIRefs.AntiLoop then UIRefs.AntiLoop:Set(S.AntiLoop) end end)
    pcall(function() if UIRefs.AntiFling then UIRefs.AntiFling:Set(S.AntiFling) end end)
end
syncUIFromState()
track(UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then WHeld = true end
end))
track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then WHeld = false end
end))
track(RunService.PostSimulation:Connect(function(dt)
    local ok, clamped = pcall(function()
        return math.clamp(dt or (1 / 60), 0, 1 / 30)
    end)
    if not ok then clamped = 1 / 60 end
    local ok2, err = pcall(stepDrive, clamped)
    if not ok2 then
        S.wasDriving, S.rampSpeed = false, 0
        warn("[BikeScannerPro] drive error: " .. tostring(err))
    end
end))
track(RunService.Heartbeat:Connect(function(dt)
    local bike = getSeatedBike()
    if bike and bike ~= S.lastBike then
        S.lastBike = bike
        S.rampSpeed, S.wasDriving = 0, false
        S.dirX, S.dirZ = nil, nil
        destroyBoost()
        S.anchoredWarnedFor = nil
        AnchoredCache.bike, AnchoredCache.t, AnchoredCache.val = nil, 0, false
    end
    local trapHum = getHumanoid()
    if trapHum then
        if trapHum.Sit and not trapHum.SeatPart then
            if not StuckSince then StuckSince = os.clock() end
            if os.clock() - StuckSince > 1.5 then
                pcall(function()
                    trapHum.Sit = false
                    trapHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
                StuckSince = nil
            end
        else
            StuckSince = nil
        end
    end
    HUDAccum = HUDAccum + dt
    if HUDAccum >= 0.25 then
        HUDAccum = 0
        if S.SpeedHUD then
            pcall(refreshHUD)
        end
    end
    ESPAccum = ESPAccum + dt
    if ESPAccum >= ESP_UPDATE_SECS then
        ESPAccum = 0
        if S.ESP then
            pcall(refreshESP)
            pcall(updateEspStatus)
        end
    end
    flushAutosave()
    OwnerAccum += dt
    if OwnerAccum > 2 then
        OwnerAccum = 0
        local okOwner, mine = pcall(function()
            return LocalPlayer:GetAttribute("BSP_OWNER")
        end)
        if okOwner and mine ~= MyClaim then
            if API and API.Shutdown then API:Shutdown() end
            return
        end
    end
end))
API = {}
function API:Shutdown()
    for _, c in ipairs(Conns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Conns)
    pcall(clearAllEsp)
    pcall(destroyHUD)
    destroyBoost()
    pcall(function() Rayfield:Destroy() end)
    local g = getgenv and getgenv() or _G
    if g then g.BSP32 = nil end
end
API._claim = MyClaim
function API:GetState()
    local ok, snap = pcall(function()
        local hum = getHumanoid()
        local seat = hum and hum.SeatPart or nil
        local bike = hum and seat and seat:FindFirstAncestorOfClass("Model") or nil
        local chassis = bike and getChassis(bike) or nil
        local v = chassis and chassis.AssemblyLinearVelocity or Vector3.zero
        local cf = chassis and chassis.CFrame or CFrame.new()
        return {
            boost = S.Boost, grip = S.Grip, target = S.SpeedMPH,
            ramp = S.rampSpeed, driving = S.wasDriving,
            dirX = S.dirX, dirZ = S.dirZ,
            seated = (seat ~= nil and hum and seat.Occupant == hum) or false,
            thr = seat and seat.ThrottleFloat or -9,
            bike = bike and bike.Name or "none",
            hspeed = math.sqrt(v.X * v.X + v.Z * v.Z), vy = v.Y,
            upY = cf.UpVector.Y, lookY = cf.LookVector.Y,
        }
    end)
    if ok then return snap else return { err = tostring(snap) } end
end
do
    local g = getgenv and getgenv() or _G
    if g then g.BSP32 = API end
end
