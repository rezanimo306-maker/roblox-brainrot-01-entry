-- HUD: the whole ScreenGui for Brainrot Bay.
-- Top bar with cash and income, the wave timer, the action buttons on the
-- right, the leaderboard on the left, the base card at the bottom and the
-- banner in the middle. All text stays clear of the top-left corner, where
-- Roblox puts its own menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local HUD = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local cashLabel: TextLabel
local incomeLabel: TextLabel
local rebirthLabel: TextLabel
local waveLabel: TextLabel
local waveBar: Frame
local lockButton: TextButton
local slapButton: TextButton
local speedButton: TextButton
local slotsButton: TextButton
local rebirthButton: TextButton
local bannerLabel: TextLabel
local baseLabel: TextLabel
local boardList: TextLabel
local goldenFrame: Frame
local hintLabel: TextLabel

local function label(parent: Instance, name: string, text: string, size: UDim2, position: UDim2): TextLabel
	local made = Instance.new("TextLabel")
	made.Name = name
	made.Size = size
	made.Position = position
	made.BackgroundTransparency = 1
	made.TextColor3 = Color3.fromRGB(255, 255, 255)
	made.TextStrokeTransparency = 0.5
	made.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	made.Font = Enum.Font.GothamBold
	made.TextScaled = true
	made.Text = text
	made.Parent = parent
	return made
end

local function button(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local made = Instance.new("TextButton")
	made.Name = name
	made.Size = size
	made.Position = position
	made.BackgroundColor3 = color
	made.TextColor3 = Color3.fromRGB(255, 255, 255)
	made.TextStrokeTransparency = 0.5
	made.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	made.Font = Enum.Font.GothamBold
	made.TextScaled = true
	made.Text = text
	made.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = made
	return made
end

local function rounded(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

-- Build the whole interface once, when the client starts.
function HUD.build()
	local playerGui = player:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBayHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- Top bar: cash, income and rebirths, centred at the top.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(0, 460, 0, 60)
	topBar.Position = UDim2.new(0.5, -230, 0, 10)
	topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	topBar.BackgroundTransparency = 0.25
	topBar.Parent = gui
	rounded(topBar, 10)
	cashLabel = label(topBar, "Cash", "$100", UDim2.new(0.45, 0, 0, 34), UDim2.new(0.05, 0, 0, 4))
	incomeLabel = label(topBar, "Income", "+$0/s", UDim2.new(0.45, 0, 0, 20), UDim2.new(0.52, 0, 0, 8))
	rebirthLabel = label(topBar, "Rebirths", "Rebirths: 0", UDim2.new(0.45, 0, 0, 20), UDim2.new(0.52, 0, 0, 32))

	-- Wave timer bar under the top bar.
	local waveFrame = Instance.new("Frame")
	waveFrame.Name = "WaveFrame"
	waveFrame.Size = UDim2.new(0, 300, 0, 26)
	waveFrame.Position = UDim2.new(0.5, -150, 0, 78)
	waveFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	waveFrame.BackgroundTransparency = 0.25
	waveFrame.Parent = gui
	rounded(waveFrame, 8)
	waveBar = Instance.new("Frame")
	waveBar.Name = "WaveBar"
	waveBar.Size = UDim2.new(1, 0, 1, 0)
	waveBar.BackgroundColor3 = Color3.fromRGB(40, 130, 230)
	waveBar.Parent = waveFrame
	rounded(waveBar, 8)
	waveLabel = label(waveFrame, "Wave", "Next wave: 3:00", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))

	-- Golden Hour flag, hidden until the event runs.
	goldenFrame = Instance.new("Frame")
	goldenFrame.Name = "GoldenHour"
	goldenFrame.Size = UDim2.new(0, 260, 0, 34)
	goldenFrame.Position = UDim2.new(0.5, -130, 0, 112)
	goldenFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	goldenFrame.Visible = false
	goldenFrame.Parent = gui
	rounded(goldenFrame, 8)
	local goldText = label(goldenFrame, "GoldenText", "GOLDEN HOUR! Income x2!", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	goldText.TextColor3 = Color3.fromRGB(60, 40, 0)

	-- Banner in the middle of the screen for announcements.
	bannerLabel = label(gui, "Banner", "", UDim2.new(0, 700, 0, 60), UDim2.new(0.5, -350, 0.28, 0))
	bannerLabel.TextTransparency = 1

	-- Leaderboard, top left but below Roblox's own menu buttons.
	local boardFrame = Instance.new("Frame")
	boardFrame.Name = "Leaderboard"
	boardFrame.Size = UDim2.new(0, 220, 0, 150)
	boardFrame.Position = UDim2.new(0, 12, 0, 64)
	boardFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	boardFrame.BackgroundTransparency = 0.25
	boardFrame.Parent = gui
	rounded(boardFrame, 10)
	label(boardFrame, "BoardTitle", "TOP PLAYERS", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 4))
	boardList = label(boardFrame, "BoardList", "", UDim2.new(1, -16, 1, -32), UDim2.new(0, 8, 0, 28))
	boardList.TextXAlignment = Enum.TextXAlignment.Left
	boardList.TextYAlignment = Enum.TextYAlignment.Top

	-- Action buttons down the right side.
	local panel = Instance.new("Frame")
	panel.Name = "ActionPanel"
	panel.Size = UDim2.new(0, 210, 0, 260)
	panel.Position = UDim2.new(1, -222, 0, 64)
	panel.BackgroundTransparency = 1
	panel.Parent = gui
	lockButton = button(panel, "Lock", "Lock Base [L]", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), Color3.fromRGB(40, 120, 220))
	slapButton = button(panel, "Slap", "Slap [F]", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 52), Color3.fromRGB(220, 90, 40))
	speedButton = button(panel, "Speed", "Speed Boots", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 104), Color3.fromRGB(60, 180, 80))
	slotsButton = button(panel, "Slots", "Base Extension", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 156), Color3.fromRGB(140, 90, 220))
	rebirthButton = button(panel, "Rebirth", "Rebirth", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 208), Color3.fromRGB(230, 180, 30))

	-- Base card, bottom left.
	baseLabel = label(gui, "BaseCard", "Your Base: --", UDim2.new(0, 260, 0, 30), UDim2.new(0, 12, 1, -76))
	baseLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Hint bar along the bottom.
	hintLabel = label(gui, "Hint", "Walk to the belt, press E to buy  •  E on a rival's brainrot to steal  •  L locks your base  •  F slaps", UDim2.new(0, 760, 0, 26), UDim2.new(0.5, -380, 1, -36))
	hintLabel.TextColor3 = Color3.fromRGB(220, 220, 220)

	lockButton.MouseButton1Click:Connect(function()
		(Remotes:WaitForChild("ToggleLock") :: RemoteEvent):FireServer()
	end)
	slapButton.MouseButton1Click:Connect(function()
		(Remotes:WaitForChild("SlapPlayer") :: RemoteEvent):FireServer()
	end)
	speedButton.MouseButton1Click:Connect(function()
		(Remotes:WaitForChild("BuyUpgrade") :: RemoteEvent):FireServer("Speed")
	end)
	slotsButton.MouseButton1Click:Connect(function()
		(Remotes:WaitForChild("BuyUpgrade") :: RemoteEvent):FireServer("Slots")
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		(Remotes:WaitForChild("Rebirth") :: RemoteEvent):FireServer()
	end)
end

local function formatMoney(n: number): string
	if n >= 1000000 then
		return "$" .. string.format("%.2fM", n / 1000000)
	elseif n >= 1000 then
		return "$" .. string.format("%.1fK", n / 1000)
	else
		return "$" .. tostring(math.floor(n))
	end
end

-- Refresh every label from one state snapshot.
function HUD.updateState(state)
	cashLabel.Text = formatMoney(state.Cash)
	incomeLabel.Text = "+" .. formatMoney(state.IncomePerSecond):sub(2) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(state.Rebirths)
	if state.LockRemaining > 0 then
		lockButton.Text = "Locked " .. tostring(math.ceil(state.LockRemaining)) .. "s"
	elseif state.LockCooldown > 0 then
		lockButton.Text = "Lock ready in " .. tostring(math.ceil(state.LockCooldown)) .. "s"
	else
		lockButton.Text = "Lock Base [L]"
	end
	local speedCost = BrainrotData.upgradeCost("Speed", state.SpeedLevel)
	if state.SpeedLevel >= BrainrotData.UPGRADES.Speed.MaxLevel then
		speedButton.Text = "Speed Boots MAX"
	else
		speedButton.Text = "Speed Boots $" .. tostring(speedCost)
	end
	local slotsCost = BrainrotData.upgradeCost("Slots", state.SlotsLevel)
	if state.SlotsLevel >= BrainrotData.UPGRADES.Slots.MaxLevel then
		slotsButton.Text = "Base Extension MAX"
	else
		slotsButton.Text = "Base Extension $" .. tostring(slotsCost)
	end
	rebirthButton.Text = "Rebirth $" .. tostring(BrainrotData.rebirthCost(state.Rebirths))
	if state.BaseIndex ~= nil then
		baseLabel.Text = "Your Base: #" .. tostring(state.BaseIndex) .. "  •  Brainrots: " .. tostring(#state.Owned)
	else
		baseLabel.Text = "Waiting for a free base..."
	end
	local lines = {}
	for i, row in ipairs(state.Top) do
		table.insert(lines, tostring(i) .. ". " .. row.Name .. "  " .. formatMoney(row.Cash))
	end
	boardList.Text = table.concat(lines, "\n")
	goldenFrame.Visible = state.GoldenHour
	if state.WaveSeconds ~= nil then
		local s = math.max(0, math.floor(state.WaveSeconds))
		local minutes = math.floor(s / 60)
		local seconds = s % 60
		waveLabel.Text = "Next wave: " .. tostring(minutes) .. ":" .. string.format("%02d", seconds)
		waveBar.Size = UDim2.new(s / 180, 0, 1, 0)
		waveBar.BackgroundColor3 = s <= 15 and Color3.fromRGB(230, 50, 50) or Color3.fromRGB(40, 130, 230)
	end
end

-- Big centre-screen announcement that fades away on its own.
function HUD.showBanner(text: string, colorName: string, seconds: number)
	local colors = {
		Red = Color3.fromRGB(255, 80, 80),
		Green = Color3.fromRGB(80, 255, 120),
		Blue = Color3.fromRGB(90, 170, 255),
		Yellow = Color3.fromRGB(255, 220, 80),
		Orange = Color3.fromRGB(255, 160, 50),
		Gold = Color3.fromRGB(255, 205, 40),
		White = Color3.fromRGB(255, 255, 255),
	}
	bannerLabel.Text = text
	bannerLabel.TextColor3 = colors[colorName] or colors.White
	bannerLabel.TextTransparency = 0
	task.delay(seconds, function()
		local tween = TweenService:Create(bannerLabel, TweenInfo.new(0.8), { TextTransparency = 1 })
		tween:Play()
	end)
end

return HUD
