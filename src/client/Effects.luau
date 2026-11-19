-- Effects: the juice. Floating money text, confetti bursts and screen
-- shake, all client-side so they never cost the server a thing.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Effects = {}

-- A "+$12" that floats up from a brainrot and fades away.
function Effects.floatMoney(position: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Name = "FloatAnchor"
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Position = position
	anchor.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatMoney"
	billboard.Size = UDim2.new(0, 120, 0, 36)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.Parent = billboard

	local tween = TweenService:Create(billboard, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
	})
	tween:Play()
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

-- A burst of little coloured squares for a purchase or a rebirth.
function Effects.confetti(position: Vector3)
	local colors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(255, 205, 40),
		Color3.fromRGB(80, 220, 100),
		Color3.fromRGB(90, 150, 255),
		Color3.fromRGB(200, 90, 255),
	}
	for _ = 1, 14 do
		local bit = Instance.new("Part")
		bit.Name = "Confetti"
		bit.Size = Vector3.new(0.4, 0.4, 0.4)
		bit.Color = colors[math.random(1, #colors)]
		bit.Material = Enum.Material.Neon
		bit.Anchored = false
		bit.CanCollide = false
		bit.Position = position + Vector3.new(math.random(-2, 2), math.random(0, 2), math.random(-2, 2))
		bit.Parent = Workspace
		bit.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), math.random(8, 18), math.random(-12, 12))
		task.delay(1.4, function()
			bit:Destroy()
		end)
	end
end

-- A short jolt of the camera for the wave hitting you.
function Effects.shake(intensity: number)
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local start = os.clock()
	task.spawn(function()
		while os.clock() - start < 0.4 do
			local offset = Vector3.new(
				math.random(-100, 100) / 100 * intensity,
				math.random(-100, 100) / 100 * intensity,
				0
			)
			camera.CFrame *= CFrame.new(offset)
			task.wait(0.05)
		end
	end)
end

return Effects
