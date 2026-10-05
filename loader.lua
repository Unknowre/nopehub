local ant = {
    Name = "Build An Ant Empire",
    Url = "https://raw.githubusercontent.com/Unknowre/nopehub/main/Nope%20HUB.lua",
}
local kaiju = {
    Name = "Kaiju Alpha",
    Url = "https://raw.githubusercontent.com/Unknowre/nopehub/main/kaiju.obfuscated.lua",
}

repeat task.wait() until game:IsLoaded()

local entry = game.PlaceId == 78490532994307 and ant or kaiju

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
