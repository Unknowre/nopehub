local function createHubButton(Window, parent)
    local UIS = game:GetService("UserInputService")
    local gui = Instance.new("ScreenGui")
    gui.Name = "NopeHubToggle"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent
    local button = Instance.new("ImageButton")
    button.Name = "NopeHubIcon"
    button.AnchorPoint = Vector2.new(1, 0)
    button.Position = UDim2.new(1, -12, 0, 12)
    button.Size = UDim2.fromOffset(54, 54)
    button.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    button.BorderSizePixel = 0
    button.Image = "rbxassetid://99169761989248"
    button.ZIndex = 100
    button.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(190, 60, 255)
    stroke.Thickness = 2
    stroke.Parent = button
    local connections = {}
    local function connect(signal, fn) table.insert(connections, signal:Connect(fn)) end
    local press, origin, dragged, dragging, dragInput
    connect(button.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragged, dragInput = true, false, input
            press, origin = input.Position, button.AbsolutePosition
        end
    end)
    connect(UIS.InputChanged, function(input)
        if not dragging then return end
        if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - press
        if delta.Magnitude > 6 then dragged = true end
        if not dragged then return end
        local bounds = gui.AbsoluteSize
        local size = button.AbsoluteSize
        local x = math.clamp(origin.X + delta.X, 0, math.max(bounds.X - size.X, 0))
        local y = math.clamp(origin.Y + delta.Y, 0, math.max(bounds.Y - size.Y, 0))
        button.Position = UDim2.fromOffset(x + size.X, y)
    end)
    connect(UIS.InputEnded, function(input)
        if input == dragInput then dragging = false end
    end)
    connect(button.Activated, function() if not dragged then Window:Minimize() end end)
    return gui, function()
        for _, connection in ipairs(connections) do connection:Disconnect() end
        gui:Destroy()
    end
end

local function Boot()
    local Http = game:GetService("HttpService")
    local env = getgenv and getgenv() or _G
    if env.NOPE_HUB_UI_CLEANUP then pcall(env.NOPE_HUB_UI_CLEANUP) end
    if makefolder then for _, path in ipairs({"NopeHub", "NopeHub/UIOnly"}) do pcall(makefolder,path) end end
    if setthreadidentity then setthreadidentity(8) end
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local Window = Fluent:CreateWindow({Title = "NopeHUB", SubTitle = "Fruit battleground", TabWidth = 160, Size = UDim2.fromOffset(640, 500), Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightShift})
    local Skills = Window:AddTab({Title = "Autofarm", Icon = "swords"})


    local cleanupTasks = {}
    local buttonGui, cleanupButton = createHubButton(Window, (type(gethui) == "function" and gethui()) or game:GetService("CoreGui"))
    table.insert(cleanupTasks, cleanupButton)
    local active = true
    local function cleanup()
        if not active then return end
        active = false
        for _, fn in ipairs(cleanupTasks) do pcall(fn) end
        pcall(function() Fluent:Destroy() end)

    end
    env.NOPE_HUB_UI_CLEANUP = cleanup
    if STATE then STATE.onCleanup(cleanup) end
    local function notify(text)
        if active then Fluent:Notify({Title = "Nope HUB", Content = tostring(text), Duration = 4}) end
    end

    local Player = game:GetService("Players").LocalPlayer
    local UIS = game:GetService("UserInputService")
    local Loader = require(game.ReplicatedStorage.Loader)
    local AutoSkill = Skills:AddToggle("AutoSkill", {Title = "Auto Skill", Default = false})
    local SelectedSkills = Skills:AddDropdown("SelectedSkills", {
        Title = "Skills",
        Values = {}, Multi = false,
    })
    local useSkills = function() return AutoSkill.Value end
    local attempts = setmetatable({}, {__mode = "k"})
    local lastNames = ""
    local function running()
        return active and not Fluent.Unloaded and (not STATE or STATE.alive())
    end
    local function getSkills()
        local result = {}
        for _, container in ipairs({Player:FindFirstChild("Backpack"), Player.Character}) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and item:FindFirstChild("Handler") and item:GetAttribute("Level") ~= nil then
                        table.insert(result, item)
                    end
                end
            end
        end
        table.sort(result, function(a, b)
            local ak, bk = tonumber(a:GetAttribute("Key")) or 99, tonumber(b:GetAttribute("Key")) or 99
            if ak == bk then return a.Name < b.Name end
            return ak < bk
        end)
        return result
    end
    local function selected(name)
        local value = SelectedSkills.Value
        return value == nil or value == "" or value == name
    end
    local function ready(tool, character)
        if tool:GetAttribute("Locked") == true then return false end
        local id = tool.Name:gsub(" ", "")
        if Loader.MainFunctions:CheckStuns(Player, {id, id .. "CD"}) then return false end
        if Loader.MainFunctions:CheckStuns(character, {"CantAttack", "Stunned"}) then return false end
        local fruit = Loader.MainFunctions:GetFruit(Player)
        local level = fruit and fruit:FindFirstChild("Level")
        return level ~= nil and level.Value >= (tonumber(tool:GetAttribute("Level")) or 0)
    end
    local function inputAllowed()
        if Loader.IsTyping or UIS:GetFocusedTextBox() then return false end
        if type(isrbxactive) ~= "function" or not isrbxactive() then return false end
        local frame = Fluent.WindowFrame
        if frame and frame.Visible and Fluent.GUI.Enabled then
            local mouse = UIS:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
            local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
            if mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y then
                return false
            end
        end
        return true
    end
    task.spawn(function()
        while running() do
            local ok, err = pcall(function()
                local tools, names = getSkills(), {}
                for _, tool in ipairs(tools) do table.insert(names, tool.Name) end
                local signature = table.concat(names, "|")
                if signature ~= lastNames then
                    lastNames = signature
                    SelectedSkills:SetValues(names)
                end
                if not useSkills() then return end

                if not (not Loader.IsTyping and UIS:GetFocusedTextBox() == nil) then
                    return
                end
                local character = Player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then return end
                for _, tool in ipairs(tools) do
                    if selected(tool.Name) and ready(tool, character) and os.clock() >= (attempts[tool] or 0) then
                        attempts[tool] = os.clock() + 0.4
                        if tool.Parent ~= character then humanoid:EquipTool(tool) task.wait(0.05) end
                        if running() and useSkills() and selected(tool.Name) and Player.Character == character
                            and humanoid.Health > 0 and tool.Parent == character and ready(tool, character) and (not Loader.IsTyping and UIS:GetFocusedTextBox() == nil) then
                            local callback
                            local ok, values = pcall(debug.getupvalues, Loader.InputManager.AddInput)
                            if ok then for _, value in pairs(values) do
                                if type(value) == "table" and type(value.MouseDown) == "table" then callback = value.MouseDown.Skill break end
                            end end
                            if type(callback) == "function" then callback() end
                        end
                        break
                    end
                end
            end)
            if not ok then warn("Nope HUB: " .. tostring(err)) task.wait(1) end
            task.wait(0.05)
        end
    end)
    local BossTab = Window:AddTab({Title = "Boss", Icon = "skull"})
    local PvPTab = Window:AddTab({Title = "PvP", Icon = "swords"})
    local ESPTab = Window:AddTab({Title = "ESP", Icon = "eye"})
    local FruitsTab = Window:AddTab({Title = "Fruits", Icon = "apple"})
    local ProgressTab = Window:AddTab({Title = "Progress", Icon = "trending-up"})
    local TravelTab = Window:AddTab({Title = "Travel", Icon = "map"})
    local OtherTab = Window:AddTab({Title = "Other", Icon = "gift"})
    local features = {}
    local multiControls = {}
    local function option(tab, id, title, values, default)
        local multi = id == "ListName" or id == "BossTarget" or id == "SpinGoal" or id == "PvPTarget"
        local value = tab:AddDropdown(id, {Title = title, Values = values, Default = multi and (default and {default} or {}) or default, Multi = multi})
        multiControls[value] = multi
        features[id] = value
        return value
    end
    local function choices(control)
        local value = control.Value
        if type(value) == "string" then return {value} end
        local result = {}
        for _, name in ipairs(control.Values or {}) do
            if type(value) == "table" and value[name] then table.insert(result,name) end
        end
        return result
    end
    local function choice(control)
        return choices(control)[1]
    end
    local function setMulti(control,value)
        if type(value)=="boolean" or type(value)=="number" then control:SetValue(value) return end
        if multiControls[control] then
            if type(value)=="string" then control:SetValue({[value]=true})
            elseif type(value)=="table" then control:SetValue(value) end
        elseif type(value)=="table" then
            for _, name in ipairs(control.Values or {}) do
                if value[name] or table.find(value,name) then control:SetValue(name) return end
            end
        elseif type(value)=="string" then control:SetValue(value) end
    end
    local function toggle(tab, id, title)
        local value = tab:AddToggle(id, {Title = title, Default = false})
        features[id] = value
        return value
    end
    local function action(tab, title, callback, confirm)
        local busy = false
        local function run()
            if busy or not running() then return end
            busy = true
            task.spawn(function()
                local ok, result = pcall(callback)
                busy = false
                if not ok then notify(result) elseif type(result) == "string" then notify(result) end
            end)
        end
        tab:AddButton({Title = title, Callback = function()
            if confirm then
                Window:Dialog({Title = title, Content = confirm, Buttons = {
                    {Title = "Confirm", Callback = run}, {Title = "Cancel", Callback = function() end},
                }})
            else run() end
        end})
    end
    local bossTarget = option(BossTab, "BossTarget", "Boss", {"Any", "Marco", "Kaido", "Cake Queen", "Katakuri"}, "Any")
    local bossEnabled = toggle(BossTab, "AutoFarmBoss", "Auto Farm Boss")
    local bossNames = {Marco = true, Kaido = true, ["Cake Queen"] = true, Katakuri = true}
    local combatTarget
    useSkills = function() return AutoSkill.Value or (bossEnabled.Value and combatTarget and combatTarget.Parent ~= nil) end
    local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
    local spinGoal = option(FruitsTab, "SpinGoal", "Stop Rarity", rarities, "Legendary")
    local spinMode = option(FruitsTab, "SpinMode", "Spin Mode", {"Normal", "Fast"}, "Normal")
    local autoSpin = toggle(FruitsTab, "HubAutoSpin", "Auto Spin")
    local fruitGroups, fruitList, fruitHeaders = {}, {}, {}
    for name, data in pairs(Loader.FruitsHandler.Data) do
        if type(data) == "table" and data.Rarity then
            fruitGroups[data.Rarity] = fruitGroups[data.Rarity] or {}
            table.insert(fruitGroups[data.Rarity],name)
        end
    end
    for _, rarity in ipairs(rarities) do
        local names = fruitGroups[rarity] or {}
        table.sort(names)
        if #names > 0 then
            local header = "──── " .. rarity .. " ────"
            fruitHeaders[header] = true
            table.insert(fruitList,header)
            for _, name in ipairs(names) do table.insert(fruitList,name) end
        end
    end
    local listName = option(FruitsTab,"ListName","List Name",fruitList,nil)
    local function reachedFruitGoal(name,data)
        local hasTargets, matches = false,false
        for _, target in ipairs(choices(listName)) do
            if not fruitHeaders[target] then
                hasTargets = true
                if target == name then matches = true end
            end
        end
        if hasTargets then return matches end
        for _, rarity in ipairs(choices(spinGoal)) do
            if data and (table.find(rarities,data.Rarity) or 0) >= (table.find(rarities,rarity) or 5) then return true end
        end
        return false
    end
    local spinBusy, spinFinished = false, false
    autoSpin:OnChanged(function() spinFinished = false end)
    spinGoal:OnChanged(function() spinFinished = false end)
    local clearingHeaders = false
    listName:OnChanged(function(values)
        spinFinished = false
        if clearingHeaders then return end
        local cleaned, changed = {},false
        for name, enabled in pairs(values) do
            if fruitHeaders[name] then changed = true elseif enabled then cleaned[name] = true end
        end
        if changed then clearingHeaders = true listName:SetValue(cleaned) clearingHeaders = false end
    end)
    local function spinOnce()
        if spinBusy or spinFinished then return end
        local slot = Loader.MainFunctions:GetSlot(Player)
        local data = slot and Loader.FruitsHandler.Data[slot.Value]
        if reachedFruitGoal(slot.Value, data) then
            spinFinished = true
            return "Spin goal reached"
        end
        if (Player:GetAttribute("SpinCooldown") or 0) > 0 then return end
        if choice(spinMode) == "Fast" and not Loader.Monetization.PlayerOwnsGamepass(Player, Loader.Monetization.Gamepasses.FastSpin.ID) then
            spinFinished = true
            return "Fast Spin gamepass required"
        end
        spinBusy = true
        local ok, result, reason = pcall(Loader.Server, "FruitsHandler", "Spin", {Type = choice(spinMode) == "Fast" and "Fast" or nil})
        spinBusy = false
        if not ok then error(result) end
        if not result then spinFinished = true return tostring(reason or "Spin unavailable") end
        return type(result) == "string" and result or nil
    end
    action(FruitsTab, "Spin Once", spinOnce, "This spends Gems and replaces the selected slot's fruit.")
    local slotChoice = option(FruitsTab, "FruitSlot", "Fruit Slot", {}, nil)
    local function slotId(value)
        return tonumber(tostring(value):match("^%d+"))
    end
    local function refreshFruitSlots()
        local selectedSlots, names = {}, {}
        for _, value in ipairs(choices(slotChoice)) do
            local id = slotId(value)
            if id then selectedSlots[id] = true end
        end
        if not next(selectedSlots) then selectedSlots[tonumber(Player.MAIN_DATA.Slot.Value)] = true end
        local slots = Player.MAIN_DATA.Slots:GetChildren()
        table.sort(slots,function(a,b) return tonumber(a.Name)<tonumber(b.Name) end)
        local selectedNames = {}
        for _, slot in ipairs(slots) do
            local name = slot.Name .. " — " .. tostring(slot.Value)
            table.insert(names,name)
            if selectedSlots[tonumber(slot.Name)] then selectedNames[name] = true end
        end
        slotChoice:SetValues(names)
        setMulti(slotChoice,selectedNames)
    end
    action(FruitsTab, "Refresh Fruit in slot", refreshFruitSlots)
    action(FruitsTab, "Swap", function()
        local id = slotId(choice(slotChoice))
        assert(id, "Select a fruit slot")
        local slot = Player.MAIN_DATA.Slots:FindFirstChild(tostring(id))
        assert(slot and slot.Value ~= "None", "Selected slot has no fruit")
        local result = Loader.Server("FruitsHandler", "SwitchSlot", {Slot=id})
        refreshFruitSlots()
        return result
    end)
    action(ProgressTab, "Rebirth", function() return Loader.Server("Core", "Rebirth", {}) end,
        "This spends Gems and evolves your current fruit to a random fruit of the next rarity.")
    action(ProgressTab, "Unlock Soru", function() return Loader.Server("Core", "UnlockSoru", {}) end)
    local titleChoice = option(ProgressTab, "OwnedTitle", "Title", {}, nil)
    local function refreshTitles()
        local names = {}
        for _, title in ipairs(Player.MAIN_DATA.Titles:GetChildren()) do table.insert(names,title.Name) end
        table.sort(names)
        titleChoice:SetValues(names)
    end
    action(ProgressTab, "Refresh Titles", refreshTitles)
    action(ProgressTab, "Equip Title", function()
        assert(choice(titleChoice) and Player.MAIN_DATA.Titles:FindFirstChild(choice(titleChoice)), "Select an owned title")
        return Loader.Server("Titles", "Equip", {Type = "Titles", Title = choice(titleChoice)})
    end)
    local destinations = {Dressrosa = {9224601490,0}, ["Whole Cake"] = {16190471004,100}, Onigashima = {12413901502,200}}
    local destination = option(TravelTab, "Destination", "Destination", {"Dressrosa", "Whole Cake", "Onigashima"}, "Dressrosa")
    action(TravelTab, "Travel", function()
        local dest = destinations[choice(destination)]
        assert(Loader.MainFunctions:GetFruit(Player).Level.Value >= dest[2], "Required level: " .. dest[2])
        return Loader.Server("Core", "Teleport", {PlaceId = dest[1]})
    end)
    action(TravelTab, "Join Tournament", function()
        assert(Loader.Server("Core", "CheckAllMovesUnlocked", {}) == true, "Unlock all moves first")
        return Loader.Server("Core", "TeleportToTournament", {})
    end)
    action(TravelTab, "Ranked Duels", function() return Loader.Server("Core", "Teleport", {PlaceId = 17493355683}) end)
    refreshFruitSlots()
    refreshTitles()
    task.spawn(function()
        while running() do
            if autoSpin.Value then
                local ok, result = pcall(spinOnce)
                if not ok then spinFinished = true notify(result)
                elseif result then notify(result) end
            end
            task.wait(1)
        end
    end)
    local skyHeight = 8000
    local pvpTarget = option(PvPTab, "PvPTarget", "Player", {}, nil)
    local autoBehind = toggle(PvPTab, "AutoBehind", "Auto Farm Player")
    useSkills = function()
        if bossEnabled.Value or autoBehind.Value then
            local model = combatTarget and combatTarget.Parent
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            return humanoid ~= nil and humanoid.Health > 0
        end
        return AutoSkill.Value
    end
    local autoBlock = toggle(PvPTab, "AutoBlock", "Auto Block")
    local autoSoru = toggle(PvPTab, "AutoSoru", "Auto Soru")
    local espChams = toggle(ESPTab, "ESPChams", "Chams")
    local espName = toggle(ESPTab, "ESPName", "Name")
    local espHealth = toggle(ESPTab, "ESPHealth", "Health")
    local espDistance = toggle(ESPTab, "ESPDistance", "Distance")
    local espFruit = toggle(ESPTab, "ESPFruit", "Fruit")
    local function espEnabled() return espChams.Value or espName.Value or espHealth.Value or espDistance.Value or espFruit.Value end
    local autoRedeem = toggle(OtherTab, "AutoRedeem", "Auto Redeem Codes")
    local players = game:GetService("Players")
    local visuals, snapshots, held = {}, {}, {}
    local freezeRoot, freezeOrigin, freezeFrame
    local skillStartRoot, skillStartFrame
    local evadeUntil, threatUntil, nextSoru = 0, 0, 0
    local function refreshPlayers()
        local names = {}
        for _, other in ipairs(players:GetPlayers()) do if other ~= Player then table.insert(names, other.Name) end end
        table.sort(names)
        pvpTarget:SetValues(names)
    end
    action(PvPTab, "Refresh Players", refreshPlayers)
    refreshPlayers()
    local function setKey(key, down)
        if down and not held[key] then
            if type(keypress) == "function" then keypress(key) held[key] = true end
        elseif not down and held[key] then
            if type(keyrelease) == "function" then keyrelease(key) end
            held[key] = nil
        end
    end
    local function releaseFreeze(returnHome)
        if freezeRoot and freezeRoot.Parent then
            freezeRoot.AssemblyLinearVelocity = Vector3.zero
            freezeRoot.AssemblyAngularVelocity = Vector3.zero
            if returnHome and freezeOrigin then freezeRoot.CFrame = freezeOrigin end
        end
        freezeRoot, freezeOrigin, freezeFrame = nil, nil, nil
    end
    AutoSkill:OnChanged(function(value)
        if not value then
            releaseFreeze(false)
            local current = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if current and current == skillStartRoot and skillStartFrame then
                current.CFrame = skillStartFrame
                current.AssemblyLinearVelocity = Vector3.zero
                current.AssemblyAngularVelocity = Vector3.zero
            end
            skillStartRoot, skillStartFrame = nil, nil
            return
        end
        local c = Player.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if r and h and h.Health > 0 then
            skillStartRoot, skillStartFrame = r, r.CFrame
            if bossEnabled.Value or autoBehind.Value then return end
            freezeRoot, freezeOrigin = r, r.CFrame
            freezeFrame = r.CFrame + Vector3.new(0,skyHeight,0)
            r.CFrame = freezeFrame
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    local function removeVisual(other)
        local v = visuals[other]
        if v then v.highlight:Destroy() v.billboard:Destroy() visuals[other] = nil end
    end
    table.insert(cleanupTasks, function()
        releaseFreeze(true)
        for key in pairs(held) do setKey(key, false) end
        for other in pairs(visuals) do removeVisual(other) end
    end)
    local function nearestBoss(root)
        local characters = workspace:FindFirstChild("Characters")
        local folder = characters and characters:FindFirstChild("NPCs")
        if not folder then return end
        local best, distance
        for _, model in ipairs(folder:GetChildren()) do
            local h = model:FindFirstChildOfClass("Humanoid")
            local r = model:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 and (bossNames[model.Name] or model:GetAttribute("Boss") == true)
                and (bossTarget.Value.Any == true or bossTarget.Value[model.Name] == true) then
                local d = (r.Position - root.Position).Magnitude
                if not distance or d < distance then best, distance = r, d end
            end
        end
        return best
    end
    local function aim(target)
        local camera = workspace.CurrentCamera
        if not camera or not target then return end
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
        local point, visible = camera:WorldToViewportPoint(target.Position)
        if visible and type(mousemoveabs) == "function" then mousemoveabs(point.X,point.Y) end
    end
    local connection = game:GetService("RunService").Heartbeat:Connect(function()
        if not running() then return end
        local ok, err = pcall(function()
            local c = Player.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if not r or not h or h.Health <= 0 then releaseFreeze(false) return end
            if freezeRoot and freezeRoot ~= r then releaseFreeze(false) end
            if skillStartRoot and skillStartRoot ~= r then skillStartRoot, skillStartFrame = nil, nil end
            if bossEnabled.Value then
                releaseFreeze(false)
                local target = nearestBoss(r)
                combatTarget = target
                if target then
                    local pos = (target.CFrame * CFrame.new(0,8,12)).Position
                    r.CFrame = CFrame.lookAt(pos,target.Position)
                    r.AssemblyLinearVelocity = Vector3.zero
                    r.AssemblyAngularVelocity = Vector3.zero
                    if inputAllowed() then aim(target) end
                end
            elseif autoBehind.Value then
                combatTarget = nil
                releaseFreeze(false)
                local other, closest
                for _, name in ipairs(choices(pvpTarget)) do
                    local candidate = players:FindFirstChild(name)
                    local character = candidate and candidate.Character
                    local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                        local distance = (targetRoot.Position-r.Position).Magnitude
                        if not closest or distance < closest then other,closest=candidate,distance end
                    end
                end
                local target = other and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
                local targetH = other and other.Character and other.Character:FindFirstChildOfClass("Humanoid")
                combatTarget = targetH and targetH.Health > 0 and target or nil
                if target and targetH and targetH.Health > 0 then
                    local pos = (target.CFrame * CFrame.new(0,0,4)).Position
                    r.CFrame = CFrame.lookAt(pos,target.Position)
                    r.AssemblyLinearVelocity = Vector3.zero
                    if inputAllowed() then aim(target) end
                end
            elseif AutoSkill.Value and os.clock() >= evadeUntil then
                combatTarget = nil
                if not freezeRoot then
                    if not skillStartRoot then skillStartRoot, skillStartFrame = r, r.CFrame end
                    freezeRoot, freezeOrigin = r, skillStartFrame
                    freezeFrame = skillStartFrame + Vector3.new(0,skyHeight,0)
                end
                freezeFrame = CFrame.new(freezeFrame.Position.X,freezeOrigin.Position.Y+skyHeight,freezeFrame.Position.Z) * freezeFrame.Rotation
                r.CFrame = freezeFrame
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            elseif not AutoSkill.Value then
                releaseFreeze(true)
            end
        end)
        if not ok then warn("Nope HUB movement: " .. tostring(err)) end
    end)
    table.insert(cleanupTasks,function() connection:Disconnect() end)
    task.spawn(function()
        while running() do
            local ok, err = pcall(function()
                if setthreadidentity then setthreadidentity(8) end
                local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local danger = false
                local present = {}
                for _, other in ipairs(players:GetPlayers()) do
                    if other ~= Player then
                        present[other] = true
                        local c = other.Character
                        local r = c and c:FindFirstChild("HumanoidRootPart")
                        local h = c and c:FindFirstChildOfClass("Humanoid")
                        if espEnabled() and c and r and h then
                            local v = visuals[other]
                            if v and v.character ~= c then removeVisual(other) v = nil end
                            if not v then
                                local highlight = Instance.new("Highlight")
                                highlight.Name = "NopeHubChams"
                                highlight.Adornee = c
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                highlight.FillColor = Color3.fromRGB(80,180,255)
                                highlight.FillTransparency = 0.65
                                highlight.Parent = c
                                local billboard = Instance.new("BillboardGui")
                                billboard.Name = "NopeHubInfo"
                                billboard.Adornee = r
                                billboard.AlwaysOnTop = true
                                billboard.Size = UDim2.fromOffset(240,65)
                                billboard.StudsOffset = Vector3.new(0,4,0)
                                billboard.Parent = Fluent.GUI
                                local label = Instance.new("TextLabel")
                                label.Size = UDim2.fromScale(1,1)
                                label.BackgroundTransparency = 1
                                label.TextColor3 = Color3.new(1,1,1)
                                label.TextStrokeTransparency = 0.3
                                label.Font = Enum.Font.GothamBold
                                label.TextSize = 13
                                label.Parent = billboard
                                v = {highlight=highlight,billboard=billboard,label=label,character=c}
                                visuals[other] = v
                            end
                            local fruit = c:GetAttribute("Form") or "Unknown"
                            local data = other:FindFirstChild("MAIN_DATA")
                            local slots = data and data:FindFirstChild("Slots")
                            local index = data and data:FindFirstChild("Slot")
                            local slot = slots and index and slots:FindFirstChild(tostring(index.Value))
                            if slot then fruit = slot.Value end
                            local distance = root and math.floor((root.Position-r.Position).Magnitude) or 0
                            local lines = {}
                            if espName.Value then table.insert(lines,other.DisplayName) end
                            if espHealth.Value then table.insert(lines,string.format("HP %.0f / %.0f",h.Health,h.MaxHealth)) end
                            if espDistance.Value then table.insert(lines,tostring(distance).." studs") end
                            if espFruit.Value then table.insert(lines,tostring(fruit)) end
                            v.highlight.Enabled = espChams.Value
                            v.billboard.Enabled = #lines > 0
                            v.label.Text = table.concat(lines,"\n")
                        else removeVisual(other) end
                        local old = snapshots[other]
                        local attrs = other:GetAttributes()
                        snapshots[other] = attrs
                        if old and root and r and h and h.Health > 0 and (r.Position-root.Position).Magnitude <= 70 then
                            local toward = root.Position-r.Position
                            local facing = toward.Magnitude < 1 or r.CFrame.LookVector:Dot(toward.Unit) > 0.25
                            if facing then
                                for key, value in pairs(attrs) do
                                    if type(value) == "number" and value > (tonumber(old[key]) or 0)
                                        and key:sub(-2) == "CD" and key ~= "SpinCooldown" then
                                        threatUntil = math.max(threatUntil,os.clock()+0.6)
                                    end
                                end
                                if (c:GetAttribute("M1ing") or 0) > 0 then threatUntil = math.max(threatUntil,os.clock()+0.2) end
                            end
                        end
                    end
                end
                for other in pairs(visuals) do if not present[other] then removeVisual(other) end end
                for other in pairs(snapshots) do if not present[other] then snapshots[other]=nil end end
                danger = os.clock() < threatUntil
                local allowed = inputAllowed()
                setKey(0x46, autoBlock.Value and danger and allowed)
                local c = Player.Character
                if autoSoru.Value and danger and allowed and c and os.clock() >= nextSoru
                    and (Player:GetAttribute("Soru") or Player.MAIN_DATA:FindFirstChild("Soru"))
                    and not Loader.MainFunctions:CheckStuns(c,{"SoruCD","DashCD","Stunned","CantDash"}) then
                    nextSoru = os.clock()+1
                    evadeUntil = os.clock()+0.25
                    setKey(0x44,true)
                    task.wait(0.05)
                    if running() and autoSoru.Value and inputAllowed() then setKey(0x51,true) end
                    task.wait(0.08)
                    setKey(0x51,false)
                    setKey(0x44,false)
                end
            end)
            if not ok then
                for key in pairs(held) do setKey(key,false) end
                warn("Nope HUB ESP/PvP: " .. tostring(err))
            end
            task.wait(0.05)
        end
    end)
    local redeemFinished = false
    autoRedeem:OnChanged(function() redeemFinished = false end)
    local redeemed = {}
    task.spawn(function()
        while running() do
            if autoRedeem.Value and not redeemFinished then
                local codes = {"EVENHIGHER!","OMGUPDATE22"}
                local ok, page = pcall(function() return game:HttpGet("https://progameguides.com/roblox/fruits-battlegrounds-codes/") end)
                if ok and type(page)=="string" then
                    local startAt = page:find("Fruit Battlegrounds Active Codes",1,true)
                    local endAt = startAt and page:find("Fruit Battlegrounds Inactive Codes",startAt+1,true)
                    local part = startAt and endAt and page:sub(startAt,endAt-1)
                    if part then for code in part:gmatch('data%-code="([%w!]+)"') do
                        if not table.find(codes,code) then table.insert(codes,code) end
                    end end
                end
                for _, code in ipairs(codes) do
                    if not running() or not autoRedeem.Value then break end
                    if not redeemed[code] then
                        local success, result = pcall(Loader.Server,"Codes","Redeem",{Code=code})
                        if success then redeemed[code]=true if type(result)=="string" then notify(result) end end
                        task.wait(0.5)
                    end
                end
                redeemFinished = true
            end
            task.wait(1)
        end
    end)
    local Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
    local Config = Window:AddTab({Title = "Config", Icon = "save"})
    local themes = {"Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose"}
    local Theme = Settings:AddDropdown("Theme", {Title = "Theme", Values = themes, Default = "Dark", Multi = false})
    Theme:OnChanged(function() local value = choice(Theme) if value then Fluent:SetTheme(value) end end)
    Settings:AddButton({Title = "Unload", Callback = cleanup})
    local path = "NopeHub/UIOnly/" .. tostring(game.Players.LocalPlayer.UserId) .. ".json"
    local store = {Version = 1, Profiles = {}, AutoLoad = ""}
    if isfile and readfile then
        local ok, data = pcall(function() return isfile(path) and Http:JSONDecode(readfile(path)) end)
        if ok and type(data) == "table" and type(data.Profiles) == "table" then
            store = data
            for _, profile in pairs(store.Profiles) do
                if type(profile) == "table" and type(profile.Features) == "table" then profile.Features.AutoSpawn = nil end
            end
        end
    end
    local selected, dropdown
    local Name = Config:AddInput("ConfigName", {Title = "Config Name", Default = "", Finished = false})
    dropdown = Config:AddDropdown("SelectedConfig", {Title = "Select Config", Values = {}, Multi = false})
    dropdown:OnChanged(function() selected = choice(dropdown) end)
    local function refresh()
        local names = {}
        for name in pairs(store.Profiles) do table.insert(names, name) end
        table.sort(names)
        dropdown:SetValues(names)
        if selected and store.Profiles[selected] then setMulti(dropdown,selected) end
    end
    local function persist()
        assert(type(writefile) == "function", "Executor does not support saving files")
        writefile(path, Http:JSONEncode(store))
    end
    local function button(title, fn)
        Config:AddButton({Title = title, Callback = function()
            local ok, err = pcall(fn)
            if not ok then notify(err) end
        end})
    end
    local function save(name, create)
        assert(name and name ~= "" and #name <= 64, "Enter a config name (1-64 characters)")
        if create then assert(not store.Profiles[name], "Config already exists; use Overwrite Config")
        else assert(store.Profiles[name], "Select a config first") end
        local previous = store.Profiles[name]
        local extra = {} for id, control in pairs(features) do extra[id] = control.Value end
        store.Profiles[name] = {Theme = choice(Theme), AutoSkill = AutoSkill.Value, SelectedSkills = SelectedSkills.Value, Features = extra}
        local ok, err = pcall(persist)
        if not ok then store.Profiles[name] = previous error(err) end
        selected = name
        refresh()
        notify("Saved: " .. name)
    end
    local function load(name)
        assert(name and type(store.Profiles[name]) == "table", "Select a config first")
        local profile = store.Profiles[name]
        setMulti(SelectedSkills,profile.SelectedSkills)
        AutoSkill:SetValue(profile.AutoSkill == true)
        for id, value in pairs(profile.Features or {}) do if features[id] then setMulti(features[id],value) end end
        refreshFruitSlots()
        local value = profile.Theme
        if table.find(themes, value) then setMulti(Theme,value) end
        selected = name
        refresh()
    end
    local function setAutoLoad(value)
        local previous = store.AutoLoad
        store.AutoLoad = value
        local ok, err = pcall(persist)
        if not ok then store.AutoLoad = previous error(err) end
    end
    button("Refresh Configs", refresh)
    button("Create Config", function() save(tostring(Name.Value):match("^%s*(.-)%s*$"), true) end)
    button("Save Config", function() save(selected, false) end)
    button("Overwrite Config", function() save(selected, false) end)
    button("Load Config", function() load(selected) notify("Loaded: " .. selected) end)
    button("Set Auto Load", function()
        assert(selected and store.Profiles[selected], "Select a config first")
        setAutoLoad(selected)
        notify("Auto load: " .. selected)
    end)
    button("Disable Auto Load", function() setAutoLoad("") notify("Auto load disabled") end)
    refresh()
    if type(store.AutoLoad) == "string" and store.Profiles[store.AutoLoad] then
        local ok, err = pcall(load, store.AutoLoad)
        if not ok then notify(err) end
    end
    Window:SelectTab(1)
    task.spawn(function()
        while active and not Fluent.Unloaded and (not STATE or STATE.alive()) do
            task.wait(5)
            if not active then return end
        end
        cleanup()
    end)
end

repeat task.wait() until game:IsLoaded()
task.spawn(function()
    local ok, err = pcall(Boot)
    if not ok then
        local env = getgenv and getgenv() or _G
        if env.NOPE_HUB_UI_CLEANUP then pcall(env.NOPE_HUB_UI_CLEANUP) end
        warn("NopeHUB: " .. tostring(err))
    end
end)