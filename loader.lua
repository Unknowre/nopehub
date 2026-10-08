local ant = {
    Name = "Build An Ant Empire",
    Url = "https://raw.githubusercontent.com/Unknowre/nopehub/c1d14d04f074e3f6aab4e258b5e4499bb51167dd/Nope%20HUB.lua",
}
local fruit = {
    Name = "Fruit Battlegrounds",
    Url = "https://raw.githubusercontent.com/Unknowre/nopehub/00f09212e1568ec54ae353776ec40b396559c7c7/FRG.obfuscated.lua",
}

repeat task.wait() until game:IsLoaded()

local entry = game.PlaceId == 78490532994307 and ant or fruit

local ok, source = pcall(function()
    return game:HttpGet(entry.Url)
end)
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
