--[[=====================================================================
  SparkRouter v1 | private repo file. This is a ROBLOX script (Lua).
  ----------------------------------------------------------------------
  HOW IT WORKS:
    1. Detects which game you executed it in (GameId, PlaceId fallback).
    2. DANDY'S WORLD -> grabs the LATEST DandyHub paste below, sends a
       Roblox notification, decrypts it, and runs it.
    3. BIKE UNIVERSE -> nothing yet. Reserved for another AI agent.
       It only shows a "coming soon" notification and stops.
    4. Anything else -> "unsupported game" notification and stops.

  KEEPING IT FRESH (for AI agents / owner):
    After every `push.py update <name>`, if the KEY rotated (--new-key)
    copy the new `key` from pastes.json into DANDY.key below, then
    `git commit + push`. The raw_url stays the same on updates, so most
    of the time NOTHING needs changing here.
=====================================================================]]--

--// CONFIG: paste your latest values from pastes.json here ------------------
local CONFIG = {
    DANDY = {
        gameIds  = { 5569032992 },        -- Dandy's World universe id
        placeIds = { 16116270224 },       -- main place id (fallback check)
        raw_url   = "https://rentry.co/REPLACE-WITH-YOUR-SLUG/raw",
        key       = "REPLACE-WITH-YOUR-KEY",
        encrypted = true,
    },
    BIKE = {
        gameIds  = { 10768284407 },       -- Bike Universe universe id
        placeIds = { 98628861455414 },    -- main place id (fallback check)
        -- [[ RESERVED FOR ANOTHER AI AGENT. Do not fill in yet. ]]
        raw_url   = "",
        key       = "",
        encrypted = true,
    },
}

--// notification (works with no UI libs) ------------------------------------
local StarterGui = game:GetService("StarterGui")
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 6,
        })
    end)
    print("[SparkRouter] " .. tostring(title) .. " - " .. tostring(text))
end

--// fetch (executor-safe) -----------------------------------------------------
local function httpGet(url)
    if type(request) == "function" then
        local r = request({ Url = url, Method = "GET" })
        return r.Body or r.body
    end
    if type(http_request) == "function" then
        local r = http_request({ Url = url, Method = "GET" })
        return r.Body or r.body
    end
    if syn and syn.request then
        local r = syn.request({ Url = url, Method = "GET" })
        return r.Body or r.body
    end
    return game:HttpGet(url)
end

--// base64 decode + xor decrypt (matches encrypter.py) ------------------------
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local REV = {}
for i = 1, #B64 do REV[B64:sub(i, i)] = i - 1 end
local function b64d(data)
    data = data:gsub("%s+", "")
    local out, i = {}, 1
    while i <= #data do
        local c1 = REV[data:sub(i, i)] or 0
        local c2 = REV[data:sub(i + 1, i + 1)] or 0
        local c3 = REV[data:sub(i + 2, i + 2)] or 0
        local c4 = REV[data:sub(i + 3, i + 3)] or 0
        local pad = 0
        if data:sub(i + 3, i + 3) == "=" then pad = pad + 1 end
        if data:sub(i + 2, i + 2) == "=" then pad = pad + 1 end
        local t = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
        out[#out + 1] = string.char(math.floor(t / 65536) % 256)
        if pad < 2 then out[#out + 1] = string.char(math.floor(t / 256) % 256) end
        if pad < 1 then out[#out + 1] = string.char(t % 256) end
        i = i + 4
    end
    return table.concat(out)
end
local function xorCrypt(data, key)
    local out = {}
    for i = 1, #data do
        local db, kb = data:byte(i), key:byte(((i - 1) % #key) + 1)
        local r, bit = 0, 1
        if bit32 and bit32.bxor then
            r = bit32.bxor(db, kb)
        else
            local a, b = db, kb
            for _ = 1, 8 do
                if (a % 2) ~= (b % 2) then r = r + bit end
                a = math.floor(a / 2); b = math.floor(b / 2); bit = bit * 2
            end
        end
        out[i] = string.char(r)
    end
    return table.concat(out)
end

--// game detection --------------------------------------------------------------
local function inList(id, list)
    for _, v in ipairs(list) do
        if v == id then return true end
    end
    return false
end

local gid = game.GameId
local pid = game.PlaceId
local isDandy = inList(gid, CONFIG.DANDY.gameIds) or inList(pid, CONFIG.DANDY.placeIds)
local isBike  = inList(gid, CONFIG.BIKE.gameIds) or inList(pid, CONFIG.BIKE.placeIds)

--// route -------------------------------------------------------------------------
if isDandy then
    notify("SparkRouter", "Dandy's World detected — loading latest update…", 5)
    local blob = httpGet(CONFIG.DANDY.raw_url)
    assert(type(blob) == "string" and #blob > 0, "[SparkRouter] Empty response from " .. CONFIG.DANDY.raw_url)
    local source = blob
    if CONFIG.DANDY.encrypted then
        source = xorCrypt(b64d(blob:gsub("%s+$", "")), CONFIG.DANDY.key)
    end
    assert(#source > 0, "[SparkRouter] Decrypt produced nothing — check key in Router.lua.")
    notify("SparkRouter", "Latest DandyHub update fetched (" .. #source .. " bytes) — executing.", 5)
    local fn, err = loadstring(source)
    if not fn then error("[SparkRouter] Fetched code did not compile: " .. tostring(err)) end
    return fn()

elseif isBike then
    -- [[ NOTHING FOR BIKE UNIVERSE YET — reserved for another AI agent. ]]
    notify("SparkRouter", "Bike Universe detected — support coming soon (reserved).", 6)
    return
else
    notify("SparkRouter",
        "Unsupported game (GameId " .. tostring(gid) .. "). This loader only runs in Dandy's World / Bike Universe.", 8)
    return
end
