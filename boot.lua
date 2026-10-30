local BOOT_URL = "https://raw.githubusercontent.com/abs0lute3/spark-router/main/Router.enc"
local BOOT_KEY = "lCQEIk%5l8-$DxEEIu7Pkdrr"
local function httpGet(url)
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
        local r = 0
        if bit32 and bit32.bxor then
            r = bit32.bxor(db, kb)
        else
            local a, b, bit = db, kb, 1
            for _ = 1, 8 do
                if (a % 2) ~= (b % 2) then r = r + bit end
                a = math.floor(a / 2); b = math.floor(b / 2); bit = bit * 2
            end
        end
        out[i] = string.char(r)
    end
    return table.concat(out)
end
local blob = httpGet(BOOT_URL)
assert(type(blob) == "string" and #blob > 1000, "[Boot] download failed")
local source = xorCrypt(b64d(blob), BOOT_KEY)
local fn, err = loadstring(source)
if not fn then error("[Boot] router compile failed: " .. tostring(err)) end
return fn()
