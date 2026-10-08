repeat task.wait() until game:IsLoaded()

local url = "https://raw.githubusercontent.com/Unknowre/nopehub/00f09212e1568ec54ae353776ec40b396559c7c7/FRG.obfuscated.lua"

local ok, source = pcall(function()
    return game:HttpGet(url)
end)
if not ok or type(source) ~= "string" or source == "" then
    warn("Nope HUB: Unable to download Fruit Battlegrounds. Try again.")
    return
end

local execute, compileError = loadstring(source)
if not execute then
    warn("Nope HUB: Unable to load Fruit Battlegrounds: " .. tostring(compileError))
    return
end

local success, runtimeError = pcall(execute)
if not success then
    warn("Nope HUB: " .. tostring(runtimeError))
end
