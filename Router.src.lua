local CONFIG = {
    DANDY = {
        gameIds = {5569032992},
        placeIds = {16116270224},
        raw_url = "https://raw.githubusercontent.com/abs0lute3/spark-router/main/payloads/dandy-v1.lua",
    },
    BIKE = {
        gameIds = {10768284407},
        placeIds = {98628861455414},
        raw_url = "https://raw.githubusercontent.com/abs0lute3/spark-router/main/payloads/bike-v1.lua",
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
local function looksLikeLua(s)
    if type(s) ~= "string" then
        return false
    end
    if #s < 1000 then
        return false
    end
    return s:find("local") ~= nil or s:find("function") ~= nil or s:find("game") ~= nil
end
local function inList(id, list)
    for _, v in ipairs(list) do
        if v == id then return true end
    end
    return false
end
local function run(entry, label)
    notify("SparkRouter", label .. " detected, downloading update", 5)
    local source, err = httpGet(entry.raw_url)
    if not source then
        notify("SparkRouter", "Download failed: " .. tostring(err):sub(1, 120), 8)
        return
    end
    if not looksLikeLua(source) then
        notify("SparkRouter", "Payload invalid, got " .. #source .. " bytes starting with: " .. source:sub(1, 60), 8)
        return
    end
    notify("SparkRouter", "Fetched " .. #source .. " bytes, executing", 5)
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
