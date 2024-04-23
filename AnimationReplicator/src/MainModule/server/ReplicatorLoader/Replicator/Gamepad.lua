-- @Name: Gamepad
-- @Author: iKrypto

-- NOTE: Specifically listens for Gamepad1 controls only!!!

--[[
	
	FIELDS:
	
		Gamepad.IsConnected           > true|false
	
	
	METHODS:
	
		Gamepad:IsDown(keyCode)       > true|false
		Gamepad:GetInput(keyCode)     > returns InputObject associated with keycode (nil if none)
		Gamepad:GetPosition(keyCode)  > Vector3 (will return 0,0,0 if no keycode available)
	
	
	EVENTS:
	
		Gamepad.ButtonDown(keyCode)
		Gamepad.ButtonUp(keyCode)
		Gamepad.Changed(keyCode)
		Gamepad.Connected()
		Gamepad.Disconnected()
	
--]]


local GAMEPAD1 = Enum.UserInputType.Gamepad1
local ZERO_VECTOR = Vector3.new()

local buttonDown = Instance.new("BindableEvent")
local buttonUp = Instance.new("BindableEvent")
local changed = Instance.new("BindableEvent")
local connected = Instance.new("BindableEvent")
local disconnected = Instance.new("BindableEvent")

local down = {}
local state = {}



local Gamepad = {
	IsConnected = game:GetService("UserInputService"):GetGamepadConnected(GAMEPAD1);
	ButtonDown = buttonDown.Event;
	ButtonUp = buttonUp.Event;
	Changed = changed.Event;
	Connected = connected.Event;
	Disconnected = disconnected.Event;
}

function Gamepad:IsDown(keyCode)
	return (down[keyCode] == true)
end

function Gamepad:GetInput(keyCode)
	return state[keyCode]
end

function Gamepad:GetPosition(keyCode)
	local input = self:GetInput(keyCode)
	if (input) then
		return input.Position
	end
	return ZERO_VECTOR
end



function Reset()
	down = {}
	state = {}
end


function GetState()
	-- Map KeyCodes to corresponding InputObjects on the gamepad:
	local s = game:GetService("UserInputService"):GetGamepadState(GAMEPAD1)
	for _,inputObj in pairs(s) do
		state[inputObj.KeyCode] = inputObj
	end
end


function InputBegan(input, processed)
	if (input.UserInputType == GAMEPAD1) then
		down[input.KeyCode] = true
		buttonDown:Fire(input.KeyCode)
	end
end


function InputEnded(input, processed)
	if (input.UserInputType == GAMEPAD1) then
		down[input.KeyCode] = false
		buttonUp:Fire(input.KeyCode)
	end
end


function InputChanged(input, processed)
	if (input.UserInputType == GAMEPAD1) then
		changed:Fire(input.KeyCode)
	end
end


function GamepadConnected(gamepad)
	if (gamepad == GAMEPAD1) then
		Gamepad.IsConnected = true
		GetState()
		connected:Fire()
	end
end


function GamepadDisconnected(gamepad)
	if (gamepad == GAMEPAD1) then
		Gamepad.IsConnected = false
		Reset()
		disconnected:Fire()
	end
end


game:GetService("UserInputService").InputBegan:Connect(InputBegan)
game:GetService("UserInputService").InputEnded:Connect(InputEnded)
game:GetService("UserInputService").InputChanged:Connect(InputChanged)
game:GetService("UserInputService").GamepadConnected:Connect(GamepadConnected)
game:GetService("UserInputService").GamepadDisconnected:Connect(GamepadDisconnected)


if (Gamepad.IsConnected) then
	GetState()
end


return Gamepad