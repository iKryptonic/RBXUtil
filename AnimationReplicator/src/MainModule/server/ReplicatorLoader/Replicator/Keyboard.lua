-- @Name: Keyboard
-- @Author: iKrypto

--[[
	
	local keyboard = require(this)
	
	METHODS:
		
		(IsDown)
		
		Boolean isDown:  keyboard:IsDown(KeyCode key)
		
	
	EVENTS:
	
		(KeyDown, KeyUp)
		
		keyboard.KeyDown(KeyCode key)
		keyboard.KeyUp(KeyCode key)
	
--]]


assert(game:GetService("RunService"):IsClient(), "Keyboard can only be used from client")


local Keyboard = {}

local userInput = game:GetService("UserInputService")

local isDown = {}

local keyboardInput = Enum.UserInputType.Keyboard

local onKeyDown  = Instance.new("BindableEvent")
local onKeyUp    = Instance.new("BindableEvent")

Keyboard.KeyDown  = onKeyDown.Event
Keyboard.KeyUp    = onKeyUp.Event


function Keyboard:IsDown(keyCode)
	return (isDown[keyCode] == true)
end
Keyboard.isDown = Keyboard.IsDown


local function InputBegan(input, processed)
	if (processed) then return end
	if (input.UserInputType == keyboardInput) then
		local key = input.KeyCode
		isDown[key] = true
		onKeyDown:Fire(key)
	end
end

local function InputEnded(input, processed)
	if (processed) then return end
	if (input.UserInputType == keyboardInput) then
		local key = input.KeyCode
		isDown[key] = false
		onKeyUp:Fire(key)
	end
end


userInput.InputBegan:Connect(InputBegan)
userInput.InputEnded:Connect(InputEnded)


return Keyboard