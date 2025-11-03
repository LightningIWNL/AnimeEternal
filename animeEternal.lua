-- UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()


-------------------------------------------------------------------------------------------
-----------------------------------------Variable------------------------------------------
-------------------------------------------------------------------------------------------
local Collection = {}; Collection.__index = Collection
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local dragging = false
local startPos
local startMousePos
local Events = ReplicatedStorage:WaitForChild("Events")
local Inventory = Events:WaitForChild("Inventory")
local To_Server = Events:WaitForChild("To_Server")
local selectedList = {}
local selectedStarList = {}
local autofarm = false
local autoRankUp = false
local randomStar = false
local Dungeon_Notification = PlayerGui.Dungeon.Dungeon_Notification
local Dungeon_Header = PlayerGui.Dungeon.Default_Header
local autoFarmDungeonIsOn = false
local autoJoinDungeonBTN = false
local autoFarmRaidIsOn = false
local autoJoinRaidBTN = false
local Monsters = workspace:WaitForChild("Debris"):WaitForChild("Monsters")
local entitiesName, seen = {}, {}
local dungeonList = {}
local autoDungeon = false
local inDungeon = false
local RaidList = {}
local autoRaid = false
local inRaid = false
local selectedWave = 1000
local selectedRoom = 50
local ExitAtWaveRaid = false
local ExitAtRoomDungeon = false
local autoExitDungeon = false
local joinDungeon = false
local autoExitRaid = false
local upgradeStats = false
local selectedAmountStats = 1
local selectedStatList = {}
local refreshEntities = false
local openChest = false
local UIR = PlayerGui.Inventory_1.Hub.Equip_All_Top.Main.UI_Ring
local selectedEquipBest = nil
local autoEquipBestBTN = false
local equipBestAllInterval = 30
local disableRender = false
local blackScreen = false
local selectedGacha = nil
local selectedAmountGacha = 1
local autoGacha = false

-------------------------------------------------------------------------------------------
-----------------------------------------Function------------------------------------------
-------------------------------------------------------------------------------------------

function Collection:pressButton(btn)
    if GuiService.SelectedObject ~= nil then
        GuiService.SelectedObject = nil
    end
    if not btn then
        return
    end

    local VisibleUI = PlayerGui:FindFirstChild("_") or Instance.new("Frame")
    VisibleUI.Name = "_"
    VisibleUI.BackgroundTransparency = 1
    VisibleUI.Parent = PlayerGui


    GuiService.SelectedObject = VisibleUI
    GuiService.SelectedObject = btn

    if GuiService.SelectedObject == btn then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(.05)
    end

    task.wait(0.05)
    GuiService.SelectedObject = nil

    if VisibleUI and VisibleUI.Parent then
        VisibleUI:Destroy()
    end
end

function Collection:DungeonTitle()
    local txt = Dungeon_Header.Main.Main.Title.Text
    return Dungeon_Header.Visible and txt:find("Dungeon") ~= nil
end

function Collection:RaidTitle()
    local txt = Dungeon_Header.Main.Main.Title.Text
    return Dungeon_Header.Visible and txt:find("Raid") ~= nil
end

function Collection:DefenseTitle()
    local txt = Dungeon_Header.Main.Main.Title.Text
    return Dungeon_Header.Visible and txt:find("Defense") ~= nil
end

for _, Entity in pairs(Monsters:GetChildren()) do
    local title = Entity:GetAttribute("Title")
    if title and not seen[title] then
        table.insert(entitiesName, title)
        seen[title] = true
    end
end


function Collection:AutoClaimChest()
    To_Server:FireServer({
        Action = "_Chest_Claim",
        Name = "Group"
    })
end

function Collection:ChestToggle(chestName)
    if openChest then
        task.spawn(function()
            pcall(function()
                To_Server:FireServer({
                    Action = "_Chest_Claim",
                    Name = chestName
                })
            end)
        end)
    end
end

function Collection:GetRoot(Character)
    if not Character then return nil end
    return Character:FindFirstChild("HumanoidRootPart")
end

function Collection:GetSelfDistance(Position)
    if not LocalPlayer.Character then return math.huge end

    local RootPart = Collection:GetRoot(LocalPlayer.Character)
    if not RootPart then return math.huge end

    return (RootPart.Position - Position).Magnitude
end

function Collection:TeleportCFrame(Position)
    if not LocalPlayer.Character then return end

    local RootPart = Collection:GetRoot(LocalPlayer.Character)
    if not RootPart then return end

    RootPart.CFrame = typeof(Position) == "CFrame" and Position or CFrame.new(Position)
end

function Collection:attackEntity(entityID)
    To_Server:FireServer({
        Id = entityID,
        Action = "_Mouse_Click"
    })
end

function Collection:getEntities(Entities)
    local distanceData = {}
    local entitiesData = {}
    local entities = {}

    if not LocalPlayer.Character then
        return nil, nil
    end
    local RootPart = Collection:GetRoot(LocalPlayer.Character)
    if not RootPart then
        return nil, nil
    end
    for _, Entity in pairs(Monsters:GetChildren()) do
        local entityRoot = Entity:FindFirstChild("HumanoidRootPart")
        local title = Entity:GetAttribute("Title")

        if title and entityRoot and table.find(Entities, title) then
            local distance = math.floor((entityRoot.Position - RootPart.Position).Magnitude)
            table.insert(entities, Entity)
            table.insert(distanceData, distance)
            entitiesData[tostring(distance)] = Entity
        end
    end

    if #distanceData <= 0 then
        return nil, nil
    end
    return entitiesData[tostring(math.min(unpack(distanceData)))], entities
end

function Collection:getSkillPoints()
    local txt = PlayerGui.PlayerHUD.Player_Hub.Primary_Stats.Stats.Frame.Skill_Points.Text
    local digits = string.match(txt or "", "%d+")
    return tonumber(digits) or 0
end

function Collection:autoUpRank()
    task.spawn(function()
        while autoRankUp do
            if autoRankUp then
                To_Server:FireServer({
                    Upgrading_Name = "Rank",
                    Action = "_Upgrades",
                    Upgrade_Name = "Rank_Up"
                })
            end
            task.spawn(30)
        end
    end)
end

function Collection:getAllEntities()
    local EntitiesName = {}
    for _, Entity in pairs(Monsters:GetChildren()) do
        local title = Entity:GetAttribute("Title")
        if title and not table.find(EntitiesName, title) then
            table.insert(EntitiesName, title)
        end
    end
    return EntitiesName
end

function Collection:autoFarmDungeon()
    autoFarmDungeonIsOn = true
    task.spawn(function()
        while autoFarmDungeonIsOn do
            if LocalPlayer.Character and Collection:DungeonTitle() then
                local allTitles = Collection:getAllEntities()
                local closestEntity, allEntities = Collection:getEntities(allTitles)
                if closestEntity and closestEntity:FindFirstChild("HumanoidRootPart") then
                    if Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) > 7 and Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) < 500 then
                        Collection:TeleportCFrame(closestEntity["HumanoidRootPart"].CFrame * CFrame.new(0, 0, -5) *
                            CFrame.Angles(0, math.rad(180), 0))
                    end
                    Collection:attackEntity(tostring(closestEntity))
                end
                task.wait()
            end
            task.wait()
        end
    end)
end

function Collection:autoFarmRaid()
    autoFarmRaidIsOn = true
    task.spawn(function()
        while autoFarmRaidIsOn do
            if LocalPlayer.Character and Dungeon_Header.Visible and (Collection:RaidTitle() or Collection:DefenseTitle()) then
                local allTitles = Collection:getAllEntities()
                local closestEntity, allEntities = Collection:getEntities(allTitles)
                if closestEntity and closestEntity:FindFirstChild("HumanoidRootPart") then
                    if Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) > 7 and Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) < 500 then
                        Collection:TeleportCFrame(closestEntity["HumanoidRootPart"].CFrame * CFrame.new(0, 0, -5) *
                            CFrame.Angles(0, math.rad(180), 0))
                    end
                    Collection:attackEntity(tostring(closestEntity))
                end
            end
            task.wait()
        end
    end)
end

function Collection:GetExitAtRoom()
    ExitAtRoomDungeon = true
    task.spawn(function()
        while ExitAtRoomDungeon do
            local DungeonWave = Dungeon_Header.Main.Main.Room.Text
            local currentWave = DungeonWave:match("%d+")
            if Collection:DungeonTitle() and currentWave and tonumber(currentWave) >= tonumber(selectedRoom) then
                To_Server:FireServer({
                    Action = "Dungeon_Leave"
                })
            end
            task.wait(.5)
        end
    end)
end

function Collection:GetExitAtWaveRaid()
    ExitAtWaveRaid = true
    task.spawn(function()
        while ExitAtWaveRaid do
            local DungeonWave = Dungeon_Header.Main.Main.Wave.Text
            local currentWave = DungeonWave:match("%d+")
            if (Collection:RaidTitle() or Collection:DefenseTitle()) and currentWave and tonumber(currentWave) >= tonumber(selectedWave) then
                To_Server:FireServer({
                    Action = "Dungeon_Leave"
                })
            end
            task.wait(.5)
        end
    end)
end

function Collection:selectAutoFarm()
    if not autofarm then
        return
    end

    task.spawn(function()
        while autofarm do
            if LocalPlayer.Character and #selectedList > 0 then
                local closest = Collection:getEntities(selectedList)

                if closest and closest:FindFirstChild("HumanoidRootPart") then
                    local distance = Collection:GetSelfDistance(closest.HumanoidRootPart.Position)

                    if distance > 7 and distance < 3000 then
                        Collection:TeleportCFrame(
                            closest.HumanoidRootPart.CFrame
                            * CFrame.new(0, 0, -5)
                            * CFrame.Angles(0, math.rad(180), 0)
                        )
                    end

                    Collection:attackEntity(tostring(closest))
                end
            end
            task.wait()
        end
    end)
end

function Collection:upgrade_Stats()
    task.spawn(function()
        while upgradeStats do
            local skillPoints = Collection:getSkillPoints()
            if skillPoints > 0 then
                for _, stat in pairs(selectedStatList) do
                    To_Server:FireServer({
                        Name = stat,
                        Action = "Assign_Level_Stats",
                        Amount = tonumber(selectedAmountStats),
                    })
                    task.wait(.5)
                end
            end
            task.wait(.5)
        end
    end)
end

function Collection:RenderDisable(toggle)
    if toggle then
        RunService:Set3dRenderingEnabled(false)
    else
        RunService:Set3dRenderingEnabled(true)
    end
end

function Collection:ScreenBlack(toggle)
    task.spawn(function()
        if toggle then
            local oldGui = PlayerGui:FindFirstChild("BlackScreen")
            if oldGui then oldGui:Destroy() end

            local gui = Instance.new("ScreenGui")
            gui.Name = "BlackScreen"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.DisplayOrder = 999999
            gui.Parent = PlayerGui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Parent = gui
        else
            local gui = PlayerGui:FindFirstChild("BlackScreen")
            if gui then
                gui:Destroy()
            end
        end
    end)
end

function Collection:updateEntitiesName()
    local newEntitiesName = {}
    local newSeen = {}

    for _, Entity in pairs(Monsters:GetChildren()) do
        local title = Entity:GetAttribute("Title")
        if title and not newSeen[title] then
            table.insert(newEntitiesName, title)
            newSeen[title] = true
        end
    end

    return newEntitiesName
end

function Collection:compareEntitiesTables(oldTable, newTable)
    if #oldTable ~= #newTable then
        return false
    end

    local oldSet = {}
    for _, name in pairs(oldTable) do
        oldSet[name] = true
    end

    for _, name in pairs(newTable) do
        if not oldSet[name] then
            return false
        end
    end

    return true
end

------------------------------------------------------------------------------------------------
-----------------------------------------Config Table-------------------------------------------
------------------------------------------------------------------------------------------------
local Handle_Config = {
    isAutoFarmRunning = false,
    isAutoFarmDungeonRunning = false,
    isAutoFarmRaidRunning = false,
    isEquipBestRunning = false,
    isRankUpRunning = false,
    isAntiAFKRunning = false,
    isOpenStarRunning = false,
    isGachaRunning = false,
    isAutoJoinDungeonRunning = false,
    isAutoJoinRaidRunning = false,
    isAutoUpgradeStatsRunning = false,
    isAutoUpgradeStatsRunning = false,


}

local DUNGEON_CONFIG = {
    { name = "Dungeon_Easy",      minuteStart = 0,  minuteEnd = 2 },
    { name = "Dungeon_Medium",    minuteStart = 10, minuteEnd = 12 },
    { name = "Dungeon_Hard",      minuteStart = 20, minuteEnd = 22 },
    { name = "Dungeon_Insane",    minuteStart = 30, minuteEnd = 32 },
    { name = "Dungeon_Crazy",     minuteStart = 40, minuteEnd = 42 },
    { name = "Dungeon_Nightmare", minuteStart = 50, minuteEnd = 52 },
    { name = "Dungeon_Suffering", minuteStart = 0,  minuteEnd = 60 },
    { name = "Kaiju_Dungeon",     minuteStart = 0,  minuteEnd = 60 },

}

local Raid_Config = {
    { name = "Cursed_Raid",              minuteStart = 0,  minuteEnd = 60 },
    { name = "Dragon_Room_Raid",         minuteStart = 0,  minuteEnd = 60 },
    { name = "Ghoul_Raid",               minuteStart = 0,  minuteEnd = 60 },
    { name = "Gleam_Raid",               minuteStart = 0,  minuteEnd = 60 },
    { name = "Green_Planet_Raid",        minuteStart = 0,  minuteEnd = 60 },
    { name = "Halloween_Raid",           minuteStart = 0,  minuteEnd = 60 },
    { name = "Hollow_Raid",              minuteStart = 0,  minuteEnd = 60 },
    { name = "Leaf_Raid",                minuteStart = 15, minuteEnd = 17 },
    { name = "Mundo_Raid",               minuteStart = 0,  minuteEnd = 60 },
    { name = "Progression_Raid",         minuteStart = 0,  minuteEnd = 60 },
    { name = "Progression_Raid_2",       minuteStart = 0,  minuteEnd = 60 },
    { name = "Restaurant_Raid",          minuteStart = 0,  minuteEnd = 60 },
    { name = "Sin_Raid",                 minuteStart = 0,  minuteEnd = 60 },
    { name = "Tomb_Arena_Raid",          minuteStart = 0,  minuteEnd = 60 },
    { name = "Total_Running_Track_Raid", minuteStart = 0,  minuteEnd = 60 },
    { name = "Tournament_Raid",          minuteStart = 0,  minuteEnd = 60 },
    { name = "Graveyard_Defense",        minuteStart = 0,  minuteEnd = 60 },
    { name = "Chainsaw_Defense",         minuteStart = 0,  minuteEnd = 60 },

}

local statName = {
    "Primary_Damage",
    "Primary_Energy",
    "Primary_Coins",
    "Primary_Luck",
}

local StarName = {
    "Star_1", "Star_2", "Star_3", "Star_4", "Star_5", "Star_6", "Star_7", "Star_8", "Star_9", "Star_10", "Star_11",
    "Star_12", "Star_13", "Star_14", "Star_15", "Star_16", "Star_17", "Star_18", "Star_19", "Star_20", "Star_21",
    "Star_22", "Star_23", "Star_24", "Star_25",
}

local GachaName = {
    "Dragon_Race", "Saiyan_Evolution", "Swords", "Pirate_Crew", "Reiatsu_Color", "Zanpakuto", "Curses", "Demon_Arts",
    "Solo_Hunter_Rank", "Grimoire", "Power_Eyes",
    "Psychic_Mayhem", "Damage_Card_Shop", "Energy_Card_Shop", "Families", "Titans", "Sins", "Commandments",
    "Kaiju_Powers", "Species", "Ultimate_Skills",
    "Power_Energy_Runes", "Onomatopoeia", "Stands", "Investigators", "Kagune", "Debiru_Hunter", "Akuma_Powers",
    "Mushi_Bite", "Special_Fire_Force",
    "Grand_Elder_Power", "Frost_Demon_Evolution"
}
--------------------------------------------------------------------------------------------
-----------------------------------------UI Setup-------------------------------------------
--------------------------------------------------------------------------------------------
ScreenGui.Parent = CoreGui
ScreenGui.Name = "FleXiZ"
ImageButton.Size = UDim2.fromOffset(128, 128)
ImageButton.Position = UDim2.new(0.5, -ImageButton.Size.X.Offset / 2, 0, 10)
ImageButton.BackgroundTransparency = 1
ImageButton.Image = "rbxassetid://123198069831010"
ImageButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.Parent = ScreenGui

local Window = Fluent:CreateWindow({
    Title = "Anime Eternal",
    SubTitle = "by FleXiZ",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Aqua",
    MinimizeKey = Enum.KeyCode.LeftControl
})

ImageButton.MouseButton1Click:Connect(function()
    if Window.Minimize then
        Window.Minimize(false)
    end
end)

ImageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startPos = ImageButton.Position
        startMousePos = input.Position
    end
end)


ImageButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - startMousePos
        ImageButton.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local Tabs = {
    General = Window:AddTab({ Title = "General", Icon = "monitor" }),
    Champions = Window:AddTab({ Title = "Champions", Icon = "user" }),
    Gacha = Window:AddTab({ Title = "Gacha", Icon = "dices" }),
    Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "shield" }),
    Raid = Window:AddTab({ Title = "Raid", Icon = "flame" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "align-end-horizontal" }),
    Reward = Window:AddTab({ Title = "Reward", Icon = "trophy" }),
    Performance = Window:AddTab({ Title = "Performance", Icon = "chevrons-up" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

task.spawn(function()
    while task.wait(.5) do
        if Fluent.Unloaded then
            if ImageButton and ImageButton.Parent then
                ImageButton:Destroy()
            end
            break
        end
    end
end)

---------------------------------------------------------------------------------------------
-----------------------------------------General Tab-----------------------------------------
---------------------------------------------------------------------------------------------

Tabs.General:AddSection("Auto Farm")

local MultiDropdown = Tabs.General:AddDropdown("MultiDropdown", {
    Title = "Select Entities",
    Values = entitiesName,
    Multi = true,
    Default = {},
    Description = "This Function will attack selected entities automatically"
})

MultiDropdown:OnChanged(function(select)
    selectedList = {}
    for i, v in pairs(select) do
        if v then
            table.insert(selectedList, i)
        end
    end
end)

task.spawn(function()
    while task.wait(5) do
        local newEntitiesName = Collection:updateEntitiesName()

        -- เปรียบเทียบว่ารายชื่อเปลี่ยนแปลงหรือไม่
        if not Collection:compareEntitiesTables(entitiesName, newEntitiesName) then
            entitiesName = newEntitiesName
            MultiDropdown:SetValues(entitiesName)

            print("Auto-refreshed entities: " .. #entitiesName .. " monsters")
            print("Updated list:", table.concat(entitiesName, ", "))
        end
    end
end)

local Toggle = Tabs.General:AddToggle("Auto Farm", { Title = "Auto Farm", Default = false })
Toggle:OnChanged(function(Toggle)
    autofarm = Toggle
    if autofarm then
        Collection:selectAutoFarm()
    end
end)
Tabs.General:AddSection("Auto Equip Best All")
function Collection:GetEquipBestName()
    local equipBestName = {}
    for _, v in next, UIR:GetChildren() do
        if v.ClassName == "ImageButton" then
            table.insert(equipBestName, v.Name)
        end
    end
    return equipBestName
end

function Collection:AutoEqiupBestAll()
    task.spawn(function()
        while autoEquipBestBTN do
            if selectedEquipBest then
                local button = UIR:FindFirstChild(selectedEquipBest)
                if button and button:IsA("ImageButton") then
                    Collection:pressButton(button)
                end
            end
            task.wait(tonumber(equipBestAllInterval))
            GuiService.SelectedObject = nil
        end
    end)
end

local Dropdown = Tabs.General:AddDropdown("MultiDropdown", {
    Title = "Select Equip Best By",
    Values = Collection:GetEquipBestName(),
    Multi = false,
    Default = nil,
    Description = "This Function will equip best champions, power, weapon and other by selected automatically"
})

Dropdown:OnChanged(function(select)
    selectedEquipBest = select
end)
local Slider = Tabs.General:AddSlider("Slider", {
    Title = "Interval",
    Description = "Equip Best All Interval",
    Default = 30,
    Min = 1,
    Max = 500,
    Rounding = 1,
    Callback = function(Value)
        equipBestAllInterval = Value
    end
})
local Toggle = Tabs.General:AddToggle("Auto Equip All", { Title = "Auto Equip Best All", Default = false })
Toggle:OnChanged(function(Toggle)
    autoEquipBestBTN = Toggle
    if autoEquipBestBTN then
        Collection:AutoEqiupBestAll()
    end
end)


Tabs.General:AddSection("Auto Rank Up")

local Toggle = Tabs.General:AddToggle("MyToggle", { Title = "Auto Rank Up", Default = false })
Toggle:OnChanged(function(Toggle)
    autoRankUp = Toggle
    Collection:autoUpRank()
end)

Tabs.General:AddSection("Anti AFK")

local AntiAFK = false
local Toggle = Tabs.General:AddToggle("MyToggle", { Title = "Anti AFK", Default = false })
Toggle:OnChanged(function(Toggle)
    AntiAFK = Toggle
    task.spawn(function()
        while AntiAFK do
            print("Anti AFK")
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            task.wait(60 * 14)
        end
    end)
end)

-----------------------------------------------------------------------------------------------
-----------------------------------------Champions Tab-----------------------------------------
-----------------------------------------------------------------------------------------------

local selectedStarList = nil
local selectedAmount = 5
local autoOpenStar = false


function Collection:openStars()
    task.spawn(function()
        while autoOpenStar do
            if selectedStarList then
                To_Server:FireServer({
                    Open_Amount = tonumber(selectedAmount),
                    Action = "_Stars",
                    Name = selectedStarList
                })
            end
            task.wait(.5)
        end
    end)
end

local Dropdown = Tabs.Champions:AddDropdown("MultiDropdown", {
    Title = "Select Stars",
    Values = StarName,
    Multi = false,
    Default = nil,
    Description = "This function will open selected star champions automatically"
})
Dropdown:OnChanged(function(selection)
    selectedStarList = selection
end)
local Slider = Tabs.Champions:AddSlider("Slider", {
    Title = "Amount",
    Description = "Number of stars to open at once",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        selectedAmount = Value
    end
})


local Toggle = Tabs.Champions:AddToggle("Open Star", { Title = "Auto Open Star", Default = false })

Toggle:OnChanged(function(Toggle)
    autoOpenStar = Toggle
    if autoOpenStar then
        Collection:openStars()
    end
end)
---------------------------------------------------------------------------------------------
-----------------------------------------Gacha Tab------------------------------------------
---------------------------------------------------------------------------------------------

function Collection:OpenGacha()
    if not autoGacha then
        return
    end
    task.spawn(function()
        while autoGacha do
            if selectedGacha then
                To_Server:FireServer({
                    Open_Amount = tonumber(selectedAmountGacha),
                    Action = "_Gacha_Activate",
                    Name = selectedGacha
                })
            end
            task.wait(.5)
        end
    end)
end

local Dropdown = Tabs.Gacha:AddDropdown("Dropdown", {
    Title = "Dropdown",
    Values = GachaName,
    Multi = false,
    Default = nil,
})
Dropdown:OnChanged(function(select)
    selectedGacha = select
end)
local Slider = Tabs.Gacha:AddSlider("Slider", {
    Title = "Amount",
    Description = "Number of gacha to open at once",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        selectedAmountGacha = Value
    end
})

local Toggle = Tabs.Gacha:AddToggle("Auto Gacha", { Title = "Auto Gacha", Default = false })
Toggle:OnChanged(function(Toggle)
    autoGacha = Toggle
    if autoGacha then
        Collection:OpenGacha()
    end
end)
---------------------------------------------------------------------------------------------
-----------------------------------------Dungeon Tab-----------------------------------------
---------------------------------------------------------------------------------------------


function Collection:getDungeonNames()
    local names = {}
    for _, config in ipairs(DUNGEON_CONFIG) do
        table.insert(names, config.name)
    end
    return names
end

function Collection:joinDungeon(dungeonName)
    task.spawn(function()
        To_Server:FireServer({
            Action = "_Enter_Dungeon",
            Name = dungeonName
        })
    end)
end

function Collection:JoinedDungeon()
    joinDungeon = true
    task.wait(120)
    joinDungeon = false
end

function Collection:enterDungeon(dungeonName)
    Dungeon_Notification.Visible = false
    Collection:joinDungeon(dungeonName)
    inDungeon = true
end

function Collection:enterSpecialDungeon(dungeonName)
    Collection:joinDungeon(dungeonName)
    inDungeon = true
end

function Collection:exitDungeon()
    inDungeon = false
end

function Collection:shouldJoinDungeon(minute, dungeonName)
    for _, config in ipairs(DUNGEON_CONFIG) do
        if config.name == dungeonName and
            minute >= config.minuteStart and
            minute <= config.minuteEnd then
            return true
        end
    end
    return false
end

function Collection:checkAndJoinDungeons()
    if not autoJoinDungeonBTN then
        return
    end

    if inDungeon and not Dungeon_Header.Visible then
        Collection:exitDungeon()
        return
    end

    local currentMinute = tonumber(os.date("%M"))
    for _, dungeonName in ipairs(dungeonList) do
        if Collection:shouldJoinDungeon(currentMinute, dungeonName) and Dungeon_Notification.Visible and not joinDungeon then
            if not inRaid and not Dungeon_Header.Visible then
                Collection:enterDungeon(dungeonName)
                Collection:JoinedDungeon()
                return
            end
        end
    end
    for _, dungeonName in ipairs(dungeonList) do
        local specialDungeon = (dungeonName == "Dungeon_Suffering" or dungeonName == "Kaiju_Dungeon")
        if specialDungeon and not inRaid and not Dungeon_Header.Visible then
            Collection:enterSpecialDungeon(dungeonName)
            break
        end
    end
end

function Collection:startAutoDungeon()
    if autoDungeon then return end
    autoDungeon = true
    task.spawn(function()
        while autoDungeon and autoJoinDungeonBTN do
            Collection:checkAndJoinDungeons()
            task.wait(.5)
        end
        autoDungeon = false
    end)
end

local MultiDropdown = Tabs.Dungeon:AddDropdown("MultiDropdown", {
    Title = "Select Dungeons",
    Values = Collection:getDungeonNames(),
    Multi = true,
    Default = {},
    Description = "This function will join selected dungeons automatically"
})

MultiDropdown:OnChanged(function(selection)
    dungeonList = {}
    for dungeonName, isSelected in pairs(selection) do
        if isSelected then
            table.insert(dungeonList, dungeonName)
        end
    end
end)
local Toggle = Tabs.Dungeon:AddToggle("Auto Join Dungeon", { Title = "Auto Join Dungeon", Default = false })

Toggle:OnChanged(function(Toggle)
    autoJoinDungeonBTN = Toggle
    if autoJoinDungeonBTN then
        Collection:startAutoDungeon()
    end
end)
local Toggle = Tabs.Dungeon:AddToggle("Auto Farm Dungeon", { Title = "Auto Farm Dungeon", Default = false })
Toggle:OnChanged(function(Toggle)
    autoFarmDungeonIsOn = Toggle
    if autoFarmDungeonIsOn then
        Collection:autoFarmDungeon()
    end
end)
Tabs.Dungeon:AddSection("Auto Exit Dungeon")
local Slider = Tabs.Dungeon:AddSlider("Select Dungeon Room", {
    Title = "Select Auto Exit Room",
    Description = "Auto leave at selected room",
    Default = 50,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        selectedRoom = Value
    end
})

local Toggle = Tabs.Dungeon:AddToggle("Select Dungeon Room Exit", { Title = "Auto Exit Dungeon", Default = false })

Toggle:OnChanged(function(Toggle)
    autoExitDungeon = Toggle
    if autoExitDungeon then
        Collection:GetExitAtRoom()
    end
end)
--------------------------------------------------------------------------------------------
-----------------------------------------Raid Tab-------------------------------------------
--------------------------------------------------------------------------------------------


function Collection:getRaidNames()
    local names = {}
    for _, config in ipairs(Raid_Config) do
        table.insert(names, config.name)
    end
    return names
end

function Collection:joinRaid(raidName)
    task.spawn(function()
        To_Server:FireServer({
            Action = "_Enter_Dungeon",
            Name = raidName
        })
        task.wait(.5)
    end)
end

function Collection:enterRaid(raidName)
    Collection:joinRaid(raidName)
    inRaid = true
    task.wait(.5)
end

local exitRaid = function()
    inRaid = false
end
function Collection:shouldJoinRaid(minute, raidName)
    for _, config in ipairs(Raid_Config) do
        if config.name == raidName and
            minute >= config.minuteStart and
            minute <= config.minuteEnd then
            return true
        end
    end
    return false
end

function Collection:checkAndJoinRaids()
    if not autoJoinRaidBTN then
        return
    end
    if inRaid and not Dungeon_Header.Visible then
        exitRaid()
        return
    end
    if inDungeon then
        return
    end
    local currentMinute = tonumber(os.date("%M"))

    for _, raidName in ipairs(RaidList) do
        if Collection:shouldJoinRaid(currentMinute, raidName) then
            if not Dungeon_Header.Visible then
                Collection:enterRaid(raidName)
                break
            end
        end
    end
end

local startAutoRaid = function()
    if autoRaid then return end

    autoRaid = true
    task.spawn(function()
        while autoRaid and autoJoinRaidBTN do
            Collection:checkAndJoinRaids()
            task.wait(.5)
        end
        autoRaid = false
    end)
end
local MultiDropdown = Tabs.Raid:AddDropdown("MultiDropdown", {
    Title = "Select Raids",
    Values = Collection:getRaidNames(),
    Multi = true,
    Default = {},
    Description = "This function will join selected raid automatically"
})
MultiDropdown:OnChanged(function(selection)
    RaidList = {}
    for raidName, isSelected in pairs(selection) do
        if isSelected then
            table.insert(RaidList, raidName)
        end
    end
end)

local Toggle = Tabs.Raid:AddToggle("Auto Join Raid", { Title = "Auto Join Raid", Default = false })

Toggle:OnChanged(function(Toggle)
    autoJoinRaidBTN = Toggle
    if autoJoinRaidBTN then
        startAutoRaid()
    end
end)

local Toggle = Tabs.Raid:AddToggle("Auto Farm Raid", { Title = "Auto Farm Raid", Default = false })

Toggle:OnChanged(function(Toggle)
    autoFarmRaidIsOn = Toggle
    if autoFarmRaidIsOn then
        Collection:autoFarmRaid()
    end
end)

Tabs.Raid:AddSection("Auto Exit Raid")

local Slider = Tabs.Raid:AddSlider("Slider", {
    Title = "Select Auto Exit Wave",
    Description = "Auto leave at selected wave",
    Default = 1000,
    Min = 1,
    Max = 1000,
    Rounding = 1,
    Callback = function(Value)
        selectedWave = Value
    end
})



local Toggle = Tabs.Raid:AddToggle("Select Raid Room Exit", { Title = "Auto Exit Raid", Default = false })

Toggle:OnChanged(function(Toggle)
    autoExitRaid = Toggle
    if autoExitRaid then
        Collection:GetExitAtWaveRaid()
    end
end)
-------------------------------------------------------------------------------------------
-----------------------------------------Stats Tab-----------------------------------------
-------------------------------------------------------------------------------------------

local MultiDropdown = Tabs.Stats:AddDropdown("MultiDropdown", {
    Title = "Select Stats",
    Values = statName,
    Multi = true,
    Default = {},
    Description = "This function will upgrade selected stats automatically"
})


MultiDropdown:OnChanged(function(selectStat)
    selectedStatList = {}
    for i, v in pairs(selectStat) do
        if v then
            table.insert(selectedStatList, i)
        end
    end
end)

local Toggle = Tabs.Stats:AddToggle("Select Stats", { Title = "Auto Upgrade Stats", Default = false })

Toggle:OnChanged(function(Toggle)
    upgradeStats = Toggle
    if upgradeStats then
        Collection:upgrade_Stats()
    end
end)

local Slider = Tabs.Stats:AddSlider("Slider", {
    Title = "Upgrade Amount",
    Description = "Select upgrade amount",
    Default = 10,
    Min = 1,
    Max = 3000,
    Rounding = 1,
    Callback = function(Value)
        selectedAmountStats = Value
    end
})
-------------------------------------------------------------------------------------------
-----------------------------------------Reward Tab-----------------------------------------
-------------------------------------------------------------------------------------------
local Toggle = Tabs.Reward:AddToggle("Daily Chest", { Title = "Open Daily Chest", Default = false })

Toggle:OnChanged(function(Toggle)
    openChest = Toggle
    if openChest then
        Collection:ChestToggle("Daily")
    end
end)
local Toggle = Tabs.Reward:AddToggle("Group Chest", { Title = "Open Group Chest", Default = false })

Toggle:OnChanged(function(Toggle)
    openChest = Toggle
    if openChest then
        Collection:ChestToggle("Group")
    end
end)
local Toggle = Tabs.Reward:AddToggle("VIP Chest", { Title = "Open VIP Chest", Default = false })

Toggle:OnChanged(function(Toggle)
    openChest = Toggle
    if openChest then
        Collection:ChestToggle("Vip")
    end
end)
local Toggle = Tabs.Reward:AddToggle("Premium Chest", { Title = "Open Premium Chest", Default = false })

Toggle:OnChanged(function(Toggle)
    openChest = Toggle
    if openChest then
        Collection:ChestToggle("Premium")
    end
end)
---------------------------------------------------------------------------------------------
-----------------------------------------Performance-----------------------------------------
---------------------------------------------------------------------------------------------
local Toggle = Tabs.Performance:AddToggle("Disable Render",
    {
        Title = "Disable Render",
        Default = false,
        Description =
        "This function will disable 3D rendering to help improve your performance"
    })

Toggle:OnChanged(function(Toggle)
    disableRender = Toggle
    if disableRender then
        Collection:RenderDisable(true)
    else
        Collection:RenderDisable(false)
    end
end)
local Toggle = Tabs.Performance:AddToggle("Black Screen",
    { Title = "Black Screen", Default = false, Description = "This function will black screen to save your battery" })

Toggle:OnChanged(function(Toggle)
    blackScreen = Toggle
    if blackScreen then
        Collection:ScreenBlack(true)
    else
        Collection:ScreenBlack(false)
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FleXiZHub_Interface")
SaveManager:SetFolder("FleXiZHub/Anime_Eternal")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
