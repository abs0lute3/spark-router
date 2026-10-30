if getgenv().DandyHub_Heartbeat then pcall(function() getgenv().DandyHub_Heartbeat:Disconnect() end) end
if getgenv().DandyHub_NoclipConn then pcall(function() getgenv().DandyHub_NoclipConn:Disconnect() end) end
if getgenv().DandyHub_StaminaConn then pcall(function() getgenv().DandyHub_StaminaConn:Disconnect() end) end
if getgenv().DandyHub_StaminaRenderConn then pcall(function() getgenv().DandyHub_StaminaRenderConn:Disconnect() end) end
if getgenv().DandyHub_PromptConn then pcall(function() getgenv().DandyHub_PromptConn:Disconnect() end) end
if getgenv().DandyHub_ESPConn then pcall(function() getgenv().DandyHub_ESPConn:Disconnect() end) end
if getgenv().DandyHub_LagConn then pcall(function() getgenv().DandyHub_LagConn:Disconnect() end) end
if getgenv().DandyHub_CharAdded then pcall(function() getgenv().DandyHub_CharAdded:Disconnect() end) end
if getgenv().DandyHub_SprintWatch then pcall(function() for _, c in ipairs(getgenv().DandyHub_SprintWatch) do c:Disconnect() end end) end
if getgenv().DandyHub_ClearStaminaGuard then pcall(getgenv().DandyHub_ClearStaminaGuard) end
pcall(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Highlight") and obj.Name == "DandyHubESP") or (obj:IsA("BillboardGui") and obj.Name == "DandyHubName") then
            obj:Destroy()
        end
    end
end)
getgenv().DandyHub_Heartbeat = nil
getgenv().DandyHub_NoclipConn = nil
getgenv().DandyHub_StaminaConn = nil
getgenv().DandyHub_StaminaRenderConn = nil
getgenv().DandyHub_PromptConn = nil
getgenv().DandyHub_ESPConn = nil
getgenv().DandyHub_LagConn = nil
getgenv().DandyHub_CharAdded = nil
getgenv().DandyHub_SprintWatch = nil
getgenv().DandyHub_FolderCache = nil
getgenv().DandyHub_FolderMiss = nil
pcall(function()
    if getgenv().DandyHub_Rayfield then getgenv().DandyHub_Rayfield:Destroy() end
end)
getgenv().DandyHub_Settings = getgenv().DandyHub_Settings or {}
local S = getgenv().DandyHub_Settings
local DEFAULTS = {
    MonsterESP = true, PlayerESP = true, ItemESP = true, MachineESP = false,
    ElevatorESP = false, SpeedEnabled = false, SpeedValue = 16, LagPrevent = false,
    Fullbright = false, NoFog = false, InstantInteract = false, ShowNames = false,
    AutoSprint = false, Noclip = false, AutoCalibrateMachine = false,
    AutoCalibrateSpeed = true, AutoSave = true, HubTheme = "Default",
    ESPFill = 0.5, ESPThroughWalls = true, NameSize = 12,
    HalloweenESP = true, ChristmasESP = true, EasterESP = true, DoorESP = true,
    EventAutoCollect = false, TwistedAlert = false, TwistedAlertDist = 50,
}
for k, v in pairs(DEFAULTS) do
    if type(S[k]) ~= type(v) then S[k] = v end
end
if S._speedToggle == nil then S._speedToggle = false end
if S._shiftWasDown == nil then S._shiftWasDown = false end
if S._toggleWasOn == nil then S._toggleWasOn = false end
if S._toggleWasOn and S._baseRunSpeed then
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        local c = lp and lp.Character
        local st = c and c:FindFirstChild("Stats")
        local r = st and st:FindFirstChild("RunSpeed")
        if r then r.Value = S._baseRunSpeed end
    end)
end
S._lastCalClick = 0
S._lastTapPress = 0
if type(S.Noclip) ~= "boolean" then S.Noclip = false end
if type(S.AutoCalibrateMachine) ~= "boolean" then S.AutoCalibrateMachine = false end
if type(S.AutoCalibrateSpeed) ~= "boolean" then S.AutoCalibrateSpeed = true end
S.InfStamina = nil
local HttpService = game:GetService("HttpService")
local SAVE_FOLDER, SAVE_FILE = "DandyHub", "DandyHub/settings.json"
local THEME_LIST = { "Default", "Ocean", "AmberGlow", "Light", "Amethyst", "Green", "Bloom", "DarkBlue", "Serenity" }
local fileOK = type(writefile) == "function" and type(readfile) == "function"
local PERSIST_KEYS = {
    "MonsterESP", "PlayerESP", "ItemESP", "MachineESP", "ElevatorESP", "ShowNames",
    "SpeedEnabled", "SpeedValue", "AutoSprint", "AutoCalibrateSpeed", "LagPrevent",
    "Fullbright", "NoFog", "Noclip", "InstantInteract", "AutoCalibrateMachine",
    "AutoSave", "HubTheme", "ESPFill", "ESPThroughWalls", "NameSize",
    "HalloweenESP", "ChristmasESP", "EasterESP", "DoorESP",
    "EventAutoCollect", "TwistedAlert", "TwistedAlertDist",
}
pcall(function()
    if type(makefolder) == "function" then makefolder(SAVE_FOLDER) end
end)
local function serializeSettings()
    local t = {}
    for _, k in ipairs(PERSIST_KEYS) do t[k] = S[k] end
    local ok, json = pcall(HttpService.JSONEncode, HttpService, t)
    return ok and json or nil
end
local function loadSettings()
    if not fileOK then return end
    local ok, content = pcall(readfile, SAVE_FILE)
    if not ok or type(content) ~= "string" then return end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
    if not ok2 or type(data) ~= "table" then return end
    for _, k in ipairs(PERSIST_KEYS) do
        local def = DEFAULTS[k]
        if def ~= nil and type(data[k]) == type(def) then
            S[k] = data[k]
        end
    end
    local validTheme = false
    for _, t in ipairs(THEME_LIST) do if S.HubTheme == t then validTheme = true break end end
    if not validTheme then S.HubTheme = "Default" end
end
local lastSaveJSON = nil
local function saveSettingsNow(force)
    if not fileOK then return end
    if not force and not S.AutoSave then return end
    local snap = serializeSettings()
    if snap then
        lastSaveJSON = snap
        pcall(writefile, SAVE_FILE, snap)
    end
end
loadSettings()
lastSaveJSON = serializeSettings()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local OrigLighting = {}
pcall(function()
    OrigLighting.Brightness = Lighting.Brightness
    OrigLighting.Ambient = Lighting.Ambient
    OrigLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    OrigLighting.FogEnd = Lighting.FogEnd
    OrigLighting.GlobalShadows = Lighting.GlobalShadows
    OrigLighting.QualityLevel = settings().Rendering.QualityLevel
end)
local function getChar()
    local c = LocalPlayer.Character
    if c then
        local stats = c:FindFirstChild("Stats")
        if stats then
            return c, c:FindFirstChildOfClass("Humanoid"), stats
        end
    end
    local ip = workspace:FindFirstChild("InGamePlayers")
    local ic = ip and ip:FindFirstChild(LocalPlayer.Name)
    if ic then
        return ic, ic:FindFirstChildOfClass("Humanoid"), ic:FindFirstChild("Stats")
    end
    if c then
        return c, c:FindFirstChildOfClass("Humanoid"), nil
    end
    return nil
end
local noclipSaved = {}
pcall(function()
    getgenv().DandyHub_CharAdded = LocalPlayer.CharacterAdded:Connect(function() noclipSaved = {} end)
end)
getgenv().DandyHub_SprintWatch = getgenv().DandyHub_SprintWatch or {}
local watchedStats, watchedHum, watchedSp, watchedHs, watchedCs = nil, nil, nil, nil, nil
local function clearSprintWatch()
    local conns = getgenv().DandyHub_SprintWatch
    if conns then pcall(function() for _, c in ipairs(conns) do c:Disconnect() end end) end
    getgenv().DandyHub_SprintWatch = {}
    watchedStats, watchedHum, watchedSp, watchedHs, watchedCs = nil, nil, nil, nil, nil
end
local function hubSprintAutoOff(reason)
    if not S._speedToggle and not S._toggleWasOn then return end
    S._speedToggle = false
    local R = getgenv().DandyHub_Rayfield
    if R then pcall(function()
        R:Notify({ Title = "Sprint", Content = "Game stopped sprint (" .. reason .. ") - custom sprint OFF", Duration = 3 })
    end) end
end
local function watchSprintObjects(hum, stats)
    local sp = stats and stats:FindFirstChild("Sprinting")
    local hs = stats and stats:FindFirstChild("HoldingSprint")
    local cs = stats and stats:FindFirstChild("CurrentStamina")
    if watchedStats == stats and watchedHum == hum and watchedSp == sp and watchedHs == hs and watchedCs == cs then return end
    clearSprintWatch()
    watchedStats, watchedHum, watchedSp, watchedHs, watchedCs = stats, hum, sp, hs, cs
    local conns = getgenv().DandyHub_SprintWatch
    local function onFlag()
        if S._speedToggle or S._toggleWasOn then
            local spOff = watchedSp and watchedSp.Parent and not watchedSp.Value
            local hsOff = watchedHs and watchedHs.Parent and not watchedHs.Value
            if spOff or hsOff then hubSprintAutoOff("sprint ended") end
        end
    end
    if sp then conns[#conns + 1] = sp:GetPropertyChangedSignal("Value"):Connect(onFlag) end
    if hs and hs ~= sp then conns[#conns + 1] = hs:GetPropertyChangedSignal("Value"):Connect(onFlag) end
    if cs then conns[#conns + 1] = cs:GetPropertyChangedSignal("Value"):Connect(function()
        if (S._speedToggle or S._toggleWasOn) and watchedCs and watchedCs.Parent and watchedCs.Value <= 0 then
            hubSprintAutoOff("stamina empty")
        end
    end) end
    if hum then conns[#conns + 1] = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if (S._speedToggle or S._toggleWasOn) and watchedHum and watchedHum.Parent then
            local base = S._baseWalkSpeed or 16
            if math.abs(S.SpeedValue - base) > 1 and math.abs(watchedHum.WalkSpeed - base) < 0.5 then
                hubSprintAutoOff("speed reset")
            end
        end
    end) end
end
getgenv().DandyHub_StaminaConn = RunService.Stepped:Connect(function()
    local char, hum, stats = getChar()
    if S.Noclip and char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                if noclipSaved[v] == nil then noclipSaved[v] = v.CanCollide end
                if v.CanCollide then v.CanCollide = false end
            end
        end
    elseif next(noclipSaved) ~= nil then
        for part, canCollide in pairs(noclipSaved) do
            if part and part.Parent then part.CanCollide = canCollide end
        end
        noclipSaved = {}
    end
    if not char then return end
    if S.SpeedEnabled and S._speedToggle and hum then
        watchSprintObjects(hum, stats)
        hum.WalkSpeed = S.SpeedValue
        if stats then
            local rs = stats:FindFirstChild("RunSpeed")
            if rs then rs.Value = S.SpeedValue end
            local sp = stats:FindFirstChild("Sprinting")
            if sp then sp.Value = true end
            local hs = stats:FindFirstChild("HoldingSprint")
            if hs then hs.Value = true end
        end
    end
end)
local function stripEffects(obj)
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
        pcall(function() obj.Enabled = false end)
    elseif obj:IsA("BasePart") then
        pcall(function() obj.CastShadow = false end)
    end
end
local function applyInstantInteract(obj)
    if obj:IsA("ProximityPrompt") then
        pcall(function() obj.HoldDuration = 0 end)
    end
end
getgenv().DandyHub_PromptConn = workspace.DescendantAdded:Connect(function(obj)
    if S.InstantInteract then applyInstantInteract(obj) end
    if S.LagPrevent then stripEffects(obj) end
end)
local TOON_SPEEDS = {
    Brusha=25,Toodles=25,Blot=27.5,Glisten=25,Gigi=25,Rudie=25,Eggson=25,Astro=25,
    Soulvester=20,Sprout=27.5,Shrimpo=20,Squirm=25,Cosmo=25,Goob=27.5,Tisha=27.5,
    Eclipse=27.5,Shelly=28,RazzleDazzle=20,Connie=20,Boxten=25,Looey=25,Brightney=25,
    Finn=25,Yatta=27.5,Dyle=30,Scraps=22.5,Ribecca=25,Bobette=25,Ginger=22.5,Dandy=30,
    Rodger=22.5,Vee=22.5,Flutter=27.5,Poppy=25,Coal=27.5,Teagan=25,Bassie=30,
    Gourdy=27.5,Pebble=30,Cocoa=27.5,Flyte=27.5
}
local MAINS = { Astro=true, Pebble=true, Shelly=true, Sprout=true, Vee=true, Gourdy=true, Bobette=true, Bassie=true }
local seenMains = {}
local highlights = {}
local highlightsKind = {}
local nameTagged = {}
local function addHighlight(obj, color, kind)
    if not obj or not obj.Parent then return end
    if highlights[obj] and highlights[obj].Parent then
        if kind then highlightsKind[obj] = kind end
        return
    end
    local h = Instance.new("Highlight")
    h.Name = "DandyHubESP"
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = math.clamp(tonumber(S.ESPFill) or 0.5, 0, 1)
    h.OutlineTransparency = 0
    h.DepthMode = S.ESPThroughWalls == false and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = obj
    h.Parent = obj
    highlights[obj] = h
    if kind then highlightsKind[obj] = kind end
end
local function removeHighlight(obj)
    local h = highlights[obj]
    if h then pcall(function() h:Destroy() end) end
    highlights[obj] = nil
    highlightsKind[obj] = nil
    nameTagged[obj] = nil
    if obj then
        local bb = obj:FindFirstChild("DandyHubName")
        if bb then pcall(function() bb:Destroy() end) end
    end
end
local function stripESPKind(kind)
    for obj, k in pairs(highlightsKind) do
        if k == kind then removeHighlight(obj) end
    end
end
local function addNameBillboard(obj, text)
    if not obj or not obj.Parent then return end
    if obj:FindFirstChild("DandyHubName") then return end
    nameTagged[obj] = true
    local bb = Instance.new("BillboardGui")
    bb.Name = "DandyHubName"
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = obj
    bb.Parent = obj
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = text
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = math.clamp(math.floor(tonumber(S.NameSize) or 12), 8, 24)
    tl.Parent = bb
end
local function applyESPVisuals()
    local fill = math.clamp(tonumber(S.ESPFill) or 0.5, 0, 1)
    local depth = S.ESPThroughWalls == false and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
    for _, h in pairs(highlights) do
        if h and h.Parent then
            h.FillTransparency = fill
            h.DepthMode = depth
        end
    end
    local ns = math.clamp(math.floor(tonumber(S.NameSize) or 12), 8, 24)
    local function fixBB(obj)
        if obj and obj.Parent then
            local bb = obj:FindFirstChild("DandyHubName")
            local tl = bb and bb:FindFirstChildOfClass("TextLabel")
            if tl then tl.TextSize = ns end
        end
    end
    for obj in pairs(highlights) do fixBB(obj) end
    for obj in pairs(nameTagged) do fixBB(obj) end
end
local function clearAllHighlights()
    for obj, h in pairs(highlights) do
        pcall(function() h:Destroy() end)
        if obj and obj.Parent then
            local bb = obj:FindFirstChild("DandyHubName")
            if bb then pcall(function() bb:Destroy() end) end
        end
    end
    for obj in pairs(nameTagged) do
        if obj and obj.Parent then
            local bb = obj:FindFirstChild("DandyHubName")
            if bb then pcall(function() bb:Destroy() end) end
        end
    end
    highlights = {}
    highlightsKind = {}
    nameTagged = {}
end
local function isMainMonster(name)
    local base = name:gsub("Monster$", "")
    return MAINS[base], base
end
local function applyMonsterESP(m)
    if S.MonsterESP then
        addHighlight(m, Color3.fromRGB(255, 0, 0), "monster")
    else
        removeHighlight(m)
    end
    if S.ShowNames then
        local base = m.Name:gsub("Monster$", "")
        addNameBillboard(m, base)
    end
    local isMain, base2 = isMainMonster(m.Name)
    if isMain and S.MonsterESP and not seenMains[m] then
        seenMains[m] = true
        pcall(function()
            getgenv().DandyHub_Rayfield:Notify({
                Title = "Main Monster",
                Content = "Main: " .. base2 .. " on the map!",
                Duration = 5
            })
        end)
    end
end
local function applyItemESP(m)
    if S.ItemESP then
        addHighlight(m, Color3.fromRGB(0, 0, 255), "item")
    else
        removeHighlight(m)
    end
end
local function applyMachineESP(m)
    if S.MachineESP then
        addHighlight(m, Color3.fromRGB(255, 255, 0), "machine")
    else
        removeHighlight(m)
    end
end
local function applyElevatorESP(m)
    if S.ElevatorESP then
        addHighlight(m, Color3.fromRGB(170, 0, 255), "elevator")
    else
        removeHighlight(m)
    end
end
local function applyPlayerESP(m)
    if m.Name == LocalPlayer.Name then return end
    if S.PlayerESP then
        addHighlight(m, Color3.fromRGB(0, 255, 0), "player")
    else
        removeHighlight(m)
    end
end
local EVENT_KEYWORDS = {
    halloween = { "pumpkin", "halloween", "trick", "treat", "candy", "corn", "jack", "spook", "cauldron", "mask" },
    christmas = { "ornament", "christmas", "xmas", "gift", "festive", "stocking", "snowman", "reindeer", "peppermint" },
    easter = { "basket", "easter", "egg", "bunny", "chick", "carrot" },
}
local EVENT_COLORS = {
    halloween = Color3.fromRGB(255, 150, 0),
    christmas = Color3.fromRGB(0, 255, 170),
    easter = Color3.fromRGB(255, 150, 255),
}
local function eventOn(kind)
    if kind == "halloween" then return S.HalloweenESP end
    if kind == "christmas" then return S.ChristmasESP end
    if kind == "easter" then return S.EasterESP end
    return false
end
local function eventMatch(model, kind)
    local words = EVENT_KEYWORDS[kind]
    if not words then return false end
    local function hit(name)
        local n = string.lower(name)
        for _, w in ipairs(words) do
            if string.find(n, w, 1, true) then return true end
        end
        return false
    end
    if hit(model.Name) then return true end
    for _, d in ipairs(model:GetDescendants()) do
        if hit(d.Name) then return true end
    end
    return false
end
local function applyEventFirst(m)
    for _, kind in ipairs({ "halloween", "christmas", "easter" }) do
        if eventOn(kind) and eventMatch(m, kind) then
            addHighlight(m, EVENT_COLORS[kind], kind)
            return true
        end
    end
    return false
end
local function applyDoorESP(m)
    if S.DoorESP then
        addHighlight(m, Color3.fromRGB(255, 150, 0), "eventdoor")
        if S.ShowNames then addNameBillboard(m, "Trick or Treat") end
    else
        removeHighlight(m)
    end
end
local function classifyModel(m)
    if not m:IsA("Model") then return end
    local parent = m.Parent
    local pname = parent and parent.Name or ""
    if pname == "Monsters" then
        applyMonsterESP(m)
    elseif pname == "Items" or pname == "HolidayPickups" then
        if not applyEventFirst(m) then applyItemESP(m) end
    elseif pname == "TrickOrTreatDoors" then
        applyDoorESP(m)
    elseif pname == "InGamePlayers" then
        applyPlayerESP(m)
    elseif m.Name == "Elevator" then
        applyElevatorESP(m)
    elseif m.Name == "Machine" or m.Name == "Generator" or m.Name:find("Machine") then
        applyMachineESP(m)
    end
end
local espQueue = {}
local espQueueActive = false
local function queueSweep()
    if espQueueActive then return end
    local desc = workspace:GetDescendants()
    for i = #desc, 1, -1 do
        espQueue[#espQueue + 1] = desc[i]
    end
    espQueueActive = true
end
local function pumpSweep()
    if not espQueueActive then return end
    local n = 0
    while #espQueue > 0 and n < 400 do
        local obj = espQueue[#espQueue]
        espQueue[#espQueue] = nil
        n = n + 1
        if obj:IsA("Model") then
            classifyModel(obj)
        elseif obj:IsA("Folder") and (obj.Name == "Monsters" or obj.Name == "Items" or obj.Name == "HolidayPickups" or obj.Name == "TrickOrTreatDoors") then
            for _, m in ipairs(obj:GetChildren()) do
                if m:IsA("Model") then classifyModel(m) end
            end
        elseif obj:IsA("ProximityPrompt") then
            if S.InstantInteract then applyInstantInteract(obj) end
        elseif S.LagPrevent then
            stripEffects(obj)
        end
    end
    if #espQueue == 0 then espQueueActive = false end
end
getgenv().DandyHub_ESPConn = workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then
        classifyModel(obj)
    elseif obj:IsA("Folder") and (obj.Name == "Monsters" or obj.Name == "Items" or obj.Name == "HolidayPickups" or obj.Name == "TrickOrTreatDoors") then
        for _, m in ipairs(obj:GetChildren()) do
            if m:IsA("Model") then classifyModel(m) end
        end
    elseif obj:IsA("ProximityPrompt") then
        if S.InstantInteract then applyInstantInteract(obj) end
    elseif S.LagPrevent then
        stripEffects(obj)
    end
end)
local function applyLighting()
    pcall(function()
        if S.LagPrevent then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        elseif OrigLighting.QualityLevel then
            settings().Rendering.QualityLevel = OrigLighting.QualityLevel
        end
    end)
    if S.Fullbright then
        pcall(function()
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        end)
    else
        pcall(function()
            if OrigLighting.Brightness then Lighting.Brightness = OrigLighting.Brightness end
            if OrigLighting.Ambient then Lighting.Ambient = OrigLighting.Ambient end
            if OrigLighting.OutdoorAmbient then Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient end
        end)
    end
    if S.LagPrevent or S.NoFog then
        pcall(function() Lighting.FogEnd = 100000 end)
    else
        pcall(function()
            if OrigLighting.FogEnd then Lighting.FogEnd = OrigLighting.FogEnd end
        end)
    end
    if S.LagPrevent then
        pcall(function() Lighting.GlobalShadows = false end)
    else
        pcall(function()
            if OrigLighting.GlobalShadows ~= nil then Lighting.GlobalShadows = OrigLighting.GlobalShadows end
        end)
    end
end
local function pressSkillCheck(calBtn)
    if VIM then
        local ok = pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.delay(0.05, function()
                pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
            end)
        end)
        if ok then return true end
    end
    if type(firesignal) == "function" and calBtn then
        local ok = pcall(function()
            local fake = { UserInputType = Enum.UserInputType.MouseButton1 }
            firesignal(calBtn.InputBegan, fake)
            task.wait()
            firesignal(UserInputService.InputEnded, fake)
        end)
        if ok then return true end
    end
    return false
end
local frameCounter = 0
getgenv().DandyHub_Heartbeat = RunService.Heartbeat:Connect(function(dt)
    frameCounter = frameCounter + 1
    local hbChar, hbHum, hbStats = getChar()
    if S.SpeedEnabled then
        local char, hum, stats = hbChar, hbHum, hbStats
        if char and hum then
            local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            if shiftHeld and not S._shiftWasDown then
                S._shiftWasDown = true
                S._speedToggle = not S._speedToggle
                if S._speedToggle then
                    S._baseWalkSpeed = (stats and stats:FindFirstChild("WalkSpeed") and stats.WalkSpeed.Value)
                        or hum.WalkSpeed or 16
                    if stats then
                        local rs = stats:FindFirstChild("RunSpeed")
                        if rs then S._baseRunSpeed = rs.Value end
                    end
                end
                local R = getgenv().DandyHub_Rayfield
                if R then
                    pcall(function()
                        R:Notify({
                            Title = "Sprint",
                            Content = S._speedToggle and ("ON - " .. tostring(S.SpeedValue) .. " studs") or "OFF",
                            Duration = 2,
                        })
                    end)
                end
            elseif not shiftHeld then
                S._shiftWasDown = false
            end
            if S._speedToggle then
                if not S._toggleWasOn then
                    S._baseWalkSpeed = (stats and stats:FindFirstChild("WalkSpeed") and stats.WalkSpeed.Value)
                        or hum.WalkSpeed or 16
                    if stats then
                        local rs = stats:FindFirstChild("RunSpeed")
                        if rs then S._baseRunSpeed = rs.Value end
                    end
                end
                S._toggleWasOn = true
                hum.WalkSpeed = S.SpeedValue
                if stats then
                    local rs = stats:FindFirstChild("RunSpeed")
                    if rs then rs.Value = S.SpeedValue end
                    local sp = stats:FindFirstChild("Sprinting")
                    if sp then sp.Value = true end
                    local hs = stats:FindFirstChild("HoldingSprint")
                    if hs then hs.Value = true end
                end
            elseif S._toggleWasOn then
                S._toggleWasOn = false
                local base = S._baseWalkSpeed
                    or (stats and stats:FindFirstChild("WalkSpeed") and stats.WalkSpeed.Value)
                    or 16
                hum.WalkSpeed = base
                if stats then
                    local rs = stats:FindFirstChild("RunSpeed")
                    if rs and S._baseRunSpeed then rs.Value = S._baseRunSpeed end
                    local sp = stats:FindFirstChild("Sprinting")
                    if sp then sp.Value = false end
                    local hs = stats:FindFirstChild("HoldingSprint")
                    if hs then hs.Value = false end
                end
            end
        end
    elseif S._toggleWasOn then
        S._toggleWasOn = false
        S._speedToggle = false
        local char, hum, stats = getChar()
        if hum then
            hum.WalkSpeed = (stats and stats:FindFirstChild("WalkSpeed") and stats.WalkSpeed.Value) or 16
        end
        if stats then
            local rs = stats:FindFirstChild("RunSpeed")
            if rs and S._baseRunSpeed then rs.Value = S._baseRunSpeed end
            local sp = stats:FindFirstChild("Sprinting")
            if sp then sp.Value = false end
            local hs = stats:FindFirstChild("HoldingSprint")
            if hs then hs.Value = false end
        end
    end
    if S.AutoCalibrateMachine then
        pcall(function()
            local now = os.clock()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return end
            local R = getgenv().DandyHub_Rayfield
            local function calNotify(text)
                if R then pcall(function()
                    R:Notify({ Title = "Calibrate", Content = text, Duration = 1.5 })
                end) end
            end
            local sg = pg:FindFirstChild("ScreenGui")
            local menu = sg and sg:FindFirstChild("Menu")
            if menu and S._lastCalClick + 0.3 <= now then
                local scf = menu:FindFirstChild("SkillCheckFrame")
                local cal = menu:FindFirstChild("Calibrate") or menu:FindFirstChild("Calibrate1")
                if scf and cal and scf.Visible and cal.Visible then
                    local marker = scf:FindFirstChild("Marker")
                    local gold = scf:FindFirstChild("GoldArea")
                    if marker and gold then
                        local mX = marker.Position.X.Scale
                        local g0 = gold.Position.X.Scale
                        local g1 = g0 + gold.Size.X.Scale
                        local inset = (g1 - g0) * 0.15
                        if mX >= (g0 + inset) and mX <= (g1 - inset) then
                            S._lastCalClick = now
                            if pressSkillCheck(cal) then calNotify("Bar: great!") end
                        end
                    end
                end
            end
            if S._lastCalClick + 0.3 <= now then
                local cgui = pg:FindFirstChild("CircleSkillCheckGui")
                local cframe = cgui and cgui:FindFirstChild("SkillCheckFrame")
                if cframe and cframe.Visible then
                    local cont = cframe:FindFirstChild("Container")
                    local ring = cont and cont:FindFirstChild("ShrinkingCircle")
                    local yellow = cont and cont:FindFirstChild("YellowCircle")
                    local black = cont and cont:FindFirstChild("CenterHole")
                    if ring and yellow and black then
                        local r = ring.Size.X.Offset / 2
                        local yR = yellow.Size.X.Offset / 2
                        local bR = black.Size.X.Offset / 2
                        if r <= yR + 8 and r >= bR - 10 then
                            S._lastCalClick = now
                            if pressSkillCheck(nil) then calNotify("Circle: great!") end
                        end
                    end
                end
            end
            local tgui = pg:FindFirstChild("TreadmillTapSkillCheckGui")
            local tframe = tgui and tgui:FindFirstChild("TapSkillCheckFrame")
            if tframe and tframe.Visible then
                if S._lastTapPress + 0.09 <= now then
                    S._lastTapPress = now
                    pressSkillCheck(nil)
                end
            end
        end)
    end
    if S.AutoCalibrateSpeed then
        local acStats = hbStats
        local acRs = acStats and acStats:FindFirstChild("RunSpeed")
        local forcing = S.SpeedEnabled and (S._speedToggle or S._toggleWasOn)
        if acRs and not forcing then
            local cur = acRs.Value
            if S._lastSeenRunSpeed == nil then
                S._lastSeenRunSpeed = cur
            elseif cur > 0 and math.abs(cur - S._lastSeenRunSpeed) > 0.01 then
                S._lastSeenRunSpeed = cur
                local newsp = math.clamp(math.floor(cur + 3), 16, 40)
                S.SpeedValue = newsp
                local sl = getgenv().DandyHub_SpeedSlider
                if sl then pcall(function() sl:Set(newsp) end) end
                local R3 = getgenv().DandyHub_Rayfield
                if R3 then pcall(function()
                    R3:Notify({ Title = "Speed", Content = "Auto-calibrated: " .. newsp, Duration = 2 })
                end) end
            end
        end
    end
    if S.AutoSprint then
        local stats = hbStats
        if stats then
            local sp = stats:FindFirstChild("Sprinting")
            local hs = stats:FindFirstChild("HoldingSprint")
            if sp then sp.Value = true end
            if hs then hs.Value = true end
        end
    end
    local folderCache = getgenv().DandyHub_FolderCache
    if not folderCache then folderCache = {} getgenv().DandyHub_FolderCache = folderCache end
    local missAt = getgenv().DandyHub_FolderMiss
    if not missAt then missAt = {} getgenv().DandyHub_FolderMiss = missAt end
    local function getLiveFolder(name)
        local f = folderCache[name]
        if f and f.Parent then return f end
        local now = os.clock()
        if missAt[name] and now - missAt[name] < 5 then return nil end
        f = workspace:FindFirstChild(name, true)
        if f then
            folderCache[name] = f
            missAt[name] = nil
        else
            missAt[name] = now
        end
        return f
    end
    if S.TwistedAlert and frameCounter % 30 == 0 then
        pcall(function()
            local mons = getLiveFolder("Monsters")
            local hrp = hbChar and hbChar:FindFirstChild("HumanoidRootPart")
            if mons and hrp then
                local best, bestName = 1e9, nil
                for _, m in ipairs(mons:GetChildren()) do
                    if m:IsA("Model") then
                        local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            local d = (part.Position - hrp.Position).Magnitude
                            if d < best then best, bestName = d, m.Name end
                        end
                    end
                end
                local limit = tonumber(S.TwistedAlertDist) or 50
                if bestName and best <= limit and (S._lastTwistedWarn or 0) + 8 <= os.clock() then
                    S._lastTwistedWarn = os.clock()
                    local R4 = getgenv().DandyHub_Rayfield
                    if R4 then R4:Notify({
                        Title = "Twisted close",
                        Content = bestName:gsub("Monster$", "") .. " is " .. math.floor(best) .. " studs away",
                        Duration = 3,
                    }) end
                end
            end
        end)
    end
    if S.EventAutoCollect and frameCounter % 20 == 0 and type(fireproximityprompt) == "function" then
        pcall(function()
            local hrp = hbChar and hbChar:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, fname in ipairs({ "HolidayPickups", "Items" }) do
                local folder = getLiveFolder(fname)
                if folder then
                    for _, m in ipairs(folder:GetChildren()) do
                        if m:IsA("Model") then
                            local claimed = eventMatch(m, "halloween") or eventMatch(m, "christmas") or eventMatch(m, "easter")
                            if claimed then
                                local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
                                if part and (part.Position - hrp.Position).Magnitude <= 18 then
                                    local pr = m:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if pr then pcall(fireproximityprompt, pr) end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    pumpSweep()
    if frameCounter % 300 == 0 then
        for obj, h in pairs(highlights) do
            if not obj or not obj.Parent then
                if h then pcall(function() h:Destroy() end) end
                highlights[obj] = nil
                highlightsKind[obj] = nil
                nameTagged[obj] = nil
                seenMains[obj] = nil
            end
        end
    end
    if S.AutoSave and frameCounter % 60 == 0 then
        local snap = serializeSettings()
        if snap and snap ~= lastSaveJSON then
            lastSaveJSON = snap
            saveSettingsNow()
        end
    end
end)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "WhyULying",
    LoadingTitle = "WhyULying",
    LoadingSubtitle = "Dandy's World helper",
    Theme = (type(S.HubTheme) == "string" and S.HubTheme or "Default"),
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})
getgenv().DandyHub_Rayfield = Rayfield
local function makeTab(name, icon)
    local ok, tab = pcall(function() return Window:CreateTab(name, icon) end)
    if ok and tab then return tab end
    return Window:CreateTab(name)
end
local MainTab = makeTab("Main", "home")
local ESPTab = makeTab("ESP", "eye")
local WorldTab = makeTab("World", "globe")
local SpeedTab = makeTab("Speed", "zap")
local SkillTab = makeTab("Skill", "target")
local EventsTab = makeTab("Events", "ghost")
local VisualsTab = makeTab("Visuals", "palette")
local SystemTab = makeTab("System", "settings")
local CreditsTab = makeTab("Credits", "heart")
MainTab:CreateSection("Welcome")
pcall(function()
    MainTab:CreateParagraph({
        Title = "WhyULying",
        Content = "Your Dandy's World helper. Pick a tab on the left and flip on what you want.",
    })
end)
MainTab:CreateSection("Quick start")
pcall(function()
    MainTab:CreateParagraph({
        Title = "Three steps",
        Content = "1. Speed tab: turn on custom sprint, then press Shift. 2. Skill tab: auto skill check lands greats for you. 3. Events tab: holiday ESP lives here.",
    })
end)
ESPTab:CreateSection("Twisteds")
ESPTab:CreateToggle({
    Name = "Twisted ESP (Red)",
    CurrentValue = S.MonsterESP,
    Flag = "MonsterESP",
    Callback = function(v)
        S.MonsterESP = v
        if v then queueSweep() else stripESPKind("monster") end
    end,
})
ESPTab:CreateSection("Teammates")
ESPTab:CreateToggle({
    Name = "Teammate ESP (Green)",
    CurrentValue = S.PlayerESP,
    Flag = "PlayerESP",
    Callback = function(v)
        S.PlayerESP = v
        if v then queueSweep() else stripESPKind("player") end
    end,
})
ESPTab:CreateSection("Loot")
ESPTab:CreateToggle({
    Name = "Item ESP (Blue)",
    CurrentValue = S.ItemESP,
    Flag = "ItemESP",
    Callback = function(v)
        S.ItemESP = v
        if v then queueSweep() else stripESPKind("item") end
    end,
})
ESPTab:CreateSection("Warnings")
ESPTab:CreateToggle({
    Name = "Twisted distance alert",
    CurrentValue = S.TwistedAlert,
    Flag = "TwistedAlert",
    Callback = function(v) S.TwistedAlert = v end,
})
ESPTab:CreateSlider({
    Name = "Alert distance",
    Range = { 20, 120 },
    Increment = 5,
    Suffix = " studs",
    CurrentValue = math.clamp(math.floor(tonumber(S.TwistedAlertDist) or 50), 20, 120),
    Flag = "TwistedAlertDist",
    Callback = function(v) S.TwistedAlertDist = math.floor(v) end,
})
WorldTab:CreateSection("Highlights")
WorldTab:CreateToggle({
    Name = "Machine ESP (Yellow)",
    CurrentValue = S.MachineESP,
    Flag = "MachineESP",
    Callback = function(v)
        S.MachineESP = v
        if v then queueSweep() else stripESPKind("machine") end
    end,
})
WorldTab:CreateToggle({
    Name = "Elevator ESP (Purple)",
    CurrentValue = S.ElevatorESP,
    Flag = "ElevatorESP",
    Callback = function(v)
        S.ElevatorESP = v
        if v then queueSweep() else stripESPKind("elevator") end
    end,
})
ESPTab:CreateSection("Labels")
ESPTab:CreateToggle({
    Name = "Show Twisted names",
    CurrentValue = S.ShowNames,
    Flag = "ShowNames",
    Callback = function(v)
        S.ShowNames = v
        if v then
            queueSweep()
        else
            for obj in pairs(nameTagged) do
                if obj and obj.Parent then
                    local bb = obj:FindFirstChild("DandyHubName")
                    if bb then pcall(function() bb:Destroy() end) end
                end
                nameTagged[obj] = nil
            end
        end
    end,
})
local function detectToonSpeed()
    local char, hum, stats = getChar()
    if stats then
        local rs = stats:FindFirstChild("RunSpeed")
        if rs and rs.Value > 0 then
            return math.clamp(math.floor(rs.Value + 3), 16, 40)
        end
    end
    local name = nil
    if char then
        local cfg = char:FindFirstChild("Config")
        if cfg then
            local cn = cfg:FindFirstChild("CharacterName")
            if cn then name = cn.Value end
        end
    end
    if name and TOON_SPEEDS[name] then
        return math.clamp(math.floor(TOON_SPEEDS[name] + 3), 16, 40)
    end
    return 16
end
SpeedTab:CreateSection("Custom Sprint")
local SpeedSlider = SpeedTab:CreateSlider({
    Name = "Sprint Speed",
    Range = { 16, 40 },
    Increment = 1,
    Suffix = " studs",
    CurrentValue = S.SpeedValue,
    Flag = "SpeedValue",
    Callback = function(v) S.SpeedValue = math.clamp(math.floor(v), 16, 40) end,
})
getgenv().DandyHub_SpeedSlider = SpeedSlider
SpeedTab:CreateToggle({
    Name = "Enable Custom Sprint (Shift)",
    CurrentValue = S.SpeedEnabled,
    Flag = "SpeedEnabled",
    Callback = function(v)
        S.SpeedEnabled = v
        S._speedToggle = false
        S._shiftWasDown = false
        if v then
            S._toggleWasOn = false
            local sp = detectToonSpeed()
            S.SpeedValue = sp
            pcall(function() SpeedSlider:Set(sp) end)
            Rayfield:Notify({ Title = "Speed", Content = "Sprint speed set to " .. sp .. " - press Shift", Duration = 3 })
        else
            S._toggleWasOn = false
            local char, hum, stats = getChar()
            if hum then
                hum.WalkSpeed = (stats and stats:FindFirstChild("WalkSpeed") and stats.WalkSpeed.Value) or 16
            end
            if stats then
                local rs = stats:FindFirstChild("RunSpeed")
                if rs and S._baseRunSpeed then rs.Value = S._baseRunSpeed end
                local sp = stats:FindFirstChild("Sprinting")
                if sp then sp.Value = false end
                local hs = stats:FindFirstChild("HoldingSprint")
                if hs then hs.Value = false end
            end
        end
    end,
})
SpeedTab:CreateButton({
    Name = "Auto-detect Toon Speed",
    Callback = function()
        local sp = detectToonSpeed()
        S.SpeedValue = sp
        pcall(function() SpeedSlider:Set(sp) end)
        Rayfield:Notify({ Title = "Speed", Content = "Detected: " .. sp, Duration = 3 })
    end,
})
SpeedTab:CreateToggle({
    Name = "Auto-calibrate speed on change",
    CurrentValue = S.AutoCalibrateSpeed,
    Flag = "AutoCalibrateSpeed",
    Callback = function(v) S.AutoCalibrateSpeed = v end,
})
SpeedTab:CreateSection("Movement")
SpeedTab:CreateToggle({
    Name = "Auto Sprint (always sprinting)",
    CurrentValue = S.AutoSprint,
    Flag = "AutoSprint",
    Callback = function(v) S.AutoSprint = v end,
})
VisualsTab:CreateSection("Lighting")
VisualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = S.Fullbright,
    Flag = "Fullbright",
    Callback = function(v)
        S.Fullbright = v
        applyLighting()
    end,
})
VisualsTab:CreateToggle({
    Name = "No Fog",
    CurrentValue = S.NoFog,
    Flag = "NoFog",
    Callback = function(v)
        S.NoFog = v
        applyLighting()
    end,
})
SpeedTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = S.Noclip,
    Flag = "Noclip",
    Callback = function(v) S.Noclip = v end,
})
VisualsTab:CreateSection("Performance")
VisualsTab:CreateToggle({
    Name = "Lag Prevent",
    CurrentValue = S.LagPrevent,
    Flag = "LagPrevent",
    Callback = function(v)
        S.LagPrevent = v
        applyLighting()
        if v then
            queueSweep()
            Rayfield:Notify({ Title = "Lag Prevent", Content = "Optimized", Duration = 3 })
        end
    end,
})
SkillTab:CreateSection("Skill Checks")
pcall(function()
    SkillTab:CreateParagraph({
        Title = "Greats without trying",
        Content = "The bar, circle and treadmill checks are each timed for a GREAT for you. Treadmill taps always land GREAT once you finish them.",
    })
end)
SkillTab:CreateToggle({
    Name = "Auto Skill Check (All Greats)",
    CurrentValue = S.AutoCalibrateMachine,
    Flag = "AutoCalibrateMachine",
    Callback = function(v)
        S.AutoCalibrateMachine = v
        if v and not VIM and type(firesignal) ~= "function" then
            Rayfield:Notify({ Title = "Calibrate", Content = "This executor cannot send key presses, so auto check is off", Duration = 4 })
        end
    end,
})
SkillTab:CreateSection("Interaction")
SkillTab:CreateToggle({
    Name = "Instant Interact",
    CurrentValue = S.InstantInteract,
    Flag = "InstantInteract",
    Callback = function(v)
        S.InstantInteract = v
        if v then
            queueSweep()
        end
    end,
})
WorldTab:CreateSection("Travel")
WorldTab:CreateButton({
    Name = "Teleport to nearest machine",
    Callback = function()
        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local folder = workspace:FindFirstChild("Generators", true)
        local best, bestPart = 1e9, nil
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") then
                    local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local d = (part.Position - hrp.Position).Magnitude
                        if d < best then best, bestPart = d, part end
                    end
                end
            end
        end
        if bestPart then
            hrp.CFrame = bestPart.CFrame + Vector3.new(0, 5, 0)
            Rayfield:Notify({ Title = "Travel", Content = "Nearest machine is " .. math.floor(best) .. " studs away", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Travel", Content = "No machines on this floor", Duration = 3 })
        end
    end,
})
WorldTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        local char, hum, stats = getChar()
        if char and char:FindFirstChild("HumanoidRootPart") then
            local e = workspace:FindFirstChild("Elevators")
            local el = e and e:FindFirstChild("Elevator")
            if not el then
                el = workspace:FindFirstChild("Elevator", true)
            end
            if el then
                pcall(function()
                    local cf = nil
                    if el:IsA("Model") then
                        cf = el:GetPivot()
                    elseif el:IsA("BasePart") then
                        cf = el.CFrame
                    end
                    if cf then
                        char.HumanoidRootPart.CFrame = cf + Vector3.new(0, 5, 0)
                    end
                end)
                Rayfield:Notify({ Title = "Teleport", Content = "Teleported to elevator", Duration = 3 })
            else
                Rayfield:Notify({ Title = "Teleport", Content = "Elevator not found", Duration = 3 })
            end
        end
    end,
})
EventsTab:CreateSection("Halloween")
EventsTab:CreateToggle({
    Name = "Halloween ESP (Orange)",
    CurrentValue = S.HalloweenESP,
    Flag = "HalloweenESP",
    Callback = function(v)
        S.HalloweenESP = v
        if v then queueSweep() else stripESPKind("halloween") end
    end,
})
EventsTab:CreateToggle({
    Name = "Trick or Treat door ESP (Orange)",
    CurrentValue = S.DoorESP,
    Flag = "DoorESP",
    Callback = function(v)
        S.DoorESP = v
        if v then queueSweep() else stripESPKind("eventdoor") end
    end,
})
EventsTab:CreateSection("Christmas")
EventsTab:CreateToggle({
    Name = "Christmas ESP (Mint)",
    CurrentValue = S.ChristmasESP,
    Flag = "ChristmasESP",
    Callback = function(v)
        S.ChristmasESP = v
        if v then queueSweep() else stripESPKind("christmas") end
    end,
})
EventsTab:CreateSection("Easter")
EventsTab:CreateToggle({
    Name = "Easter ESP (Pink)",
    CurrentValue = S.EasterESP,
    Flag = "EasterESP",
    Callback = function(v)
        S.EasterESP = v
        if v then queueSweep() else stripESPKind("easter") end
    end,
})
EventsTab:CreateSection("Helpers")
EventsTab:CreateToggle({
    Name = "Auto collect nearby event loot",
    CurrentValue = S.EventAutoCollect,
    Flag = "EventAutoCollect",
    Callback = function(v)
        S.EventAutoCollect = v
        if v and type(fireproximityprompt) ~= "function" then
            Rayfield:Notify({ Title = "Auto collect", Content = "This executor cannot press prompts, so nothing will happen", Duration = 4 })
        end
    end,
})
EventsTab:CreateButton({
    Name = "Travel to nearest event item",
    Callback = function()
        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local best, bestPart = 1e9, nil
        for _, fname in ipairs({ "HolidayPickups", "Items" }) do
            local folder = workspace:FindFirstChild(fname, true)
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    if m:IsA("Model") then
                        local claimed = eventMatch(m, "halloween") or eventMatch(m, "christmas") or eventMatch(m, "easter")
                        if claimed then
                            local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                local d = (part.Position - hrp.Position).Magnitude
                                if d < best then best, bestPart = d, part end
                            end
                        end
                    end
                end
            end
        end
        if bestPart then
            hrp.CFrame = bestPart.CFrame + Vector3.new(0, 4, 0)
            Rayfield:Notify({ Title = "Travel", Content = "Took you to the closest event item", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Travel", Content = "No event items out right now", Duration = 3 })
        end
    end,
})
SystemTab:CreateSection("Hub")
SystemTab:CreateButton({
    Name = "Unload Hub",
    Callback = function()
        S.SpeedEnabled = false
        S._speedToggle = false
        S._shiftWasDown = false
        S._toggleWasOn = false
        local char, hum, stats = getChar()
        if hum then
            hum.WalkSpeed = (stats and stats:FindFirstChild("WalkSpeed") and stats.WalkSpeed.Value) or 16
        end
        if stats then
            local rs = stats:FindFirstChild("RunSpeed")
            if rs and S._baseRunSpeed then rs.Value = S._baseRunSpeed end
            local sp = stats:FindFirstChild("Sprinting")
            if sp then sp.Value = false end
            local hs = stats:FindFirstChild("HoldingSprint")
            if hs then hs.Value = false end
        end
        pcall(function()
            for part, canCollide in pairs(noclipSaved) do
                if part and part.Parent then part.CanCollide = canCollide end
            end
        end)
        noclipSaved = {}
        getgenv().DandyHub_SpeedSlider = nil
        if getgenv().DandyHub_Heartbeat then pcall(function() getgenv().DandyHub_Heartbeat:Disconnect() end) end
        if getgenv().DandyHub_NoclipConn then pcall(function() getgenv().DandyHub_NoclipConn:Disconnect() end) end
        if getgenv().DandyHub_StaminaConn then pcall(function() getgenv().DandyHub_StaminaConn:Disconnect() end) end
        if getgenv().DandyHub_StaminaRenderConn then pcall(function() getgenv().DandyHub_StaminaRenderConn:Disconnect() end) end
        if getgenv().DandyHub_PromptConn then pcall(function() getgenv().DandyHub_PromptConn:Disconnect() end) end
        if getgenv().DandyHub_ESPConn then pcall(function() getgenv().DandyHub_ESPConn:Disconnect() end) end
        if getgenv().DandyHub_LagConn then pcall(function() getgenv().DandyHub_LagConn:Disconnect() end) end
        if getgenv().DandyHub_CharAdded then pcall(function() getgenv().DandyHub_CharAdded:Disconnect() end) end
if getgenv().DandyHub_SprintWatch then pcall(function() for _, c in ipairs(getgenv().DandyHub_SprintWatch) do c:Disconnect() end end) end
        if getgenv().DandyHub_ClearStaminaGuard then pcall(getgenv().DandyHub_ClearStaminaGuard) end
        getgenv().DandyHub_Heartbeat = nil
        getgenv().DandyHub_NoclipConn = nil
        getgenv().DandyHub_StaminaConn = nil
        getgenv().DandyHub_StaminaRenderConn = nil
        getgenv().DandyHub_PromptConn = nil
        getgenv().DandyHub_ESPConn = nil
        getgenv().DandyHub_LagConn = nil
        getgenv().DandyHub_CharAdded = nil
getgenv().DandyHub_SprintWatch = nil
getgenv().DandyHub_FolderCache = nil
getgenv().DandyHub_FolderMiss = nil
        clearAllHighlights()
        seenMains = {}
        pcall(function()
            if OrigLighting.Brightness then Lighting.Brightness = OrigLighting.Brightness end
            if OrigLighting.Ambient then Lighting.Ambient = OrigLighting.Ambient end
            if OrigLighting.OutdoorAmbient then Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient end
            if OrigLighting.FogEnd then Lighting.FogEnd = OrigLighting.FogEnd end
            if OrigLighting.GlobalShadows ~= nil then Lighting.GlobalShadows = OrigLighting.GlobalShadows end
            if OrigLighting.QualityLevel then settings().Rendering.QualityLevel = OrigLighting.QualityLevel end
        end)
        saveSettingsNow(true)
        Rayfield:Destroy()
    end,
})
local UI = {}
VisualsTab:CreateSection("Theme")
UI.HubTheme = VisualsTab:CreateDropdown({
    Name = "UI Theme",
    Options = THEME_LIST,
    CurrentOption = S.HubTheme,
    MultipleOptions = false,
    Flag = "HubTheme",
    Callback = function(v)
        local t = (type(v) == "table") and v[1] or v
        if type(t) ~= "string" then return end
        S.HubTheme = t
        pcall(function() Window.ModifyTheme(t) end)
        Rayfield:Notify({ Title = "Theme", Content = "Theme: " .. tostring(t), Duration = 2 })
    end,
})
VisualsTab:CreateSection("ESP Appearance")
UI.ESPFill = VisualsTab:CreateSlider({
    Name = "Highlight Fill Transparency",
    Range = { 0, 100 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = math.floor((tonumber(S.ESPFill) or 0.5) * 100),
    Flag = "ESPFill",
    Callback = function(v) S.ESPFill = v / 100; applyESPVisuals() end,
})
UI.ESPThroughWalls = VisualsTab:CreateToggle({
    Name = "ESP Visible Through Walls",
    CurrentValue = S.ESPThroughWalls,
    Flag = "ESPThroughWalls",
    Callback = function(v) S.ESPThroughWalls = v; applyESPVisuals() end,
})
UI.NameSize = VisualsTab:CreateSlider({
    Name = "Monster Name Text Size",
    Range = { 8, 24 },
    Increment = 1,
    Suffix = "px",
    CurrentValue = math.clamp(math.floor(tonumber(S.NameSize) or 12), 8, 24),
    Flag = "NameSize",
    Callback = function(v) S.NameSize = math.floor(v); applyESPVisuals() end,
})
SystemTab:CreateSection("Auto-Save")
UI.AutoSave = SystemTab:CreateToggle({
    Name = "Auto-save settings on change",
    CurrentValue = S.AutoSave,
    Flag = "AutoSave",
    Callback = function(v) S.AutoSave = v; if v then saveSettingsNow() end end,
})
SystemTab:CreateButton({
    Name = "Save settings now",
    Callback = function()
        saveSettingsNow(true)
        Rayfield:Notify({ Title = "Auto-Save", Content = "Settings saved", Duration = 2 })
    end,
})
SystemTab:CreateButton({
    Name = "Reset customization defaults",
    Callback = function()
        S.HubTheme = DEFAULTS.HubTheme
        S.ESPFill = DEFAULTS.ESPFill
        S.ESPThroughWalls = DEFAULTS.ESPThroughWalls
        S.NameSize = DEFAULTS.NameSize
        S.AutoSave = DEFAULTS.AutoSave
        pcall(function() UI.HubTheme:Set(S.HubTheme) end)
        pcall(function() UI.ESPFill:Set(S.ESPFill * 100) end)
        pcall(function() UI.ESPThroughWalls:Set(S.ESPThroughWalls) end)
        pcall(function() UI.NameSize:Set(S.NameSize) end)
        pcall(function() UI.AutoSave:Set(S.AutoSave) end)
        saveSettingsNow(true)
        Rayfield:Notify({ Title = "Customize", Content = "Customization reset to defaults", Duration = 2 })
    end,
})
getgenv().DandyHub_UI = UI
CreditsTab:CreateSection("Credits")
pcall(function()
    CreditsTab:CreateParagraph({ Title = "Built by", Content = "qwilner" })
    CreditsTab:CreateParagraph({ Title = "Menu", Content = "Rayfield by Sirius" })
    CreditsTab:CreateParagraph({ Title = "Game", Content = "Dandy's World by BlushCrunch" })
end)
applyLighting()
if S.MonsterESP or S.PlayerESP or S.ItemESP or S.MachineESP or S.ElevatorESP or S.ShowNames or S.InstantInteract or S.LagPrevent or S.HalloweenESP or S.ChristmasESP or S.EasterESP or S.DoorESP then
    queueSweep()
end
print("[WhyULying v4.1] loaded")
