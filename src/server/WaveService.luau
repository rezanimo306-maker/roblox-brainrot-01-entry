-- WaveService: the tsunami that sweeps the map every three minutes.
-- Ten seconds of warning, then a wall of water rolls in from the sea in the
-- north and crosses the whole map. Stand on your own base and you are safe;
-- get caught out in the open and you are knocked down and drop whatever you
-- were carrying. It is the dash-home moment the genre lives on.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local StealService = require(script.Parent:WaitForChild("StealService"))

local WaveService = {}

local secondsUntilWave = Config.WAVE.CycleSeconds

function WaveService.secondsUntilWave(): number
	return secondsUntilWave
end

local function stunPlayer(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	StealService.dropCarried(player)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	task.delay(Config.WAVE.StunSeconds, function()
		local state = PlayerState.get(player)
		if humanoid.Parent ~= nil and state ~= nil then
			humanoid.WalkSpeed = Config.BASE_WALK_SPEED + state.SpeedLevel * 2
			humanoid.JumpPower = 50
		end
	end)
end

-- The wall is a wide, tall, see-through slab. Anyone it touches who is not
-- standing on their own base gets knocked down.
local function sweepWall()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(170, 30, 4)
	wall.Color = Color3.fromRGB(30, 120, 220)
	wall.Transparency = 0.25
	wall.Material = Enum.Material.Neon
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = Workspace

	local steps = 60
	local zStart = -110
	local zEnd = 70
	local hit: { [Player]: boolean } = {}
	for i = 1, steps do
		local t = i / steps
		local z = zStart + (zEnd - zStart) * t
		wall.Position = Vector3.new(0, 12, z)
		for _, player in ipairs(PlayerState.allPlayers()) do
			if hit[player] == nil then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local state = PlayerState.get(player)
				if root ~= nil and state ~= nil then
					local onOwnBase = state.BaseIndex ~= nil and Config.isOnBase(root.Position, state.BaseIndex)
					if not onOwnBase and math.abs(root.Position.Z - z) < 3 then
						hit[player] = true
						stunPlayer(player)
					end
				end
			end
		end
		task.wait(Config.WAVE.SweepSeconds / steps)
	end
	wall:Destroy()
end

function WaveService.start()
	task.spawn(function()
		while true do
			secondsUntilWave = Config.WAVE.CycleSeconds
			PlayerState.setWaveSeconds(secondsUntilWave)
			while secondsUntilWave > Config.WAVE.WarnSeconds do
				task.wait(1)
				secondsUntilWave -= 1
				PlayerState.setWaveSeconds(secondsUntilWave)
			end
			PlayerState.announce("TSUNAMI INCOMING! Get to your base!", "Blue", Config.WAVE.WarnSeconds)
			task.wait(Config.WAVE.WarnSeconds)
			secondsUntilWave = 0
			sweepWall()
			PlayerState.announce("The wave has passed. Back to the hunt!", "Green", 4)
		end
	end)
end

return WaveService
