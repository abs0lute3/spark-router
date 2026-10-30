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
    local ok, res = pcall(function()
        if type(request) == "function" then
            local r = request({Url = url, Method = "GET", Timeout = 20})
            return r.Body or r.body
        end
        if type(http_request) == "function" then
            local r = http_request({Url = url, Method = "GET", Timeout = 20})
            return r.Body or r.body
        end
        if syn and syn.request then
            local r = syn.request({Url = url, Method = "GET", Timeout = 20})
            return r.Body or r.body
        end
        return game:HttpGet(url)
    end)
    if ok and type(res) == "string" and #res > 0 then
        return res
    end
    return nil, res
end
local function validPayload(s)
    if type(s) ~= "string" then
        return false
    end
    if #s < 1000 or #s > 5000000 then
        return false
    end
    if s:find("[^A-Za-z0-9%+/= \r\n\t]") then
        return false
    end
    return true
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
local function run(entry, label)
    notify("SparkRouter", label .. " detected, downloading update", 5)
    local blob, err = httpGet(entry.raw_url)
    if not blob then
        notify("SparkRouter", "Download failed: " .. tostring(err):sub(1, 120), 8)
        return
    end
    notify("SparkRouter", "Downloaded " .. #blob .. " bytes, decrypting", 5)
    if not validPayload(blob) then
        notify("SparkRouter", "Payload invalid, got " .. #blob .. " bytes starting with: " .. blob:sub(1, 60), 8)
        return
    end
    local source = blob
    if entry.encrypted then
        local ok, res = pcall(function()
            return xorCrypt(b64d(blob), entry.key)
        end)
        if not ok or type(res) ~= "string" or #res == 0 then
            notify("SparkRouter", "Decrypt failed: " .. tostring(res):sub(1, 120), 8)
            return
        end
        source = res
    end
    notify("SparkRouter", "Decrypted " .. #source .. " bytes, executing", 5)
    local fn, compErr = loadstring(source)
    if not fn then
        notify("SparkRouter", "Compile failed: " .. tostring(compErr):sub(1, 200), 8)
        return
    end
    return fn()
end
local gid = game.GameId
local pid = game.PlaceId
if inList(gid, CONFIG.DANDY.gameIds) or inList(pid, CONFIG.DANDY.placeIds) then
    return run(CONFIG.DANDY, "Dandy's World")
elseif inList(gid, CONFIG.BIKE.gameIds) or inList(pid, CONFIG.BIKE.placeIds) then
    return run(CONFIG.BIKE, "Bike Universe")
else
    notify("SparkRouter", "Unsupported game " .. tostring(gid), 8)
    return
end
