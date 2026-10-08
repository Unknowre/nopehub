local ant = {
    Name = "Build An Ant Empire",
    Url = "https://raw.githubusercontent.com/Unknowre/nopehub/b239dd4d22247e6e5b4369a6306db69a42193915/Nope%20HUB.lua",
}

repeat task.wait() until game:IsLoaded()

local entry
if game.GameId == 3457700596 then
    entry = {
        Name = "Fruit Battlegrounds",
        Url = "https://raw.githubusercontent.com/Unknowre/nopehub/main/fruit-battlegrounds.lua",
    }
elseif game.PlaceId == 78490532994307 then
    entry = ant
else
    warn("Nope HUB: This map is not supported")
    return
end
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
