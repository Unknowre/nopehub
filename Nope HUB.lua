local function Authenticate()
    repeat task.wait() until game:IsLoaded()
    local env = getgenv and getgenv() or _G
    if env.NOPE_HUB_UI_CLEANUP then pcall(env.NOPE_HUB_UI_CLEANUP) end
    local active, accepted, busy = true, false, false
    local sdk, library
    local keyPath = "NopeHub/AntEmpire/keys/" .. tostring(game.Players.LocalPlayer.UserId) .. ".txt"
    local function alive()
        return active and (not STATE or STATE.alive())
    end
    local function cleanup()
        active = false
        if library then pcall(function() library:Destroy() end) end
        if sdk then pcall(function() sdk.disconnect() end) end
    end
    env.NOPE_HUB_UI_CLEANUP = cleanup
    if STATE then STATE.onCleanup(cleanup) end
    setthreadidentity(8)
    library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local window = library:CreateWindow({Title = "Nope HUB", SubTitle = "Key System", TabWidth = 140, Size = UDim2.fromOffset(520, 350), Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightShift})
    library.GUI.Name = "NopeHubKeySystem"
    local tab = window:AddTab({Title = "Key", Icon = "key"})
    local input = tab:AddInput("LicenseKey", {Title = "Key", Default = "", Placeholder = "Enter your key", Finished = false})
    local remember = tab:AddToggle("RememberKey", {Title = "Remember Key", Default = true})
    local function notify(message)
        if alive() then
            setthreadidentity(8)
            library:Notify({Title = "Nope HUB", Content = message, Duration = 5})
        end
    end
    local function getSdk()
        if sdk then return sdk end
        local value = loadstring(game:HttpGet("https://secure.pandauth.com/pv4/lib"))()
        assert(type(value) == "table" and type(value.configure) == "function", "Panda SDK unavailable")
        value.configure({serviceId = "nopehub", debug = false, kickOnDetect = false})
        if not alive() then pcall(value.disconnect) error("Key window closed") end
        sdk = value
        return sdk
    end
    local function verify(key)
        if busy or not alive() or accepted then return end
        key = tostring(key or ""):match("^%s*(.-)%s*$")
        if key == "" then notify("Enter your key") return end
        busy = true
        task.spawn(function()
            local reason = "NETWORK"
            for attempt = 1, 3 do
                if not alive() then busy = false return end
                local ok, result = pcall(function() return getSdk().validate(key) end)
                if not alive() then busy = false return end
                if ok and type(result) == "table" and result.success == true then
                    if remember.Value and type(writefile) == "function" then
                        pcall(writefile, keyPath, key)
                    elseif type(isfile) == "function" and type(delfile) == "function" then
                        pcall(function() if isfile(keyPath) then delfile(keyPath) end end)
                    end
                    accepted, busy = true, false
                    return
                end
                reason = ok and type(result) == "table" and (result.reason or result.error) or "NETWORK"
                if reason == "INVALID_KEY" or reason == "NO_KEY" or reason == "NO_SERVICE" then break end
                if attempt < 3 then task.wait(attempt * 2) end
            end
            busy = false
            if reason == "INVALID_KEY" then
                notify("Key invalid, expired, or linked to another device")
            else
                notify("Unable to verify: " .. tostring(reason) .. ". Try again.")
            end
        end)
    end
    tab:AddButton({Title = "Get Key", Callback = function()
        task.spawn(function()
            local ok, link = pcall(function() return getSdk().getKeyUrl() end)
            if not alive() then return end
            if not ok or type(link) ~= "string" or link == "" then notify("Unable to get key link. Try again.") return end
            if type(setclipboard) == "function" and pcall(setclipboard, link) then
                notify("Get Key link copied. Open it in your browser.")
            else
                setthreadidentity(8)
                input:SetValue(link)
                notify("Copy the Get Key link from the input field")
            end
        end)
    end})
    tab:AddButton({Title = "Verify Key", Callback = function() verify(input.Value) end})
    tab:AddButton({Title = "Close", Callback = cleanup})
    window:SelectTab(1)
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, saved = pcall(function() return isfile(keyPath) and readfile(keyPath) or nil end)
        if ok and type(saved) == "string" and saved ~= "" then
            input:SetValue(saved)
            verify(saved)
        end
    end
    while alive() and not accepted and not library.Unloaded do task.wait(0.1) end
    if not accepted or not alive() then cleanup() return nil end
    setthreadidentity(8)
    library:Destroy()
    library = nil
    env.NOPE_HUB_UI_CLEANUP = nil
    return sdk
end

local function Boot()
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local LP = Players.LocalPlayer
local ENV = getgenv and getgenv() or _G
if ENV.NOPE_HUB_UI_CLEANUP then pcall(ENV.NOPE_HUB_UI_CLEANUP) end
local C = require(RS.Battle.Game.Context)
local Bus = require(RS.Packages.EventBus)
local H = C.Helper.PlayerDataHelper
local Room = C.Helper.RoomHelper
local Roll = require(RS.Battle.Game.Helper.RollPresentationHelper)
local Backpack = require(RS.UI.Backpack.Model.BackpackModel)
local PlayerData = require(RS.UI._global.PlayerData)
local DC = {Ecs = {Context = C}, PlayerData = PlayerData}
local Gear = require(RS.UI.GearShop.Model.GearShopModel)
local Compost = require(RS.UI.Compost.Model.CompostModel)
local Ride = require(RS.UI.Ride.Model.State)
local Tame = require(RS.UI.TamePanel.Model.State)
local Potions = require(RS.UI.AutoUserTool.Model.State)
local Online = require(RS.UI.OnlineReward.Model.OnlineState)
local Seven = require(RS.UI["7DAY"].Model.SevenDayState)
local Index = require(RS.UI.Index.Model.IndexModel)
local BlackMarket = require(RS.Battle.Game.Helper.Activities.BlackMarket)
local VineConfig = require(RS.Battle.Game.Helper.Activities.Vine.Config)
local ActivityEvent = require(RS.UI.ActivityEvent.Model.State)
local ClickBoost = require(RS.Battle.Game.Dungeon.ClickBoost)
local DungeonConfig = require(RS.Battle.Game.Config.DungeonConfig)
local ActivityScheduleConfig = require(RS.Battle.Game.Helper.Activities.ActivityScheduleConfig)
local FoodStore = require(RS.WuKongHooks.AntFoodStore)
local WK = require(RS.WuKong)
local purchaseGuard = {Active = true, Blocked = 0}
local queryTarget = WK.ExecuteQuery
local originalQuery
originalQuery = hookfunction(queryTarget, function(self, path, ...)
    if purchaseGuard.Active and type(path) == "string" and string.find(path, "弹出购买窗口", 1, true) then
        purchaseGuard.Blocked += 1
        return false
    end
    return originalQuery(self, path, ...)
end)
local function restorePurchaseGuard()
    if purchaseGuard.Active then
        purchaseGuard.Active = false
        restorefunction(queryTarget)
    end
end
if STATE then STATE.onCleanup(restorePurchaseGuard) end
local world, client
for _, connection in ipairs(getconnections(RS.MatterDiff.OnClientEvent)) do
    if connection.Function then
        for _, value in pairs(debug.getupvalues(connection.Function)) do
            if type(value) == "table" then
                if value._storages then world = value end
                if value.LocalPlayerAttributes then client = value end
            end
        end
    end
end
assert(world and client, "Game replication is not ready")
Gear:Init()
Index:Init()
Ride:Load()
ActivityEvent:Load()
setthreadidentity(8)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({Title = "Nope HUB", SubTitle = "Build An Ant Empire", TabWidth = 160, Size = UDim2.fromOffset(640, 500), Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightShift})
Fluent.GUI.Name = "NopeHubAntEmpire"
local bootCleanup = function() restorePurchaseGuard() setthreadidentity(8) pcall(function() Fluent:Destroy() end) end
ENV.NOPE_HUB_UI_CLEANUP = bootCleanup
if STATE then STATE.onCleanup(bootCleanup) end
local Tabs = {}
for _, entry in ipairs({{"Autofarm", "leaf"}, {"Upgrades", "trending-up"}, {"Resource Converter", "recycle"}, {"Trash", "trash-2"}, {"Dungeon", "swords"}, {"Events", "star"}, {"Gear", "shopping-cart"}, {"Potions", "flask-conical"}, {"Ride", "car"}, {"Rewards", "gift"}, {"Settings", "settings"}}) do
    Tabs[entry[1]] = Window:AddTab({Title = entry[1], Icon = entry[2]})
end
local running = true
local settings, options, jobs, errors, counts, connections = {}, {}, {}, {}, {}, {}
local configPath = "NopeHub/AntEmpire/" .. tostring(LP.UserId) .. ".json"
local configLoading = false
local configStore = {Version = 2, Profiles = {}, AutoLoad = ""}
if isfile(configPath) then
    local ok, data = pcall(function() return Http:JSONDecode(readfile(configPath)) end)
    if ok and type(data) == "table" then
        if data.Version == 2 and type(data.Profiles) == "table" then
            configStore = data
        elseif data.Version == 1 and type(data.Settings) == "table" then
            configStore.Profiles.Default = data.Settings
        end
    end
end
local selectedConfig, configName = nil, ""
local configDropdown
local function persistConfig()
    writefile(configPath, Http:JSONEncode(configStore))
end
local function configChanged() end
local function notifyConfig(message)
    Fluent:Notify({Title = "Config", Content = message, Duration = 3})
end
local function refreshConfigs()
    local names = {}
    for name in pairs(configStore.Profiles) do table.insert(names, name) end
    table.sort(names)
    if configDropdown then
        configDropdown:SetValues(names)
        if selectedConfig then configDropdown:SetValue(selectedConfig) end
    end
end
local function snapshotConfig()
    local snapshot = {}
    for id, option in pairs(options) do
        if option.Type == "Input" then
            snapshot[id] = tonumber(option.Value) or settings[id]
        else
            snapshot[id] = option.Value
        end
    end
    return Http:JSONDecode(Http:JSONEncode(snapshot))
end
local function createConfig(name)
    name = tostring(name or configName):match("^%s*(.-)%s*$")
    assert(name ~= "" and name ~= "None" and #name <= 64, "Enter a config name (1-64 characters)")
    assert(not configStore.Profiles[name], "Config already exists; use Overwrite Config")
    configStore.Profiles[name] = snapshotConfig()
    persistConfig()
    selectedConfig = name
    refreshConfigs()
    notifyConfig("Created: " .. name)
end
local function saveConfig(name)
    name = name or selectedConfig
    assert(name and configStore.Profiles[name], "Select a config first")
    configStore.Profiles[name] = snapshotConfig()
    persistConfig()
    notifyConfig("Saved: " .. name)
end
local function setAutoLoad(name)
    name = name == "None" and "" or name
    assert(name == "" or configStore.Profiles[name], "Config does not exist")
    configStore.AutoLoad = name
    persistConfig()
    refreshConfigs()
    notifyConfig(name == "" and "Auto load disabled" or "Auto load: " .. name)
end
local function loadConfig(name)
    name = name or selectedConfig
    assert(name and type(configStore.Profiles[name]) == "table", "Select a config first")
    local decoded = {Settings = configStore.Profiles[name]}
    configLoading = true
    local ok, err = pcall(function()
        setthreadidentity(8)
        for _, restoreToggles in ipairs({false, true}) do
            for id, value in pairs(decoded.Settings) do
                local option = options[id]
                if option and (jobs[id] ~= nil) == restoreToggles then
                    if jobs[id] then
                        if type(value) == "boolean" then option:SetValue(value) end
                    elseif option.Values then
                        if type(value) == "table" then
                            local selected = {}
                            for key, enabled in pairs(value) do
                                if enabled == true and table.find(option.Values, key) then selected[key] = true end
                            end
                            option:SetValue(selected)
                        elseif table.find(option.Values, value) then option:SetValue(value) end
                    elseif type(value) == "number" then
                        option:SetValue(tostring(value))
                    end
                end
            end
        end
    end)
    configLoading = false
    if not ok then error(err) end
    selectedConfig = name
    refreshConfigs()
end
local function live()
    return running and not Fluent.Unloaded and (not STATE or STATE.alive())
end
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
local function send(name, payload)
    if live() then C.SendCommand(name, payload or {}) end
end
local function gold() return H.GetPlayerGold(LP.UserId) end
local spending, spendReadyAt = nil, 0
local function spend(event, cost, callback)
    if not live() or spending or os.clock() < spendReadyAt then return false end
    cost = tonumber(cost)
    if not cost or cost < 0 or gold() < cost then return false end
    spending = {Event = event, Started = os.clock()}
    local ok, accepted = pcall(callback)
    if not ok or accepted == false then
        spending = nil
        spendReadyAt = os.clock() + 1
        if not ok then error(accepted) end
        return false
    end
    if not event then
        spending = nil
        spendReadyAt = os.clock() + 0.75
    end
    return true
end
local function room() return Room.GetLocalClientRoomObject() end
local function root() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function move(position)
    local part = root()
    if part and typeof(position) == "Vector3" then
        LP.Character:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
        return true
    end
    return false
end
local function toggle(tab, id, title, interval, callback, onDisable)
    setthreadidentity(8)
    settings[id] = false
    jobs[id] = {interval = interval, callback = callback, nextAt = 0, busy = false, onDisable = onDisable}
    local option = Tabs[tab]:AddToggle(id, {Title = title, Default = false})
    options[id] = option
    option:OnChanged(function(value)
        settings[id] = value == true
        jobs[id].nextAt = 0
        if not value and onDisable then pcall(onDisable) end
        configChanged()
    end)
end
local function dropdown(tab, id, title, values, multi, default)
    setthreadidentity(8)
    settings[id] = default or (multi and {} or nil)
    local option = Tabs[tab]:AddDropdown(id, {Title = title, Values = values, Multi = multi, Default = default or (multi and {} or nil)})
    options[id] = option
    option:OnChanged(function(value) settings[id] = value configChanged() end)
    return option
end
local function numberInput(tab, id, title, default)
    setthreadidentity(8)
    settings[id] = default
    local option = Tabs[tab]:AddInput(id, {Title = title, Default = tostring(default), Numeric = true, Finished = true})
    options[id] = option
    option:OnChanged(function(value) settings[id] = math.max(tonumber(value) or default, 0) configChanged() end)
end
local function button(tab, title, callback)
    setthreadidentity(8)
    Tabs[tab]:AddButton({Title = title, Callback = function()
        local ok, err = pcall(callback)
        if not ok then
            warn("[Nope HUB]", title, err)
            Fluent:Notify({Title = title, Content = tostring(err), Duration = 5})
        end
    end})
end
local function dungeon()
    local d = client.Core and client.Core.DungeonClient
    local entity = d and d.EntityId
    local session = entity and world:contains(entity) and world:get(entity, C.Components.DungeonClient)
    return session and session.Snapshot, d
end
local function collectFood()
    local ok, slots = FoodStore.GetSlots(LP.UserId)
    if not ok then return end
    local claims = {}
    for slot, amount in pairs(slots) do
        amount = math.floor(tonumber(amount) or 0)
        if tonumber(slot) and amount > 0 then table.insert(claims, {SlotIndex = tonumber(slot), Amount = amount}) end
    end
    if #claims > 0 then send("ClaimWorkerAntFood", {SubmissionId = Http:GenerateGUID(false), Claims = claims}) end
end
local price = nil
table.insert(connections, Bus.RemoteEvent.OnClientEvent:Connect(function(event, payload)
    if event == Room.FoodSellConfig.PriceUpdateEvent and type(payload) == "table" then price = payload end
    if spending and event == spending.Event then
        spending = nil
        spendReadyAt = os.clock() + 0.75
    end
end))
local function sellFood()
    local amount = H.GetPlayerFood(LP.UserId)
    if settings.BlackMarketSell and BlackMarket.IsSellOpen() then return end
    if amount > 0 then send("SellPlayerFood", {FoodAmount = amount, Source = "NopeHub"}) end
end
toggle("Autofarm", "CollectFood", "Auto Collect Food", 1.5, collectFood)
numberInput("Autofarm", "SellPrice", "Minimum Sell Price", 2)
toggle("Autofarm", "SellFood", "Auto Sell Food", 3, function()
    if not settings.SellByPrice then sellFood() end
end)
toggle("Autofarm", "SellByPrice", "Auto Sell By Price", 3, function()
    if price and (tonumber(price.GoldPerFood) or 0) >= settings.SellPrice then sellFood() end
    send("RequestSellFoodPrice", {})
end)
local nextRoll = 0
toggle("Autofarm", "RollAnt", "Auto Roll Ant", 0.3, function()
    if settings.VineRoll and workspace:GetAttribute("CurrentActivityId") == "Vine" then return end
    if os.clock() < nextRoll or Roll.IsPlaying() then return end
    nextRoll = os.clock() + math.max(H.GetPlayerRollInterval(C, LP.UserId), 0.5)
    send("RollAnt", {Source = "NopeHub"})
end)
local claimTimes = {}
local claimRarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exotic", "Secret", "Divine", "OP", "Celestial"}
dropdown("Autofarm", "ClaimRarities", "Buy Ant Rarity", claimRarities, true, table.clone(claimRarities))
toggle("Autofarm", "ClaimRolled", "Auto Buy Ant", 0.5, function()
    local manager = Roll.GetManager()
    for claimId, platform in pairs(manager and manager.ClaimPlatforms or {}) do
        local result = platform.Result
        local cost = result and tonumber(result.Cost)
        local config = result and C.Config.UnitConfig[result.UnitId] or {}
        local rarity = result and (result.Rarity or config.Rarity)
        local selected = rarity and (settings.ClaimRarities or {})[rarity] == true
        if result and result.ResultType ~= "Item" and selected and cost and gold() >= cost and not platform.ClaimRequested and os.clock() >= (claimTimes[claimId] or 0) then
            if spend("ClaimRolledAntResult", cost, function() send("ClaimRolledAnt", {ClaimId = claimId}) end) then
                claimTimes[claimId] = os.clock() + 4
                break
            end
        end
    end
end)
local slotNames, slotMap = {}, {}
local slotDropdowns = {}
local function refreshSlots()
    slotNames, slotMap = {}, {}
    for _, ant in ipairs((room() and room().LastAntsInfo) or {}) do
        local label = tostring(ant.SlotIndex) .. " - " .. tostring((C.Config.UnitConfig[ant.id] or {}).DisplayName or ant.id)
        table.insert(slotNames, label)
        slotMap[label] = ant.SlotIndex
    end
    setthreadidentity(8)
    for _, option in ipairs(slotDropdowns) do option:SetValues(slotNames) end
end
refreshSlots()
local equipBestSignature
toggle("Autofarm", "EquipBest", "Auto Equip Best", 3, function()
    if Backpack.IsEquipBestRunning then return end
    local data = Backpack:GetData()
    local parts = {}
    for value, count in pairs(data.Stacks or {}) do
        table.insert(parts, "S:" .. tostring(value) .. ":" .. tostring(count))
    end
    for slot, entry in pairs(data.EquippedBySlot or {}) do
        table.insert(parts, "E:" .. tostring(slot) .. ":" .. tostring(entry.V))
    end
    for slot, unlocked in pairs(data.UnlockedAntSlots or {}) do
        if unlocked then table.insert(parts, "U:" .. tostring(slot)) end
    end
    table.sort(parts)
    local signature = table.concat(parts, "|")
    if equipBestSignature == signature then return end
    if Backpack:EquipBest(function()
        if live() and settings.EquipBest then refreshSlots() end
    end) then equipBestSignature = signature end
end, function() equipBestSignature = nil end)
table.insert(slotDropdowns, dropdown("Upgrades", "UpgradeSlots", "Ant Slots", slotNames, true))
toggle("Upgrades", "UpgradeAnt", "Auto Upgrade Ant", 2.5, function()
    for label, selected in pairs(settings.UpgradeSlots or {}) do
        if selected and slotMap[label] then
            local ok, info = require(RS.WuKongHooks.BackPackStore).GetEquippedUpgradeInfo(LP.UserId, slotMap[label])
            if ok and info and spend(function()
                local equipped = Backpack:GetData().EquippedBySlot[tostring(slotMap[label])]
                return not equipped or equipped.V ~= info.V
            end, info.CostGold or info.CostFood, function()
                send("UpgradeEquippedAnt", {AntIndex = slotMap[label]})
            end) then break end
        end
    end
end)
local statMap = {["Expand the Ant Nest"] = "巢穴层数", ["Food Gain Multiplier"] = "蚂蚁攻击力", ["Ant Speed"] = "蚂蚁移速", ["Upgrade Egg Luck"] = "幸运值", ["Queen Level"] = "蚁后等级", ["Roll Count"] = "单抽数量"}
local statOrder = {"Expand the Ant Nest", "Food Gain Multiplier", "Ant Speed", "Upgrade Egg Luck", "Queen Level", "Roll Count"}
dropdown("Upgrades", "Stats", "Stats", statOrder, true)
toggle("Upgrades", "UpgradeStats", "Auto Upgrade Stats", 0.5, function()
    for _, label in ipairs(statOrder) do
        local selected = (settings.Stats or {})[label]
        local name = statMap[label]
        if selected and name then
            local info = H.GetPlayerUpgradeAttributeInfo(C, LP.UserId, name)
            if info and not info.IsMax and spend("UpgradePlayerAttributeResult", info.Price, function()
                send("UpgradePlayerAttribute", {AttributeName = name})
            end) then break end
        end
    end
end)
toggle("Upgrades", "UpgradePool", "Auto Upgrade Pool", 3, function()
    local cfg = H.GetPoolLevelUpgradeConfig(C, H.GetPlayerCardPoolLevel(LP.UserId))
    if cfg and cfg.NextLevel then spend("PoolLevelUpgradeResult", cfg.CostFood or cfg.Cost or cfg.FoodCost, function() send("PoolLevelUpgrade", {}) end) end
end)
toggle("Upgrades", "AddSlot", "Auto Unlock Ant Slot", 0.5, function()
    local data = Backpack:GetData()
    local count = 0
    for _, enabled in pairs(data.UnlockedAntSlots or {}) do if enabled then count += 1 end end
    local cfg = require(RS._genConfigs.battle_tbnestunlock)[count]
    if not cfg or gold() < cfg.Price then return end
    local unlockConfig = require(RS._genConfigs.battle_tbnestunlock)
    for index = 1, #unlockConfig + 1 do
        if not data.UnlockedAntSlots[tostring(index)] and Room.HasAntSlot(LP, index) then
            spend("AddAntSlotResult", cfg.Price, function() send("AddAntSlot", {SlotIndex = index, Source = "NopeHub"}) end)
            break
        end
    end
end)
button("Upgrades", "Refresh Ant Slots", refreshSlots)
local compostEntries = {}
dropdown("Resource Converter", "CompostRarities", "Ant Rarity", claimRarities, true)
local compostDropdown = dropdown("Resource Converter", "CompostAnts", "Ants", {}, true)
local function refreshCompost()
    Backpack:Refresh()
    local labels = {}
    compostEntries = {}
    for _, entry in ipairs(Backpack:BuildBackPackEntries(DC)) do
        if not entry.Favorite then
            local label = tostring((entry.UnitConfig or {}).DisplayName or entry.UnitId) .. " | " .. tostring(entry.Tag or "") .. " | Lv." .. tostring(entry.Level) .. " | " .. tostring(entry.V)
            table.insert(labels, label)
            compostEntries[label] = entry
        end
    end
    setthreadidentity(8)
    compostDropdown:SetValues(labels)
end
numberInput("Resource Converter", "CompostCount", "Ants Per Deposit", 1)
toggle("Resource Converter", "AutoCompost", "Auto Convert Ants", 4.5, function()
    local state = Compost:GetState(DC)
    if not state.Unlocked then return end
    if state.CanPull then Compost:PullLever(DC) return end
    if state.Progress >= 1 then return end
    refreshCompost()
    local data, items = Backpack:GetData(), {}
    for label, entry in pairs(compostEntries) do
        local rarity = entry.Rarity or (entry.UnitConfig or {}).Rarity
        local selected = (settings.CompostAnts or {})[label] == true or (settings.CompostRarities or {})[rarity] == true
        if selected and entry and not (data.Favorites or {})[entry.EntryKey] then
            local available = tonumber((data.Stacks or {})[tostring(entry.V)] or (data.Stacks or {})[entry.V]) or 0
            if available > 0 then items[entry.V] = math.min(available, math.floor(settings.CompostCount)) end
        end
    end
    if next(items) then Compost:AddAnts(DC, items) end
end)
toggle("Resource Converter", "UpgradeCompost", "Auto Upgrade Converter", 5, function()
    local state = Compost:GetState(DC)
    if state.CanUpgrade then spend("CompostMachineResult", state.UpgradePrice, function() return Compost:Upgrade(DC) end) end
end)
toggle("Resource Converter", "UnlockConverter", "Auto Unlock Converter", 2, function()
    local state = Compost:GetState(DC)
    if state.CanUnlock then
        spend(nil, state.UnlockPrice, function() return Compost:Unlock(DC) end)
    end
end)
toggle("Resource Converter", "PullConverter", "Auto Pull Lever", 1, function()
    local state = Compost:GetState(DC)
    if state.CanPull then Compost:PullLever(DC) end
end)
button("Resource Converter", "Refresh Ants", refreshCompost)
button("Resource Converter", "Unlock Converter", function()
    local state = Compost:GetState(DC)
    if state.CanUnlock then spend(nil, state.UnlockPrice, function() return Compost:Unlock(DC) end) end
end)
local trashEntries = {}
dropdown("Trash", "TrashRarities", "Ant Rarity", claimRarities, true)
local trashDropdown = dropdown("Trash", "TrashAnts", "Ants", {}, true)
numberInput("Trash", "TrashCount", "Ants Per Delete", 1)
local function refreshTrash()
    Backpack:Refresh()
    local labels = {}
    trashEntries = {}
    for _, entry in ipairs(Backpack:BuildBackPackEntries(DC)) do
        if not entry.Favorite then
            local label = tostring((entry.UnitConfig or {}).DisplayName or entry.UnitId) .. " | " .. tostring(entry.Tag or "") .. " | Lv." .. tostring(entry.Level) .. " | " .. tostring(entry.V)
            table.insert(labels, label)
            trashEntries[label] = entry
        end
    end
    setthreadidentity(8)
    trashDropdown:SetValues(labels)
end
toggle("Trash", "AutoTrash", "Auto Trash Ants", 3, function()
    refreshTrash()
    local data = Backpack:GetData()
    for label, entry in pairs(trashEntries) do
        local rarity = entry.Rarity or (entry.UnitConfig or {}).Rarity
        local selected = (settings.TrashAnts or {})[label] == true or (settings.TrashRarities or {})[rarity] == true
        local favorite = entry.Favorite or (data.Favorites or {})[entry.EntryKey] or (data.Favorites or {})["Ant:" .. tostring(entry.V)]
        local available = tonumber((data.Stacks or {})[tostring(entry.V)] or (data.Stacks or {})[entry.V]) or 0
        local count = math.min(available, math.floor(settings.TrashCount))
        if selected and not favorite and count > 0 then
            Backpack:ExecuteAction("/背包系统/背包移除物品?购买", {V = entry.V, Count = count, Section = "BackPack"})
            return
        end
    end
end)
button("Trash", "Refresh Ants", refreshTrash)

toggle("Dungeon", "AutoDungeon", "Auto Dungeon", 3, function()
    local snapshot, state = dungeon()
    if snapshot then
        if snapshot.status == "ready" then send("DungeonCommand", {Action = "Start", SessionId = snapshot.sessionId}) end
        return
    end
    if state and state.Transition then return end
    local folder = workspace:FindFirstChild("DungeonEntrances")
    for _, model in ipairs(folder and folder:GetChildren() or {}) do
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        local expires = tonumber(model:GetAttribute("ExpiresAt")) or 0
        if prompt and prompt.Enabled and expires > workspace:GetServerTimeNow() and model:GetAttribute("DungeonUsed_" .. tostring(LP.UserId)) ~= true then
            local part = prompt.Parent
            local position = part:IsA("Attachment") and part.WorldPosition or part:IsA("BasePart") and part.Position or model:GetPivot().Position
            if move(position) then
                task.wait(0.3)
                if live() and settings.AutoDungeon then fireproximityprompt(prompt) end
            end
            break
        end
    end
end)
toggle("Dungeon", "ClickBoost", "Auto Click Boost", 0.05, function()
    local snapshot, state = dungeon()
    if not snapshot or snapshot.status == "ready" or snapshot.status == "ended" or (state and state.Transition) then return end
    local now = workspace:GetServerTimeNow()
    local _, multiplier = ClickBoost.Project(snapshot.clickScore or 0, snapshot.attackSpeedMultiplier or 1, math.max(now - (snapshot.clickUpdatedAt or now), 0), DungeonConfig.ClickBoost)
    if multiplier < 4 then
        send("DungeonCommand", {Action = "Click", SessionId = snapshot.sessionId})
    end
end)
toggle("Dungeon", "TimeCoin", "Auto Pickup Time Coin", 0.75, function()
    local snapshot, state = dungeon()
    if not snapshot then return end
    for _, renderer in pairs(state.RendererResources or {}) do
        local coins = renderer.timeCoins
        if coins then
            for id, coin in pairs(coins.coins or {}) do
                if coin.landed and coin.positionConfirmed then
                    local position = coin.model and coin.model.Position or coin.data and coin.data.position
                    if position then move(position) end
                    coins:RequestPickup(id, workspace:GetServerTimeNow())
                    return
                end
            end
        end
    end
end)
toggle("Rewards", "Activity14DayReward", "Auto 14-Day Reward", 5, function()
    ActivityEvent:Refresh()
    for _, day in ipairs(ActivityEvent:GetDays()) do
        if day.Status == "Claim" then ActivityEvent:Claim(day.DayId) return end
    end
end)
local activityShopEntries, activityShopLabels = {}, {}
for _, entry in ipairs(ActivityEvent:GetShopCatalog()) do
    local label = tostring(entry.DisplayName) .. " [" .. tostring(entry.ProductId) .. "]"
    activityShopEntries[label] = entry
    table.insert(activityShopLabels, label)
end
dropdown("Events", "ActivityShopItems", "Activity Shop Items", activityShopLabels, true, {})
toggle("Events", "ActivityShop", "Auto Buy Activity Shop", 2, function()
    if ActivityEvent.PendingShopPurchase or ActivityEvent:GetActivityRemainingSeconds() <= 0 then return end
    ActivityEvent:Refresh()
    local balance = ActivityEvent:RefreshWishCurrencyBalance()
    for _, label in ipairs(activityShopLabels) do
        local entry = activityShopEntries[label]
        if settings.ActivityShopItems[label] and balance >= entry.Price and (entry.Limit <= 0 or ActivityEvent:GetShopPurchaseCount(entry.ProductId) < entry.Limit) then
            ActivityEvent:PurchaseShopItem(entry.ProductId)
            return
        end
    end
end)
toggle("Events", "VineRoll", "Auto Vine Roll", 0.2, function()
    if dungeon() or workspace:GetAttribute("CurrentActivityId") ~= "Vine" or (tonumber(workspace:GetAttribute("CurrentActivityCountdownSeconds")) or 0) <= 0 then return end
    if os.clock() < nextRoll or Roll.IsPlaying() then return end
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:GetAttribute(VineConfig.ReadyAttribute) == true then
            local base = model:FindFirstChild(VineConfig.BaseName)
            local queen = base and base:FindFirstChild(VineConfig.QueenPositionName)
            if queen and queen:IsA("BasePart") and move(queen.Position) then
                nextRoll = os.clock() + math.max(H.GetPlayerRollInterval(C, LP.UserId), 0.5)
                send("RollAnt", {Source = VineConfig.Id})
                return
            end
        end
    end
end)
toggle("Events", "BlackMarketSell", "Auto Black Market Sell", 1, function()
    if dungeon() or not BlackMarket.IsSellOpen() then return end
    local amount = H.GetPlayerFood(LP.UserId)
    if amount <= 0 then return end
    local part = BlackMarket.GetClientSellPart()
    if part and part:IsA("BasePart") and move(part.Position) then
        send("SellPlayerFood", {FoodAmount = amount, Source = "BlackMarket"})
    end
end)

toggle("Events", "TravelSnail", "Auto Travel Snail", 0.55, function()
    if dungeon() then return end
    local attributes = ActivityScheduleConfig.WorkspaceAttributes
    if workspace:GetAttribute(attributes.ActivityId) ~= "TravelSnail" or (tonumber(workspace:GetAttribute(attributes.CountdownSeconds)) or 0) <= 0 then return end
    WK:ExecuteAction("/功能商人/蜗牛活动抽奖?购买")
end)

toggle("Events", "StrawberryCoin", "Auto Strawberry Coin", 0.75, function()
    if dungeon() then return end
    for entity, coin in world:query(C.Components.StrawberryCoin) do
        if (tonumber(coin.ReadyAt) or math.huge) <= workspace:GetServerTimeNow() and (tonumber(coin.ExpiresAt) or 0) > workspace:GetServerTimeNow() then
            if move(coin.Position) then send("PickupStrawberryCoin", {CoinEntityId = entity}) end
            break
        end
    end
end)
dropdown("Events", "StarMode", "Star Event Mode", {"Submit", "Enter", "Submit + Enter"}, false, "Submit + Enter")
toggle("Events", "StarEvent", "Auto Star Event", 3, function()
    local state = client.Core and client.Core.StarEventClient and client.Core.StarEventClient.State
    if not state or dungeon() or not C.Helper.StarEventTime.IsActive() then return end
    if state.IsOpen and state.EndsAt > workspace:GetServerTimeNow() then
        if settings.StarMode ~= "Submit" then send("StarEventCommand", {Action = "Enter", CycleId = state.CycleId}) end
    elseif settings.StarMode ~= "Enter" then
        local config = require(RS.Battle.Game.Config.StarRollConfig)
        if LP:GetAttribute("BackpackHeldItemId") == config.ItemId and Backpack:GetItemCount(config.ItemId) > 0 then
            send("StarEventCommand", {Action = "Submit", CycleId = state.CycleId})
        end
    end
end)
toggle("Events", "StrawberryBase", "Auto Unlock Strawberry Base", 10, function()
    local state = require(RS.UI.StrawberryKingPanel.Model.State)
    if not state:IsStrawberryBaseUnlocked() and state:HasEnoughActivityCoin() then
        spend(nil, 0, function() return state:StrawberrgBaseUnlock() end)
    end
end)
local gearLabels, gearEntries = {}, {}
for _, entry in ipairs(Gear:GetCatalog()) do
    local label = entry.Config.DisplayName or entry.ItemId
    table.insert(gearLabels, label)
    gearEntries[label] = entry
end
dropdown("Gear", "GearItems", "Gear Items", gearLabels, true)
toggle("Gear", "BuyGear", "Auto Buy Gear", 3, function()
    for label, selected in pairs(settings.GearItems or {}) do
        local entry = gearEntries[label]
        if selected and entry and Gear:GetStock(entry.ItemId) > 0 and spend("GearShopResult", entry.Config.CoinPrice, function() return Gear:Purchase(entry.ItemId) end) then break end
    end
end)
button("Gear", "Refresh Stock", function() Gear:RequestSnapshot() end)
table.insert(slotDropdowns, dropdown("Potions", "PotionSlots", "Ant Slots", slotNames, true))
local potionIds = {}
local potionDropdown = dropdown("Potions", "Potion", "Potion", {}, false)
local function refreshPotions()
    local names = {}
    potionIds = {}
    for _, item in ipairs(Potions:GetAvailablePotions()) do
        table.insert(names, item.Name)
        potionIds[item.Name] = item.ItemId
    end
    setthreadidentity(8)
    potionDropdown:SetValues(names)
end
local potionEnabledSlots = {}
local function disablePotion()
    for slot in pairs(potionEnabledSlots) do Potions:RequestSetAutoUsePotion(slot, false) end
    table.clear(potionEnabledSlots)
end
toggle("Potions", "UsePotion", "Auto Use Potion", 5, function()
    local id = potionIds[settings.Potion]
    if not id then return end
    local active = {}
    for label, selected in pairs(settings.PotionSlots or {}) do
        local slot = slotMap[label]
        if selected and slot then
            active[slot] = true
            local equipped = Backpack:GetData().EquippedBySlot[tostring(slot)]
            if equipped then
                local effect = require(RS.Configs.PotionConfig).GetActiveEffect(equipped.PotionEffect)
                if not effect then Potions:RequestUsePotion(slot, id)
                elseif effect.Id == id and not equipped.AutoUsePotion then Potions:RequestSetAutoUsePotion(slot, true) end
                if effect and effect.Id == id then potionEnabledSlots[slot] = true end
            end
        end
    end
    for slot in pairs(potionEnabledSlots) do
        if not active[slot] then Potions:RequestSetAutoUsePotion(slot, false) potionEnabledSlots[slot] = nil end
    end
end, disablePotion)
button("Potions", "Refresh Potions", refreshPotions)
toggle("Ride", "AutoTame", "Auto Tame Held Unit", 4, function()
    local id = LP:GetAttribute("BackpackHeldAntValue")
    local key = LP:GetAttribute("BackpackHeldEntryKey")
    if id and not (Backpack:GetData().Favorites or {})[key] then spend(nil, 0, function() return Tame:TameUnit(true) end) end
end)
local rideIds = {}
local rideDropdown = dropdown("Ride", "RideUnit", "Ride", {}, false)
local function refreshRide()
    Ride:Refresh()
    local labels = {}
    rideIds = {}
    for _, entry in ipairs(Ride:GetEntries()) do
        if entry.Unlocked then
            table.insert(labels, entry.DisplayName)
            rideIds[entry.DisplayName] = entry.UnitId
        end
    end
    setthreadidentity(8)
    rideDropdown:SetValues(labels)
end
toggle("Ride", "EquipRide", "Auto Equip Ride", 5, function()
    local id = rideIds[settings.RideUnit]
    if id and Ride:GetEquippedUnitId() ~= id then
        if Tame:EquipRide(id) and live() then Bus.FireServer("Ride", {UnitName = id}) end
    end
end)
toggle("Ride", "RideReward", "Auto Ride Progress Reward", 8, function()
    Ride:Refresh()
    local reward = Ride:GetRewardState()
    if reward.CanClaim then Ride:ClaimProgressReward(reward.RewardIndex) end
end)
button("Ride", "Refresh Rides", refreshRide)
toggle("Rewards", "OnlineReward", "Auto Claim Online Rewards", 8, function()
    local index = Online:GetFirstClaimableRewardIndex()
    if index then Online:GetReward(index, DC) end
end)
toggle("Rewards", "IndexReward", "Auto Claim Index Rewards", 8, function()
    for _, tab in ipairs({"Ants", "Mutations"}) do
        local reward = Index:GetRewardState(tab)
        if reward and reward.CanClaim then Index:ClaimReward(tab) end
    end
end)
toggle("Rewards", "SevenReward", "Auto 7-Day Reward", 15, function() if Seven:IsAward() then Seven:GetReward() end end)
toggle("Rewards", "OfflineReward", "Auto Offline Reward", 5, function()
    local hud = LP.PlayerGui:FindFirstChild("HUDContainer")
    local frame = hud and hud:FindFirstChild("OfflineReward")
    if frame and frame.Visible then Bus.Fire("OfflineRewardCloseRequested") end
end)
dropdown("Settings", "Theme", "Theme", Fluent.Themes, false, "Dark"):OnChanged(function(value) settings.Theme = value Fluent:SetTheme(value) end)
local function stopAll()
    setthreadidentity(8)
    for id in pairs(jobs) do setthreadidentity(8) options[id]:SetValue(false) end
end
button("Settings", "Stop All", stopAll)
Tabs.Settings:AddSection("Config")
local configNameInput = Tabs.Settings:AddInput("ConfigName", {Title = "Config Name", Default = "default", Placeholder = "default", Finished = false})
configNameInput:OnChanged(function(value) configName = value end)
configDropdown = Tabs.Settings:AddDropdown("SelectConfig", {Title = "Select Config", Values = {}, Multi = false})
configDropdown:OnChanged(function(value)
    selectedConfig = value
    if value then configNameInput:SetValue(value) end
end)
button("Settings", "Refresh Configs", refreshConfigs)
button("Settings", "Create Config", function() createConfig(configNameInput.Value) end)
button("Settings", "Save Config", function()
    local name = tostring(configNameInput.Value):match("^%s*(.-)%s*$")
    if configStore.Profiles[name] then
        saveConfig(name)
        selectedConfig = name
        refreshConfigs()
    else
        createConfig(name)
    end
end)
button("Settings", "Overwrite Config", function() saveConfig() end)
button("Settings", "Load Config", function() loadConfig() end)
button("Settings", "Auto Load", function()
    assert(selectedConfig and configStore.Profiles[selectedConfig], "Select a saved config first")
    setAutoLoad(selectedConfig)
end)
button("Settings", "Disable Auto Load", function() setAutoLoad("None") end)
selectedConfig = configStore.Profiles[configStore.AutoLoad] and configStore.AutoLoad or nil
refreshConfigs()
local IconGui = Instance.new("ScreenGui")
IconGui.Name = "NopeHubToggle"
IconGui.ResetOnSpawn = false
IconGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
IconGui:SetAttribute("Map", "Build An Ant Empire")
IconGui.Parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
local IconButton = Instance.new("ImageButton")
IconButton.Name = "NopeHubIcon"
IconButton.Position = UDim2.fromOffset(12, 12)
IconButton.Size = UDim2.fromOffset(54, 54)
IconButton.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
IconButton.BorderSizePixel = 0
IconButton.Image = "rbxassetid://99169761989248"
IconButton.ZIndex = 100
IconButton.Parent = IconGui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = IconButton
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(190, 60, 255)
stroke.Thickness = 2
stroke.Parent = IconButton
connect(IconButton.Activated, function() Window:Minimize() end)
local function cleanup()
    if not running then return end
    running = false
    for id in pairs(settings) do if jobs[id] then settings[id] = false end end
    pcall(disablePotion)
    restorePurchaseGuard()
    setthreadidentity(8)
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    pcall(function() IconGui:Destroy() end)
    pcall(function() Fluent:Destroy() end)
end
ENV.NOPE_HUB_UI_CLEANUP = cleanup
if STATE then STATE.onCleanup(cleanup) end
button("Settings", "Unload", cleanup)
refreshCompost()
refreshTrash()
refreshPotions()
refreshRide()
if configStore.AutoLoad and configStore.AutoLoad ~= "" then
    local configOk, configError = pcall(loadConfig, configStore.AutoLoad)
    if not configOk then warn("[Nope HUB] Load Config", configError) end
end
send("RequestSellFoodPrice", {})
local API = {Settings = settings, Options = options, Jobs = jobs, Errors = errors, Counts = counts, Stop = stopAll, Cleanup = cleanup, Tabs = Tabs, Window = Window, Library = Fluent, PurchaseGuard = purchaseGuard}
API.SaveConfig = saveConfig
API.LoadConfig = loadConfig
API.ConfigPath = configPath
API.CreateConfig = createConfig
API.SetAutoLoad = setAutoLoad
API.ConfigStore = configStore
ENV.NOPE_ANT_HUB = API
_G.NOPE_ANT_HUB = API
if STATE then STATE.api = API end
task.spawn(function()
    while live() do
        local now = os.clock()
        if spending and type(spending.Event) == "function" then
            local ok, completed = pcall(spending.Event)
            if ok and completed then
                spending = nil
                spendReadyAt = now + 0.75
            end
        end
        if spending and now - spending.Started > 8 then
            spending = nil
            spendReadyAt = now + 5
        end
        for id, job in pairs(jobs) do
            if settings[id] and not job.busy and now >= job.nextAt then
                job.nextAt = now + job.interval
                job.busy = true
                task.spawn(function()
                    if live() and settings[id] then
                        local ok, err = pcall(job.callback)
                        if not ok then
                            errors[id] = tostring(err)
                            job.nextAt = os.clock() + math.max(job.interval, 10)
                            warn("[Nope HUB]", id, err)
                        else
                            errors[id] = nil
                            counts[id] = (counts[id] or 0) + 1
                        end
                    end
                    job.busy = false
                end)
            end
        end
        task.wait(settings.ClickBoost and 0.02 or 0.1)
    end
    cleanup()
end)
setthreadidentity(8)
Window:SelectTab(1)
end
task.spawn(function()
    local ok, err = xpcall(function()
        local sdk = Authenticate()
        if not sdk then return end
        local started, bootError = xpcall(Boot, debug.traceback)
        if not started then
            pcall(sdk.disconnect)
            error(bootError)
        end
        local env = getgenv and getgenv() or _G
        local hub = env.NOPE_ANT_HUB or _G.NOPE_ANT_HUB
        local hubCleanup = env.NOPE_HUB_UI_CLEANUP
        local function cleanupSession()
            pcall(sdk.disconnect)
            if hubCleanup then hubCleanup() end
        end
        env.NOPE_HUB_UI_CLEANUP = cleanupSession
        if hub then hub.Cleanup = cleanupSession end
        if STATE then STATE.onCleanup(cleanupSession) end
        while hub and hub.PurchaseGuard.Active and (not STATE or STATE.alive()) do
            task.wait(5)
            local checked, expired = pcall(sdk.isExpired)
            if checked and expired then
                cleanupSession()
                warn("[Nope HUB] Key expired. Run the script to get a new key.")
                return
            end
        end
        pcall(sdk.disconnect)
    end, debug.traceback)
    if not ok then warn("[Nope HUB]", err) end
end)
