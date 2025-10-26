local args = {
	{
		Action = "_Enter_Dungeon",
		Name = "Dungeon_Hard"
	}
}
game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("To_Server"):FireServer(unpack(args))
