-- @Name: Player
-- @Author: iKrypto

--[[
	-- @TODO:
		-- Create RenderStowedItems() for rendering already stored items
]]

-- Service Provider
local Services	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;}); -- Setting up service provider

-- We need network here!
local Network = require(script.Parent:FindFirstChild("Network"))

-- Services
local ReplicatedStorage = Services.ReplicatedStorage;

local Player = {};


local function new(Player)
	
	local API = {};
	
	local Connections = {};
	
	local PlayerData = {
		Inventory 	= {"1", "2", "3", "4", "5", "6", "7"};
		Player 		= Player;
		UserId 		= Player.userId;
		Equipped 	= {};
		ActionBar 	= {};
		WeaponEqp	= '2';
		Class		= "Beginner";
	}
	
	local function Kill()
		for _, connection in ipairs(Connections) do -- Disconnect all our connections
			connection:disconnect()
			Connections[connection] = nil;
		end
		-- Save players data
		-- Anti-Combat logging?
	end
	
	local function CheckStowContainer()
		if Player then
			if Player.Character then
				local Cont = Player.Character:FindFirstChild('StowContainer')
				if (not Cont) then
					local Cont = Instance.new("Model")
					Cont.Name = 'StowContainer'
					Cont.Parent = Player.Character
				end
				return Cont
			end
		end
	end
	
	local function EquipObject(ItemId, Hand)
		local Equipped = PlayerData.Equipped[Hand]
		if Equipped then
			if Equipped == 1 then
				if (API.UnEquipObject(Hand)==false) then
					error("Failed to unequip item")
					return false
				else
					return false
				end
			end
		end
		PlayerData.Equipped[Hand] = 1
		
		local StowContainer = CheckStowContainer()
		
		if StowContainer then
			local StowedItem = StowContainer:FindFirstChild(ItemId);
			if StowedItem then
				StowedItem:Destroy();
			end
		end
		
		local Item = ReplicatedStorage:WaitForChild("Assets"):FindFirstChild(ItemId, true);
		
		if Item then
			if table.find(PlayerData.Inventory, ItemId) then
				Item = Item:Clone(); -- Clone Item so we don't overwrite it.
				
				local Data = require(Item.Data);
				
				local Handle = Item:FindFirstChild('Handle') -- If this isn't here, I blame you
				
				if Handle then
					local HandleWeld = Instance.new("Weld")
					HandleWeld.Part0 = Hand
					HandleWeld.Part1 = Handle
					HandleWeld.Name = 'HandleWeld'
					HandleWeld.C1 = Data.GripC1
					wait()
					HandleWeld.Parent = Handle
					Item.Parent = Hand
					Network:FireAllClients('ChangeEquip', Player, 'Equip', Hand, Item, HandleWeld);
					return true
				else
					error(("Weapon [%s] did not have a handle!"):format(ItemId), 0)
					return false
				end
				
			end
		end
		return false
	end
	
	local function UnEquipObject(Hand, Drop)
		local Weld = Hand:FindFirstChild("HandleWeld", true);
		
		if Drop then
			local WasRemoved = API.RemoveFromInventory(Weld.Parent.Parent.Name)
			if WasRemoved then
				pcall(function() Weld.Parent:FindFirstChild("Stowed"):Destroy() end) -- Do not stow.
				return UnEquipObject(Hand)
			else
				warn("[UnEquipObject]: Request fail.")
				return false
			end
		elseif Weld then
			PlayerData.Equipped[Hand] = 0
			local Handle = Weld.Parent;
			local Stow = Handle:FindFirstChild("Stowed")
			local Item = Handle.Parent;
			local Data = require(Item.Data);
			local StowContainer = CheckStowContainer();
			
			Network:FireAllClients('ChangeEquip', Player, 'UnEquip', Hand);
			
			if (Data.Stowable) then
				local WeldParent = Item.Parent.Parent:FindFirstChild(Data.StowPartName)
				if WeldParent then
					Weld.Part0 = WeldParent;
					Weld.C0 = CFrame.new();
					Weld.C1 = Data.StowC1;
					if StowContainer then
						Item.Parent = StowContainer;
					end
				end
			else
				for _, Object in ipairs(Item:GetDescendants()) do
					if Object:IsA('BasePart') then
						Object.CanCollide = true;
					end
					Services.Debris:AddItem(Object, 6)
				end
				Weld:Destroy();
				Item.Parent = workspace
			end
			return true
		end
		return false
	end
	
	local function AddToInventory(ItemId, BypassCheck)
		local Item = ReplicatedStorage:FindFirstChild(ItemId, true)
		
		if Item or BypassCheck then
			table.add(PlayerData.Inventory, ItemId)
		end
	end
	
	local function RemoveFromInventory(ItemId)
		local ItemCheck = table.find(PlayerData.Inventory, ItemId)
		if ItemCheck then
			
			local StowContainer = CheckStowContainer()
			
			if StowContainer then
				local StowedItem = StowContainer:FindFirstChild(ItemId);
				if StowedItem then
					StowedItem:Destroy();
				end
			end
			
			-- The reason I'm using table.remove is because I want the table to automatically shift the items accordingly.
			table.remove(PlayerData.Inventory, ItemCheck)
			return true
		end
		-- Implement a UI update here
	return false
	end
	
	local function Save()
		-- Save module here
	end
	
	-- Set Function Aliases
	API.EquipObject 		= EquipObject;
	API.UnEquipObject		= UnEquipObject
	API.AddToInventory 		= AddToInventory;
	API.RemoveFromInventory = RemoveFromInventory;
	API.Destroy				= Kill;
	API.destroy				= Kill;
	API.Remove				= Kill;
	API.remove				= Kill;
	API.Kill				= Kill;
	API.kill				= Kill;
	API.PlayerData			= PlayerData;
	API.Data				= PlayerData;
	API.data				= PlayerData;
	API.Name				= Player.Name;
	API.name				= Player.Name;
	API.Player				= Player;
	API.player				= Player;
	API.Save				= Save;

	return API
end


Player.new = new;
return Player