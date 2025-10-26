_G.AutoFarm = not _G.AutoFarm ; print("AutoFarm: ", _G.AutoFarm)
 
 
 
----------------------------------------------------------
---------------------- [ Variables ] ---------------------
----------------------------------------------------------
 
 
local Collection = {} ; Collection.__index = Collection
 
Collection.Cooldown = {
    equipBestPets = 0,
	autoUpRank = 0,
    antiAFK = 0,
    autoupgrade = 0,
}
 
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
 
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
 
local Events = ReplicatedStorage:WaitForChild("Events")
local Inventory = Events:WaitForChild("Inventory")
local To_Server = Events:WaitForChild("To_Server")
local rankUpCost = PlayerGui.Upgrades.Upgrade_Rank_Up.Progress.Main.TextLabel.Text
local myEnergy = PlayerGui.Main.Left_Side.Displays.Energy.Energy.Main.TextLabel.Text

 
----------------------------------------------------------
---------------------- [ Functions ] ---------------------
----------------------------------------------------------
 
 
function Collection:GetRoot(Character)
    return Character:FindFirstChild("HumanoidRootPart")
end
function Collection:GetHumanoid(Character)
    return Character:FindFirstChild("Humanoid")
end
function Collection:GetSelfDistance(Position)
    local RootPart = Collection:GetRoot(LocalPlayer.Character)
    return (RootPart.Position - Position).Magnitude
end
function Collection:TeleportCFrame(Position)
    local RootPart = Collection:GetRoot(LocalPlayer.Character)
    RootPart.CFrame = typeof(Position) == "CFrame" and Position or CFrame.new(Position)
end
function Collection:getNilInstance(Name, className)
    for _,v in pairs(getnilinstances()) do
        if v.Name == Name and v.ClassName == className then
            return v
        end
    end
 
    return nil
end
function Collection:getEntities(Entities)
    local distanceData = {}
    local entitiesData = {}
    local entities = {}
	
 
    local RootPart = Collection:GetRoot(LocalPlayer.Character)
 
    for _, Entity in pairs(workspace.Debris.Monsters:GetChildren()) do
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

function Collection:getAllTitles()
    local titles = {}
    for _, Entity in pairs(workspace.Debris.Monsters:GetChildren()) do
        local title = Entity:GetAttribute("Title")
        if title and not table.find(titles, title) then
            table.insert(titles, title)
        end
    end
    return titles
end



function Collection:attackEntity(entityID)
    To_Server:FireServer({
        Id = entityID,
        Action = "_Mouse_Click"
    })
end
function Collection:openStar(starName, Amount)
    To_Server:FireServer({
        Open_Amount = Amount,
        Action = "_Stars",
        Name = starName
    })
end

function Collection:OpenPower(Name,Amount)
To_Server:FireServer({
		Open_Amount = Amount,
		Action = "_Gacha_Activate",
		Name = Name
	})

end

function Collection:openSword(Name,Amount)
	game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("To_Server"):FireServer({
		Open_Amount = Amount,
		Action = "_Gacha_Activate",
		Name = Name
	})

end

function Collection:shadowEnhancher()
	game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("To_Server"):FireServer({
		Type = "Enchant",
		Action = "Enchantment",
		Desired = {
			["7"] = true,
			["8"] = true
		},
		Enchantment_Name = "Shadow_Enhancer",
		UniqueId = "5ad4-59fad26fa83f319656e16963f265"
	})
end
 

function Collection:autoUpRank()
	To_Server:FireServer({
		Upgrading_Name = "Rank",
		Action = "_Upgrades",
		Upgrade_Name = "Rank_Up"
	})

end

function Collection:antiAFK()
    local Humanoid = Collection:GetHumanoid(LocalPlayer.Character)
    
    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end


function Collection:autoUpgrade(UpgradeName)
    To_Server:FireServer({
		Upgrading_Name = UpgradeName,
		Action = "_Upgrades",
		Upgrade_Name = UpgradeName
	})

end



local replicatedClientModule = Collection:getNilInstance("ReplicatedClient", "ModuleScript")
local replicatedClient = require(replicatedClientModule)
 
function Collection:getMostEnergyPets()
    local energyList = {}
    local petsData = {}
 
    for i,v in pairs(replicatedClient.GetReplica().Data.Inventory.Items) do
        if typeof(v.Equipped) == "boolean" then
            local energy = v.Stats.Energy
 
            if energy then
                table.insert(energyList, energy)
 
                if petsData[tostring(energy)] == nil then
                    petsData[tostring(energy)] = {}
                end
 
                table.insert(petsData[tostring(energy)], i)
 
            end
        end
    end
 
    if #energyList <= 0 then return nil end
 
    return petsData[tostring(math.max(unpack(energyList)))]
end
 
 
----------------------------------------------------------
------------------------ [ Loops ] -----------------------
----------------------------------------------------------
 
 
 
while _G.AutoFarm do task.wait()
    local success, err = pcall(function()

        --#Auto Upgrades

        if tick() >= Collection.Cooldown["autoupgrade"] then
            Collection.Cooldown["autoupgrade"] = tick() + 5
            Collection:autoUpgrade(
                "Spiritual_Pressure"
            )
        end

        --$# Anti AFK

        if tick() >= Collection.Cooldown["antiAFK"] then
            Collection.Cooldown["antiAFK"] = tick() + 300
            print("Anti AFK")
            Collection:antiAFK()
        end

		--#Auto Up Rank
		if tick() >= Collection.Cooldown["autoUpRank"] then
            Collection.Cooldown["autoUpRank"] = tick() + 30
            Collection:autoUpRank()
        end
		--#Auto Shadow Enchancer
		-- Collection:shadowEnhancher()
        -- # Open Stars
        -- Collection:openStar("Star_6", 5)

		--# Open Power
		-- Collection:OpenPower("Dragon_Race",4)	

		--#Open Sword
		-- Collection:openSword("Swords",4)

        -- # Equip Best Pets
        -- if tick() >= Collection.Cooldown["equipBestPets"] then
        --     Collection.Cooldown["equipBestPets"] = tick() + 3
        --     local mostEnergyPets = Collection:getMostEnergyPets()
 
        --     Inventory:FireServer({
        --         Action = "Equip_Unequip",
        --         Selected = mostEnergyPets
        --     })
        -- end
 
        -- # Auto Farm
		local allTitles = Collection:getAllTitles()
		-- local closestEntity, allEntities = Collection:getEntities(allTitles)
		local targetEntities = Collection:getEntities({})
        local closestEntity, allEntities = Collection:getEntities({
			
			
			
			
			"Eizen",
			"Rakiu",
			"Hime",
			"Ichige"

			
		
			
			-- allTitles
			
			
			
			
            
		})
        
        if closestEntity then
            if Collection:GetSelfDistance(closestEntity["HumanoidRootPart"].Position) > 7 then
                Collection:TeleportCFrame(closestEntity["HumanoidRootPart"].CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.rad(180), 0))
            end
            Collection:attackEntity(tostring(closestEntity))
        end
    end)
    if err then
        warn("[CAUGHT ERROR]: ", err)
    end
end