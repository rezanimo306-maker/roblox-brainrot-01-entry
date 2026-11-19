-- Camera: a short establishing shot, then the default follow camera.
-- When the player spawns, the camera starts high above the bay, swoops down
-- behind the character over two seconds, and hands control back to Roblox's
-- own camera. If anything fails, the default camera just stays.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Camera = {}

local player = Players.LocalPlayer

function Camera.intro()
	local character = player.Character
	if character == nil then
		return
	end
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local ok = pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(Vector3.new(0, 90, 110), Vector3.new(0, 0, 0))
		local target = CFrame.new(root.Position + Vector3.new(0, 12, 22), root.Position)
		local tween = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target })
		tween:Play()
		tween.Completed:Wait()
		camera.CameraType = Enum.CameraType.Custom
	end)
	if not ok then
		camera.CameraType = Enum.CameraType.Custom
	end
end

return Camera
