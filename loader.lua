local supported = {
    [78490532994307] = {
        Name = "Build An Ant Empire",
        Url = "https://raw.githubusercontent.com/Unknowre/nopehub/main/Nope%20HUB.lua",
    },
}

repeat task.wait() until game:IsLoaded()

local entry = supported[game.PlaceId]
if not entry then
    local message = "Nope HUB: This map is not supported (PlaceId: " .. tostring(game.PlaceId) .. ")"
    warn(message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Nope HUB",
            Text = "This map is not supported",
            Duration = 6,
        })
    end)
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
