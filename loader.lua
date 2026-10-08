local ant = {
    Name = "Build An Ant Empire",
    Url = "https://raw.githubusercontent.com/Unknowre/nopehub/ae04373f997ae03f662e59f4b0702b75d3349003/Nope%20HUB.lua",
}

repeat task.wait() until game:IsLoaded()

if game.PlaceId ~= 78490532994307 then
    warn("Nope HUB: This map is not supported")
    return
end
local entry = ant

local ok, source = pcall(function() return game:HttpGet(entry.Url) end)
if not ok or type(source) ~= "string" or source == "" then
    warn("Nope HUB: Unable to download " .. entry.Name .. ". Try again.")
    return
end
local execute, compileError = loadstring(source)
if not execute then
    warn("Nope HUB: Unable to load " .. entry.Name .. ": " .. tostring(compileError))
    return
end
local success, runtimeError = pcall(execute)
if not success then
    warn("Nope HUB: " .. tostring(runtimeError))
end
