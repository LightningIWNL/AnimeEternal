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
local autoExitRaid = false
local upgradeStats = false
local selectedAmountStats = 1
local selectedStatList = {}
local refreshEntities = false
local UIR = PlayerGui.Inventory_1.Hub.Equip_All_Top.Main.UI_Ring
local selectedEquipBest = {}
local autoEquipBest = false
local autoEquipBestBTN = false

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

    -- ลบ Frame ชั่วคราวออก
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
        -- local title = Entity:GetAttribute("Title")
        local entityRoot = Entity:FindFirstChild("HumanoidRootPart")
        if table.find(Entities, Entity:GetAttribute("Title")) and entityRoot then
            -- local distance = math.floor((Entity["HumanoidRootPart"].Position - RootPart.Position).Magnitude)
            local distance = math.floor((entityRoot.Position - RootPart.Position).Magnitude)
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
            if closestEntity and Dungeon_Header.Visible and (Collection:RaidTitle() or Collection:DefenseTitle()) then
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
    if autofarm then
        task.spawn(function()
            while autofarm do
                if #selectedList > 0 then
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
                end
                task.wait()
            end
        end)
    end
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

Tabs.General:AddSection("Auto Farm")

local SelectEntityMultiDropdown = Tabs.General:AddDropdown("MultiDropdown", {
    Title = "Select Entities",
    Values = entitiesName,
    Multi = true,
    Default = {},
    Description = "This Function will attack selected entities automatically"
})

SelectEntityMultiDropdown:OnChanged(function(select)
    selectedList = {}
    for i, v in pairs(select) do
        if v then
            table.insert(selectedList, i)
        end
    end
    -- autofarm = true
    -- Collection:selectAutoFarm()
end)

local function refreshDropdown()
    if refreshEntities then return end
    refreshEntities = true

    task.spawn(function()
        task.wait(2.5)


        local entitiesName = Collection:getAllEntities()
        SelectEntityMultiDropdown:SetValues(entitiesName)

        refreshEntities = false
    end)
end
refreshDropdown()
Monsters.ChildAdded:Connect(refreshDropdown)
Monsters.ChildRemoved:Connect(refreshDropdown)

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

function Collection:GetEquipBestBTN(btnName)
    local equipBestBTN = {}
    for _, v in next, UIR:GetChildren() do
        if v.ClassName == "ImageButton" then
            table.insert(equipBestBTN, v)
        end
    end
    return equipBestBTN
end

function Collection:AutoEqiupBest()
    autoEquipBest = true
    task.spawn(function()
        while autoEquipBest do
            if #selectedEquipBest > 0 then
                for _, btnName in pairs(selectedEquipBest) do
                    local button = UIR:FindFirstChild(btnName)
                    if autoEquipBestBTN and button and button:IsA("ImageButton") then
                        Collection:pressButton(button)
                    end
                end
            end
            task.wait(5)
            GuiService.SelectedObject = nil
        end
    end)
end

local SelectEntityMultiDropdown = Tabs.General:AddDropdown("MultiDropdown", {
    Title = "Select Equip Best",
    Values = Collection:GetEquipBestName(),
    Multi = true,
    Default = {},
    Description = "This Function will equip best all selected automatically"
})

SelectEntityMultiDropdown:OnChanged(function(select)
    selectedEquipBest = {}
    for i, v in pairs(select) do
        if v then
            table.insert(selectedEquipBest, i)
        end
    end
end)

local Toggle = Tabs.General:AddToggle("Auto Equip All", { Title = "Auto Equip Best All", Default = false })
Toggle:OnChanged(function(Toggle)
    autoEquipBestBTN = Toggle
    if autoEquipBestBTN then
        Collection:AutoEqiupBest()
        task.wait(.5)
        autofarm = true
        Collection:selectAutoFarm()
    end
end)


Tabs.General:AddSection("Auto Rank Up")

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
            for _, star in ipairs(selectedStarList) do
                openStars(star, tonumber(selectedAmount))
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
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        selectedAmount = Value
    end
})


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

function Collection:enterDungeon(dungeonName)
    Dungeon_Notification.Visible = false
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
    if not Dungeon_Notification.Visible and not autoJoinDungeonBTN then
        if inDungeon and not Dungeon_Header.Visible then
            Collection:exitDungeon()
        end
        return
    end


    local currentMinute = tonumber(os.date("%M"))

    for _, dungeonName in ipairs(dungeonList) do
        if Collection:shouldJoinDungeon(currentMinute, dungeonName) then
            if not inRaid and not Dungeon_Header.Visible then
                Collection:enterDungeon(dungeonName)
                break
            end
        end
    end
end

function Collection:startAutoDungeon()
    if autoDungeon then return end
    autoDungeon = true
    task.spawn(function()
        while autoDungeon do
            Collection:checkAndJoinDungeons()
            task.wait(.5)
        end
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
    -- joinRaidIsOn =true
    task.spawn(function()
        To_Server:FireServer({
            Action = "_Enter_Dungeon",
            Name = raidName
        })
        task.wait(.5)
    end)
end

local enterRaid = function(raidName)
    Collection:joinRaid(raidName)
    inRaid = true
    task.wait(.5)
end
local exitRaid = function()
    inRaid = false
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
    if not autoJoinRaidBTN then
        if inRaid and not Dungeon_Header.Visible then
            exitRaid()
        end
        return
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
