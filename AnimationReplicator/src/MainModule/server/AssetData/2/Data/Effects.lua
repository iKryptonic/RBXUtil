-- @Author: iKrypto
-- Services
local Services 	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;})

-- Determining Input Types
local IS_CONSOLE= Services.GuiService:IsTenFootInterface()
local IS_MOBILE = Services.UserInputService.TouchEnabled and not Services.UserInputService.MouseEnabled and not IS_CONSOLE

-- Common Services
local Players			= Services.Players;
local UIS				= Services.UserInputService;
local Lighting			= Services.Lighting;
local ReplicatedStorage	= Services.ReplicatedStorage;

-- Shortcuts
local V3 		= Vector3.new
local CF 		= CFrame.new
local CFA		= CFrame.Angles
local MR 		= math.rad
local MRand		= math.random
local Ins 		= Instance.new
local sin		= math.sin
local cos		= math.cos
local tr		= table.remove
local ti		= table.insert
local mh		= math.huge
local bigVector	= V3(mh, mh, mh)

return (function(EffectName)

	local Effects = {};

	local function AddEffect(EffectName, Fn)
		Effects[EffectName] = coroutine.wrap(Fn);
	end
	
	-- Returns
	--[[AddEffect("DFA",function(Player, Character, Network, Replicator, Util)
		Util.PlayKeyframe(function(f)
			if f < 10 then
				print('1')
				Util.PlayAnimationFrame("DaggerR-1",0.1)
			elseif f < 20 then
				
				Util.PlayAnimationFrame("DaggerR-2",0.1)
			elseif f < 30 then
				Util.PlayAnimationFrame("DaggerR-3",0.1)
			elseif f < 40 then
				Util.PlayAnimationFrame("DaggerR-4",0.1)
			elseif f < 50 then
				Util.PlayAnimationFrame("DaggerR-5",0.1)
			elseif f < 60 then
				Util.PlayAnimationFrame("DaggerR-6",0.1)
			elseif f < 70 then
				Util.PlayAnimationFrame("DaggerR-7",0.1)
			elseif f < 80 then
				Util.PlayAnimationFrame("DaggerR-8",0.1)
			elseif f < 90 then
				Util.PlayAnimationFrame("DaggerR-9",0.1)
			end
		end,100)
	end)]]--
	AddEffect("Leap",function(Player, Character, Network, Replicator, Util)
		Util.makeImpulse("Up",(35))
		
	end)
	AddEffect("EmpoweredLunge",function(Player, Character, Network, Replicator, Util)
		Util.PlaySound(Character.HumanoidRootPart, "558640653", 0.05, 2)
		Util.makeImpulse("Forward",(76))
		for i = 1,3 do
		
			Replicator:FireEvent("Effect","Break","Bright yellow",{Character.Torso.Position},.2,.2,.2)
			end
	end)
	AddEffect("Thrust",function(Player, Character, Network, Replicator, Util)
		Util.makeImpulse("Forward", (40))
		
	end)
	
	AddEffect("EmpowerCharacter", function(Player, Character, Network, Replicator, Util)
		
		local BodyParts = {};
		
		for _, v in pairs(Character:GetChildren()) do
			if v:IsA("Part") then
				ti(BodyParts, v)
			end
		end
		
		local Bounding = {}
		for _, v in pairs(BodyParts) do
			local temp = {X=nil, Y=nil, Z=nil}
			temp.X = v.Size.X/2 * 10
			temp.Y = v.Size.Y/2 * 10
			temp.Z = v.Size.Z/2 * 10
			Bounding[v.Name] = temp
		end
		
		local function emitLightning()
			local Body1 = BodyParts[MRand(#BodyParts)]
			local Body2 = BodyParts[MRand(#BodyParts)]
			local Pos1 = V3(
				MRand(-Bounding[Body1.Name].X, Bounding[Body1.Name].X)/10,
				MRand(-Bounding[Body1.Name].Y, Bounding[Body1.Name].Y)/10,
				MRand(-Bounding[Body1.Name].Z, Bounding[Body1.Name].Z)/10
			)
			local Pos2 = V3(
				MRand(-Bounding[Body2.Name].X, Bounding[Body2.Name].X)/10,
				MRand(-Bounding[Body2.Name].Y, Bounding[Body2.Name].Y)/10,
				MRand(-Bounding[Body2.Name].Z, Bounding[Body2.Name].Z)/10
			)
			local SPos1 = Body1.Position + Pos1
			local SPos2 = Body2.Position + Pos2

			Replicator:FireEvent("Effect", "Lightning", SPos1, SPos2, 4, 2, 'New Yeller', 0.15, 0.4, 0.05)
		end

		for i = 1,25 do
			if (MRand() > .9) then
				emitLightning()
			end
			Services.RunService.RenderStepped:wait();
		end
	end)
	
	
	return Effects[EffectName]
end)