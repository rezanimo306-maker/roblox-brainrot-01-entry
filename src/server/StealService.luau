-- StealService: the threat that makes the game tense.
-- Walk up to another player's brainrot, press E, and carry it home: if you
-- reach your own base with it, it is yours. The owner can slap you to make
-- you drop it, a locked base cannot be stolen from at all, and the tsunami
-- makes a caught thief drop everything.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local StealService = {}

-- Brainrots being carried right now: uid -> { Record, Owner }.
-- A brainrot in this table belongs to nobody's list until it is placed,
-- dropped or returned.
local carried: { [number]: { Record: PlayerState.OwnedBrainrot, Owner: Player } } = {}

-- Brainrots lying dropped on the ground: uid -> { Owner, Record, Until }.
local dropped: { [number]: { Owner: Player, Record: PlayerState.OwnedBrainrot, Until: number } } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function setWalkSpeed(player: Player, speed: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

local function slowCarrier(player: Player)
	setWalkSpeed(player, Config.CARRY_WALK_SPEED)
end

local function restoreSpeed(player: Player)
	local state = PlayerState.get(player)
	if state then
		setWalkSpeed(player, Config.BASE_WALK_SPEED + state.SpeedLevel * 2)
	end
end

-- Add the STEAL prompt to a brainrot that sits on someone's base.
local function addStealPrompt(record: PlayerState.OwnedBrainrot, _owner: Player)
	local root = record.Model.PrimaryPart
	if root == nil then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "STEAL"
	prompt.ObjectText = record.Name .. "  $" .. tostring(record.Rate) .. "/s"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.STEAL_RANGE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		StealService.trySteal(player, record.Uid)
	end)
end

-- Add the GRAB prompt to a dropped brainrot lying on the ground.
local function addGrabPrompt(record: PlayerState.OwnedBrainrot)
	local root = record.Model.PrimaryPart
	if root == nil then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "GRAB"
	prompt.ObjectText = record.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.STEAL_RANGE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		StealService.tryGrabDropped(player, record.Uid)
	end)
end

local function removePrompts(record: PlayerState.OwnedBrainrot)
	local root = record.Model.PrimaryPart
	if root == nil then
		return
	end
	for _, name in ipairs({ "StealPrompt", "GrabPrompt" }) do
		local prompt = root:FindFirstChild(name)
		if prompt then
			prompt:Destroy()
		end
	end
end

-- Called when a brainrot lands on a base and starts earning: give it a
-- STEAL prompt so rivals can try to take it.
function StealService.armBaseBrainrot(record: PlayerState.OwnedBrainrot, owner: Player)
	removePrompts(record)
	addStealPrompt(record, owner)
end

-- Pick up a brainrot from a rival's base and carry it overhead.
function StealService.trySteal(player: Player, uid: number): (boolean, string)
	local state = PlayerState.get(player)
	if state == nil then
		return false, "No state."
	end
	if state.CarryingUid ~= nil then
		return false, "You are already carrying one."
	end
	if state.BaseIndex == nil then
		return false, "You have no base to take it to."
	end
	if PlayerState.freeSlot(state) == nil then
		return false, "Your base is full."
	end
	local owner, _ownerState, owned = BaseService.findOwned(uid)
	if owner == nil or owned == nil then
		return false, "That brainrot is gone."
	end
	if owner == player then
		return false, "That one is already yours."
	end
	if BaseService.isLocked(owner) then
		return false, "That base is locked."
	end
	local thiefRoot = rootOf(player)
	local brainRoot = owned.Model.PrimaryPart
	if thiefRoot == nil or brainRoot == nil then
		return false, "Too far away."
	end
	if (thiefRoot.Position - brainRoot.Position).Magnitude > Config.STEAL_RANGE + 2 then
		return false, "Too far away."
	end
	BaseService.removeOwned(owner, uid)
	removePrompts(owned)
	carried[uid] = { Record = owned, Owner = owner }
	state.CarryingUid = uid
	slowCarrier(player)
	PlayerState.sync(player)
	PlayerState.sync(owner)
	PlayerState.announce(player.Name .. " stole " .. owned.Name .. " from " .. owner.Name .. "!", "Red", 4)
	return true, "Run home with it!"
end

-- Pick up a brainrot someone dropped. Your own drops walk straight home.
function StealService.tryGrabDropped(player: Player, uid: number): (boolean, string)
	local entry = dropped[uid]
	if entry == nil then
		return false, "It is gone."
	end
	local state = PlayerState.get(player)
	if state == nil then
		return false, "No state."
	end
	if state.CarryingUid ~= nil then
		return false, "You are already carrying one."
	end
	local record = entry.Record
	if entry.Owner == player then
		dropped[uid] = nil
		removePrompts(record)
		BaseService.placeBrainrot(player, record)
		StealService.armBaseBrainrot(record, player)
		return true, record.Name .. " is home safe."
	end
	if state.BaseIndex == nil then
		return false, "You have no base to take it to."
	end
	if PlayerState.freeSlot(state) == nil then
		return false, "Your base is full."
	end
	dropped[uid] = nil
	removePrompts(record)
	carried[uid] = { Record = record, Owner = entry.Owner }
	state.CarryingUid = uid
	slowCarrier(player)
	PlayerState.sync(player)
	return true, "Run home with it!"
end

-- Drop what a player carries, where they stand. It can be grabbed for 30
-- seconds, then it walks home to its original owner on its own.
function StealService.dropCarried(player: Player)
	local state = PlayerState.get(player)
	if state == nil or state.CarryingUid == nil then
		return
	end
	local uid = state.CarryingUid
	state.CarryingUid = nil
	restoreSpeed(player)
	local entry = carried[uid]
	if entry == nil then
		return
	end
	carried[uid] = nil
	local record = entry.Record
	local root = rootOf(player)
	local dropPos = root and root.Position or Vector3.new(0, 2, 0)
	record.Model:PivotTo(CFrame.new(dropPos.X, 2.5, dropPos.Z))
	addGrabPrompt(record)
	dropped[uid] = { Owner = entry.Owner, Record = record, Until = os.clock() + 30 }
	PlayerState.sync(player)
end

-- The carrier reached their own base: the steal is complete.
local function completeSteal(player: Player)
	local state = PlayerState.get(player)
	if state == nil or state.CarryingUid == nil or state.BaseIndex == nil then
		return
	end
	local uid = state.CarryingUid
	local entry = carried[uid]
	if entry == nil then
		return
	end
	state.CarryingUid = nil
	carried[uid] = nil
	restoreSpeed(player)
	local slot = BaseService.placeBrainrot(player, entry.Record)
	if slot ~= nil then
		StealService.armBaseBrainrot(entry.Record, player)
		PlayerState.announce(player.Name .. " got away with " .. entry.Record.Name .. "!", "Orange", 4)
	else
		-- Base filled up mid-run: drop it at the door instead of losing it.
		carried[uid] = entry
		state.CarryingUid = uid
		slowCarrier(player)
		StealService.dropCarried(player)
	end
end

-- Slap the nearest player who is carrying a brainrot: they drop it.
function StealService.trySlap(player: Player): (boolean, string)
	local state = PlayerState.get(player)
	if state == nil then
		return false, "No state."
	end
	local now = os.clock()
	if now < state.SlapCooldownUntil then
		return false, "Slap is recharging."
	end
	local myRoot = rootOf(player)
	if myRoot == nil then
		return false, "Too far away."
	end
	local target: Player? = nil
	for _, other in ipairs(PlayerState.allPlayers()) do
		if other ~= player then
			local otherState = PlayerState.get(other)
			local otherRoot = rootOf(other)
			if otherState ~= nil and otherState.CarryingUid ~= nil and otherRoot ~= nil then
				if (myRoot.Position - otherRoot.Position).Magnitude <= 8 then
					target = other
					break
				end
			end
		end
	end
	if target == nil then
		return false, "Nobody to slap nearby."
	end
	state.SlapCooldownUntil = now + Config.SLAP_COOLDOWN_SECONDS
	StealService.dropCarried(target)
	PlayerState.announce(player.Name .. " slapped " .. target.Name .. " and the brainrot dropped!", "Yellow", 4)
	return true, "Slapped!"
end

-- Every heartbeat: carry the carried brainrot above its carrier's head, and
-- finish the steal when the carrier stands on their own base.
function StealService.start()
	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(PlayerState.allPlayers()) do
			local state = PlayerState.get(player)
			if state ~= nil and state.CarryingUid ~= nil then
				local uid = state.CarryingUid
				local entry = carried[uid]
				local head = player.Character and player.Character:FindFirstChild("Head")
				if entry ~= nil and entry.Record.Model.PrimaryPart ~= nil and head ~= nil then
					entry.Record.Model:PivotTo(CFrame.new(head.Position + Vector3.new(0, 3, 0)))
				end
				local root = rootOf(player)
				if root ~= nil and state.BaseIndex ~= nil and Config.isOnBase(root.Position, state.BaseIndex) then
					completeSteal(player)
				end
			end
		end
		-- Dropped brainrots walk home after 30 seconds unclaimed.
		local now = os.clock()
		for uid, entry in pairs(dropped) do
			if now >= entry.Until then
				dropped[uid] = nil
				removePrompts(entry.Record)
				BaseService.placeBrainrot(entry.Owner, entry.Record)
				StealService.armBaseBrainrot(entry.Record, entry.Owner)
			end
		end
	end)
end

return StealService
