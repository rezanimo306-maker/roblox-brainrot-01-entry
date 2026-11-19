-- Brainrot Bay: client bootstrap.
-- Builds the HUD, wires the server's StateSync and Announce events to it,
-- and binds the keys: L locks your base, F slaps the nearest thief.
-- ProximityPrompts (buy on the belt, steal on a base) are handled by the
-- server and need no client code: walk up and press E.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUD = require(script.Parent:WaitForChild("HUD"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Camera = require(script.Parent:WaitForChild("Camera"))

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

HUD.build()

local function onStateSync(state)
	HUD.updateState(state)
end
(Remotes:WaitForChild("StateSync") :: RemoteEvent).OnClientEvent:Connect(onStateSync)

local function onAnnounce(text, colorName, seconds)
	HUD.showBanner(text, colorName, seconds)
	if string.find(text, "TSUNAMI") then
		Effects.shake(0.6)
	end
end
(Remotes:WaitForChild("Announce") :: RemoteEvent).OnClientEvent:Connect(onAnnounce)

local function bindLock(_actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		(Remotes:WaitForChild("ToggleLock") :: RemoteEvent):FireServer()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("LockBase", bindLock, false, Enum.KeyCode.L)

local function bindSlap(_actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		(Remotes:WaitForChild("SlapPlayer") :: RemoteEvent):FireServer()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("SlapPlayer", bindSlap, false, Enum.KeyCode.F)

local function onCharacterAdded(_character)
	task.wait(0.5)
	Camera.intro()
end
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

print("Brainrot Bay client is live.")
