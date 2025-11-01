-- UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()


--Variable
local Collection = {}; Collection.__index = Collection
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
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
local autoFarmRaidIsOn = false
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
local autoExitRaid = false
-------------------------------------------------------------------------------------------
-----------------------------------------Function------------------------------------------
-------------------------------------------------------------------------------------------

function Collection:DungeonTitle()
    local txt = Dungeon_Header.Main.Main.Title.Text
    return Dungeon_Header.Visible and txt:find("Dungeon") ~= nil
end

function Collection:RaidTitle()
    local txt = Dungeon_Header.Main.Main.Title.Text
    return Dungeon_Header.Visible and txt:find("Raid") ~= nil
end

function Collection:Graveyard_DefenseTitle()
    local txt = Dungeon_Header.Main.Main.Title.Text
    return Dungeon_Header.Visible and txt:find("Graveyard Defense") ~= nil
end

for _, Entity in pairs(workspace.Debris.Monsters:GetChildren()) do
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

function Collection:GetRoot(Character)
    return Character:FindFirstChild("HumanoidRootPart")
end

function Collection:GetSelfDistance(Position)
    local RootPart = Collection:GetRoot(LocalPlayer.Character)
    return (RootPart.Position - Position).Magnitude
end

function Collection:TeleportCFrame(Position)
    local RootPart = Collection:GetRoot(LocalPlayer.Character)
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


    local RootPart = Collection:GetRoot(LocalPlayer.Character)

    for _, Entity in pairs(Monsters:GetChildren()) do
        local title = Entity:GetAttribute("Title")
        if table.find(Entities, Entity:GetAttribute("Title")) then
            local distance = math.floor((Entity["HumanoidRootPart"].Position - RootPart.Position).Magnitude)

            table.insert(entities, Entity)
            table.insert(distanceData, distance)
            entitiesData[tostring(distance)] = Entity
        end
    end

    if #distanceData <= 0 then return nil, nil end

    return entitiesData[tostring(math.min(unpack(distanceData)))], entities
end

function Collection:getSkillPoints()
    local txt = PlayerGui.PlayerHUD.Player_Hub.Primary_Stats.Stats.Frame.Skill_Points.Text
    local digits = string.match(txt or "", "%d+")
    return tonumber(digits) or 0
end

function Collection:autoUpRank()
    To_Server:FireServer({
        Upgrading_Name = "Rank",
        Action = "_Upgrades",
        Upgrade_Name = "Rank_Up"
    })
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
            local allTitles = Collection:getAllEntities()
            local closestEntity, allEntities = Collection:getEntities(allTitles)
            if closestEntity and Collection:DungeonTitle() then
                if Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) > 7 and Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) < 500 then
                    Collection:TeleportCFrame(closestEntity["HumanoidRootPart"].CFrame * CFrame.new(0, 0, -5) *
                        CFrame.Angles(0, math.rad(180), 0))
                end
                Collection:attackEntity(tostring(closestEntity))
            end
            task.wait()
        end
    end)
end

function Collection:autoFarmRaid()
    autoFarmRaidIsOn = true
    task.spawn(function()
        while autoFarmRaidIsOn do
            local allTitles = Collection:getAllEntities()
            local closestEntity, allEntities = Collection:getEntities(allTitles)
            if closestEntity and Dungeon_Header.Visible and (Collection:RaidTitle() or Collection:Graveyard_DefenseTitle()) then
                if Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) > 7 and Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) < 500 then
                    Collection:TeleportCFrame(closestEntity["HumanoidRootPart"].CFrame * CFrame.new(0, 0, -5) *
                        CFrame.Angles(0, math.rad(180), 0))
                end
                Collection:attackEntity(tostring(closestEntity))
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
            if (Collection:RaidTitle() or Collection:Graveyard_DefenseTitle()) and currentWave and tonumber(currentWave) >= tonumber(selectedWave) then
                To_Server:FireServer({
                    Action = "Dungeon_Leave"
                })
            end
            task.wait(.5)
        end
    end)
end

function Collection:updateEntitiesName()
    local newEntitiesName = {}
    local newSeen = {}

    for _, Entity in pairs(workspace.Debris.Monsters:GetChildren()) do
        local title = Entity:GetAttribute("Title")
        if title and not newSeen[title] then
            table.insert(newEntitiesName, title)
            newSeen[title] = true
        end
    end

    return newEntitiesName
end

function Collection:selectAutoFarm()
    if not autofarm then
        return
    end
    if autofarm then
        task.spawn(function()
            while autofarm do
                -- if #selectedList > 0 then
                local closest = Collection:getEntities(selectedList)
                if closest then
                    if Collection:GetSelfDistance(closest.HumanoidRootPart.Position) > 7 and Collection:GetSelfDistance(closest.HumanoidRootPart.Position) < 3000 then
                        Collection:TeleportCFrame(
                            closest.HumanoidRootPart.CFrame
                            * CFrame.new(0, 0, -5)
                            * CFrame.Angles(0, math.rad(180), 0)
                        )
                    end
                    Collection:attackEntity(tostring(closest))
                end
                -- end
                task.wait()
            end
        end)
    end
end

local function stopSelectEntities(reason)
    if autofarm then
        autofarm = false
        print("[SelectEntities] stopped:", reason or "unknown")
    end
end



------------------------------------------------------------------------------------------------
-----------------------------------------Config Table-------------------------------------------
------------------------------------------------------------------------------------------------

local DUNGEON_CONFIG = {
    { name = "Dungeon_Easy",      minuteStart = 0,  minuteEnd = 2 },
    { name = "Dungeon_Medium",    minuteStart = 10, minuteEnd = 12 },
    { name = "Dungeon_Hard",      minuteStart = 20, minuteEnd = 22 },
    { name = "Dungeon_Insane",    minuteStart = 30, minuteEnd = 32 },
    { name = "Dungeon_Crazy",     minuteStart = 40, minuteEnd = 42 },
    { name = "Dungeon_Nightmare", minuteStart = 50, minuteEnd = 52 }
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
--------------------------------------------------------------------------------------------
-----------------------------------------UI Setup-------------------------------------------
--------------------------------------------------------------------------------------------
ScreenGui.Parent = CoreGui
ScreenGui.Name = "FleXiZ"
ImageButton.Size = UDim2.fromOffset(128, 128)
ImageButton.Position = UDim2.new(0.5, -ImageButton.Size.X.Offset / 2, 0, 10)
ImageButton.BackgroundTransparency = 1
ImageButton.Image = "rbxassetid://136992027589423"
ImageButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.Parent = ScreenGui

local Window = Fluent:CreateWindow({
    Title = "FleXiZ " .. Fluent.Version,
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
    Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "shield" }),
    Raid = Window:AddTab({ Title = "Raid", Icon = "flame" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "align-end-horizontal" }),
    Reward = Window:AddTab({ Title = "Reward", Icon = "trophy" }),
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

local Toggle = Tabs.General:AddToggle("MyToggle", { Title = "Auto Rank Up", Default = false })
Toggle:OnChanged(function(Toggle)
    autoRankUp = Toggle
    task.spawn(function()
        while autoRankUp do
            print("Auto Up Rank")
            Collection:autoUpRank()
            task.wait(30)
        end
    end)
end)



local MultiDropdown = Tabs.General:AddDropdown("MultiDropdown", {
    Title = "Select Entities",
    Values = entitiesName,
    Multi = true,
    Default = { "" },
    Description = "This Function will attack selected entities automatically"
})





MultiDropdown:OnChanged(function(select)
    selectedList = {}
    for i, v in pairs(select) do
        if v then
            table.insert(selectedList, i)
        end
    end
    autofarm = true
    Collection:selectAutoFarm()
end)
task.spawn(function()
    while task.wait(2) do
        local oldCount = #entitiesName
        entitiesName = Collection:updateEntitiesName()

        if oldCount ~= #entitiesName then
            MultiDropdown:SetValues(entitiesName)
            print("Auto-refreshed entities: " .. #entitiesName .. " monsters")
        end
    end
end)


-----------------------------------------------------------------------------------------------
-----------------------------------------Champions Tab-----------------------------------------
-----------------------------------------------------------------------------------------------

local selectedStarList = {}
local selectedAmount = 5
local randomStar = false


local function openStars(starName, amount)
    To_Server:FireServer({
        Open_Amount = amount,
        Action = "_Stars",
        Name = starName
    })
end

local function RandomChampions()
    randomStar = true
    task.spawn(function()
        while randomStar do
            local currentAmount = selectedAmount
            for _, star in ipairs(selectedStarList) do
                openStars(star, currentAmount)
            end
            task.wait()
        end
    end)
end


local MultiDropdown = Tabs.Champions:AddDropdown("MultiDropdown", {
    Title = "Select Stars",
    Values = StarName,
    Multi = true,
    Default = {},
    Description = "This function will open selected star champions automatically"
})
MultiDropdown:OnChanged(function(selection)
    selectedStarList = {}

    for starName, isSelected in pairs(selection) do
        if isSelected then
            table.insert(selectedStarList, starName)
        end
    end
    RandomChampions()
end)
local Slider = Tabs.Champions:AddSlider("Slider", {
    Title = "Amount",
    Description = "Number of stars to open at once",
    Default = 1,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        selectedAmount = Value
    end
})


---------------------------------------------------------------------------------------------
-----------------------------------------Dungeon Tab-----------------------------------------
---------------------------------------------------------------------------------------------


local function getDungeonNames()
    local names = {}
    for _, config in ipairs(DUNGEON_CONFIG) do
        table.insert(names, config.name)
    end
    return names
end

local function joinDungeon(dungeonName)
    To_Server:FireServer({
        Action = "_Enter_Dungeon",
        Name = dungeonName
    })
end

local function enterDungeon(dungeonName)
    Dungeon_Notification.Visible = false
    joinDungeon(dungeonName)
    inDungeon = true
    stopSelectEntities("entering dungeon: " .. dungeonName)
    autoFarmDungeonIsOn = true
end

local function exitDungeon()
    inDungeon = false
    autofarm = true
    autoFarmDungeonIsOn = false
    Collection:selectAutoFarm()
end

local function shouldJoinDungeon(minute, dungeonName)
    for _, config in ipairs(DUNGEON_CONFIG) do
        if config.name == dungeonName and
            minute >= config.minuteStart and
            minute <= config.minuteEnd then
            return true
        end
    end
    return false
end



local function checkAndJoinDungeons()
    if not Dungeon_Notification.Visible then
        if inDungeon and not Dungeon_Header.Visible then
            exitDungeon()
        end
        return
    end


    local currentMinute = tonumber(os.date("%M"))

    for _, dungeonName in ipairs(dungeonList) do
        if shouldJoinDungeon(currentMinute, dungeonName) then
            if not inRaid and not Dungeon_Header.Visible then
                enterDungeon(dungeonName)
                break
            end
        end
    end
end

local function startAutoDungeon()
    if autoDungeon then return end
    autoDungeon = true
    task.spawn(function()
        while autoDungeon do
            checkAndJoinDungeons()
            task.wait(.5)
        end
    end)
end


local MultiDropdown = Tabs.Dungeon:AddDropdown("MultiDropdown", {
    Title = "Select Dungeons",
    Values = getDungeonNames(),
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

    startAutoDungeon()
end)

local Toggle = Tabs.Dungeon:AddToggle("Auto Farm Dungeon", { Title = "Auto Farm Dungeon", Default = false })

Toggle:OnChanged(function(Toggle)
    autoFarmDungeonIsOn = Toggle
    if autoFarmDungeonIsOn then
        Collection:autoFarmDungeon()
    end
end)

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


local function getRaidNames()
    local names = {}
    for _, config in ipairs(Raid_Config) do
        table.insert(names, config.name)
    end
    return names
end

local joinRaid = function(raidName)
    To_Server:FireServer({
        Action = "_Enter_Dungeon",
        Name = raidName
    })
end

local enterRaid = function(raidName)
    joinRaid(raidName)
    inRaid = true
    stopSelectEntities("entering raid: " .. raidName)
    task.wait(0.5)
    autoFarmRaidIsOn = true
end
local exitRaid = function()
    inRaid = false
    autofarm = true
    autoFarmRaidIsOn = false
    Collection:selectAutoFarm()
end
local shouldJoinRaid = function(minute, raidName)
    for _, config in ipairs(Raid_Config) do
        if config.name == raidName and
            minute >= config.minuteStart and
            minute <= config.minuteEnd then
            return true
        end
    end
    return false
end
local checkAndJoinRaids = function()
    if inRaid and not Dungeon_Header.Visible then
        exitRaid()
    end
    local currentMinute = tonumber(os.date("%M"))

    for _, raidName in ipairs(RaidList) do
        if shouldJoinRaid(currentMinute, raidName) then
            if not inDungeon and not Dungeon_Header.Visible then
                enterRaid(raidName)
                break
            end
        end
    end
end
local startAutoRaid = function()
    if autoRaid then return end

    autoRaid = true
    task.spawn(function()
        while autoRaid do
            checkAndJoinRaids()
            task.wait(.5)
        end
    end)
end
local MultiDropdown = Tabs.Raid:AddDropdown("MultiDropdown", {
    Title = "Select Raids",
    Values = getRaidNames(),
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

    startAutoRaid()
end)

local Toggle = Tabs.Raid:AddToggle("Auto Farm Raid", { Title = "Auto Farm Raid", Default = false })

Toggle:OnChanged(function(Toggle)
    autoFarmRaidIsOn = Toggle
    if autoFarmRaidIsOn then
        Collection:autoFarmRaid()
    end
end)

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
    Title = "Select Entities",
    Values = statName,
    Multi = true,
    Default = { "" },
    Description = "This Function will attack selected entities automatically"
})

local selectedStatList = {}
local upgradeStats = false
MultiDropdown:OnChanged(function(selectStat)
    selectedStatList = {}
    for i, v in pairs(selectStat) do
        if v then
            table.insert(selectedStatList, i)
        end
    end


    if not upgradeStats then
        upgradeStats = true
        task.spawn(function()
            while upgradeStats do
                local skillPoints = Collection:getSkillPoints()
                if skillPoints >= 1 then
                    for _, stat in pairs(selectedStatList) do
                        To_Server:FireServer({
                            Name = stat,
                            Action = "Assign_Level_Stats",
                            Amount = 1
                        })
                        print("Upgraded Stat: " .. stat)
                        task.wait(0.1)
                    end
                end
                task.wait()
            end
        end)
    end
end)

-------------------------------------------------------------------------------------------
-----------------------------------------Reward Tab-----------------------------------------
-------------------------------------------------------------------------------------------
function Collection:ChestToggle(key, title, chestName)
    local openChest = false

    local ToggleObj = Tabs.Reward:AddToggle(key, { Title = title, Default = false })

    ToggleObj:OnChanged(function(state)
        openChest = state
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
    end)
end

Collection:ChestToggle("DailyChestToggle", "Claim Daily Chest", "Daily")
Collection:ChestToggle("GroupChestToggle", "Claim Group Chest", "Group")
Collection:ChestToggle("VipChestToggle", "Claim VIP Chest", "Vip")
Collection:ChestToggle("PremiumChestToggle", "Claim Premium Chest", "Premium")
