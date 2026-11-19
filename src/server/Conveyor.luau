-- Conveyor: the belt that brings the brainrots in.
-- Every few seconds a fresh brainrot rolls out of the green spawn gate, walks
-- the belt west to east, and leaves through the red gate if nobody buys it.
-- Buying is a ProximityPrompt on the brainrot itself: walk up, press E.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local Conveyor = {}

export type BeltBrainrot = {
	Uid: number,
	Def: BrainrotData.BrainrotDef,
	Mutation: string,
	Multiplier: number,
	Rate: number,
	Model: Model,
	X: number,
	Phase: number,
}

local belt: { [number]: BeltBrainrot } = {}
local nextUid = 1
local beltFolder: Folder

-- Fired when a player presses E on a belt brainrot. ShopService listens.
Conveyor.BuyRequested = Instance.new("BindableEvent")

function Conveyor.getBeltBrainrot(uid: number): BeltBrainrot?
	return belt[uid]
end

function Conveyor.beltCount(): number
	local n = 0
	for _, _ in pairs(belt) do
		n += 1
	end
	return n
end

-- Take a brainrot off the belt (it was bought). Returns its record.
function Conveyor.removeFromBelt(uid: number): BeltBrainrot?
	local record = belt[uid]
	if record == nil then
		return nil
	end
	belt[uid] = nil
	local root = record.Model.PrimaryPart
	local prompt = root and root:FindFirstChild("BuyPrompt") :: ProximityPrompt?
	if prompt then
		prompt:Destroy()
	end
	return record
end

local function spawnOne()
	if Conveyor.beltCount() >= Config.CONVEYOR.MaxOnBelt then
		return
	end
	local def = BrainrotData.rollCharacter()
	local mutation, multiplier = BrainrotData.rollMutation()
	local rate = math.floor(def.Rate * multiplier)
	local rarityColor = BrainrotData.RARITY_COLORS[def.Rarity]

	local model = BrainrotFactory.build(def, mutation, multiplier, rarityColor)
	model.Parent = beltFolder
	model:PivotTo(CFrame.new(
		Config.CONVEYOR.StartX,
		Config.CONVEYOR.BeltTopY + def.Size / 2,
		Config.CONVEYOR.Z
	) * CFrame.Angles(0, math.rad(90), 0))

	local uid = nextUid
	nextUid += 1

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "BUY"
	prompt.ObjectText = def.Name .. "  $" .. tostring(def.Cost)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.BUY_RANGE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		Conveyor.BuyRequested:Fire(player, uid)
	end)

	belt[uid] = {
		Uid = uid,
		Def = def,
		Mutation = mutation,
		Multiplier = multiplier,
		Rate = rate,
		Model = model,
		X = Config.CONVEYOR.StartX,
		Phase = math.random() * math.pi * 2,
	}
end

-- Walk every belt brainrot east; despawn the ones that reach the red gate.
local function stepBelt(dt: number)
	local now = os.clock()
	for uid, record in pairs(belt) do
		record.X += Config.CONVEYOR.Speed * dt
		if record.X >= Config.CONVEYOR.EndX then
			record.Model:Destroy()
			belt[uid] = nil
		else
			local bob = math.sin(now * 3 + record.Phase) * 0.15
			local y = Config.CONVEYOR.BeltTopY + record.Def.Size / 2 + bob
			record.Model:PivotTo(CFrame.new(record.X, y, Config.CONVEYOR.Z) * CFrame.Angles(0, math.rad(90), 0))
		end
	end
end

function Conveyor.start()
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "BeltBrainrots"
	beltFolder.Parent = Workspace

	-- A starter trio so the belt is never empty when the first player joins.
	for _ = 1, 3 do
		spawnOne()
	end

	task.spawn(function()
		while true do
			task.wait(Config.CONVEYOR.SpawnInterval)
			spawnOne()
		end
	end)
	RunService.Heartbeat:Connect(stepBelt)
end

return Conveyor
