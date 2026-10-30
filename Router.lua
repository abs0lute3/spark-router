local CONFIG = {
    DANDY = {
        gameIds = {5569032992},
        placeIds = {16116270224},
        raw_url = "https://raw.githubusercontent.com/abs0lute3/spark-router/main/payloads/dandy-v1.enc",
        key = "luZkyFPys3dN7jO*idAixwna",
        encrypted = true,
    },
    BIKE = {
        gameIds = {10768284407},
        placeIds = {98628861455414},
        raw_url = "https://raw.githubusercontent.com/abs0lute3/spark-router/main/payloads/bike-v1.enc",
        key = "dqMkthmlvcv@XKAU0duIV2LJ",
        encrypted = true,
    },
}
local StarterGui = game:GetService("StarterGui")
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 6})
    end)
    print("[SparkRouter] " .. tostring(title) .. " - " .. tostring(text))
end
local function httpGet(url)
    if type(request) == "function" then
        local r = request({Url = url, Method = "GET"})
        return r.Body or r.body
    end
    if type(http_request) == "function" then
        local r = http_request({Url = url, Method = "GET"})
        return r.Body or r.body
    end
    if syn and syn.request then
        local r = syn.request({Url = url, Method = "GET"})
        return r.Body or r.body
    end
    return game:HttpGet(url)
end
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
local function inList(id, list)
    for _, v in ipairs(list) do
        if v == id then return true end
    end
    return false
end
local gid = game.GameId
local pid = game.PlaceId
if inList(gid, CONFIG.DANDY.gameIds) or inList(pid, CONFIG.DANDY.placeIds) then
    notify("SparkRouter", "Dandy's World detected, loading latest update", 5)
    local blob = httpGet(CONFIG.DANDY.raw_url)
    assert(type(blob) == "string" and #blob > 0, "[SparkRouter] empty response")
    local source = blob
    if CONFIG.DANDY.encrypted then
        source = xorCrypt(b64d(blob), CONFIG.DANDY.key)
    end
    assert(type(source) == "string" and #source > 0, "[SparkRouter] decrypt failed")
    notify("SparkRouter", "Fetched " .. #source .. " bytes, executing", 5)
    local fn, err = loadstring(source)
    if not fn then error("[SparkRouter] compile failed: " .. tostring(err)) end
    return fn()
elseif inList(gid, CONFIG.BIKE.gameIds) or inList(pid, CONFIG.BIKE.placeIds) then
    notify("SparkRouter", "Bike Universe detected, loading latest update", 5)
    local blob = httpGet(CONFIG.BIKE.raw_url)
    assert(type(blob) == "string" and #blob > 0, "[SparkRouter] empty response")
    local source = blob
    if CONFIG.BIKE.encrypted then
        source = xorCrypt(b64d(blob), CONFIG.BIKE.key)
    end
    assert(type(source) == "string" and #source > 0, "[SparkRouter] decrypt failed")
    notify("SparkRouter", "Fetched " .. #source .. " bytes, executing", 5)
    local fn, err = loadstring(source)
    if not fn then error("[SparkRouter] compile failed: " .. tostring(err)) end
    return fn()
else
    notify("SparkRouter", "Unsupported game " .. tostring(gid), 8)
    return
end
