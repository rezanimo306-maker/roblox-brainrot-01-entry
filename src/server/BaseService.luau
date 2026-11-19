-- BaseService: the eight bases and what sits on them.
-- A player gets the first free base when they join. A bought brainrot walks
-- from the belt to a free slot on its new owner's base and earns there.
-- The lock button seals a base against thieves for 45 seconds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BaseService = {}

local baseOwner: { [number]: Player? } = {}

-- Give the joining player the first free base, or nil when all eight are taken.
function BaseService.assignBase(player: Player): number?
	for i = 1, #Config.BASES do
		if baseOwner[i] == nil then
			baseOwner[i] = player
			local state = PlayerState.get(player)
			if state then
				state.BaseIndex = i
				PlayerState.sync(player)
			end
			return i
		end
	end
	return nil
end

function BaseService.freeBase(player: Player)
	local state = PlayerState.get(player)
	if state ~= nil and state.BaseIndex ~= nil then
		baseOwner[state.BaseIndex] = nil
		state.BaseIndex = nil
	end
end

function BaseService.ownerOf(baseIndex: number): Player?
	return baseOwner[baseIndex]
end

function BaseService.baseOf(player: Player): number?
	local state = PlayerState.get(player)
	if state then
		return state.BaseIndex
	end
	return nil
end

-- Find any owned brainrot by uid, across all players.
function BaseService.findOwned(uid: number): (Player?, PlayerState.State?, PlayerState.OwnedBrainrot?, number?)
	for _, player in ipairs(PlayerState.allPlayers()) do
		local state = PlayerState.get(player)
		if state then
			for i, owned in ipairs(state.Owned) do
				if owned.Uid == uid then
					return player, state, owned, i
				end
			end
		end
	end
	return nil, nil, nil, nil
end

-- A brainrot walks from where it is to its slot, hopping as it goes, then
-- settles and starts earning. The walk is a short lerp, not a teleport, so
-- the purchase reads on screen.
local function walkToSlot(record: PlayerState.OwnedBrainrot, slotCenter: Vector3)
	local model = record.Model
	local startCFrame = model:GetPivot()
	local body = model.PrimaryPart
	local height = body and body.Size.Y or 3
	local target = CFrame.new(slotCenter.X, 1.3 + height / 2, slotCenter.Z)
	local steps = 24
	for i = 1, steps do
		local t = i / steps
		local pos = startCFrame.Position:Lerp(target.Position, t)
		pos = Vector3.new(pos.X, pos.Y + math.sin(t * math.pi) * 2, pos.Z)
		model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0))
		task.wait(0.05)
	end
	model:PivotTo(target)
end

-- Place a bought brainrot on the buyer's base. Returns the slot, or nil.
function BaseService.placeBrainrot(player: Player, record: PlayerState.OwnedBrainrot): number?
	local state = PlayerState.get(player)
	if state == nil or state.BaseIndex == nil then
		return nil
	end
	local slotIndex = PlayerState.freeSlot(state)
	if slotIndex == nil then
		return nil
	end
	record.SlotIndex = slotIndex
	table.insert(state.Owned, record)
	local slotCenter = Config.slotCenter(state.BaseIndex, slotIndex)
	task.spawn(walkToSlot, record, slotCenter)
	PlayerState.sync(player)
	return slotIndex
end

-- Remove a brainrot from its owner's list (stolen, rebirthed, or dropped).
-- The model itself is left alone: the caller decides what happens to it.
function BaseService.removeOwned(player: Player, uid: number): PlayerState.OwnedBrainrot?
	local state = PlayerState.get(player)
	if state == nil then
		return nil
	end
	for i, owned in ipairs(state.Owned) do
		if owned.Uid == uid then
			table.remove(state.Owned, i)
			PlayerState.sync(player)
			return owned
		end
	end
	return nil
end

-- Lock your base: no stealing from it until the lock runs out.
function BaseService.lockBase(player: Player): (boolean, string)
	local state = PlayerState.get(player)
	if state == nil or state.BaseIndex == nil then
		return false, "You have no base yet."
	end
	local now = os.clock()
	if now < state.LockUntil then
		return false, "Your base is already locked."
	end
	if now < state.LockCooldownUntil then
		return false, "Lock is recharging."
	end
	state.LockUntil = now + Config.LOCK_SECONDS
	state.LockCooldownUntil = now + Config.LOCK_SECONDS + Config.LOCK_COOLDOWN_SECONDS
	WorldBuilder.setLockLight(state.BaseIndex, true)
	task.delay(Config.LOCK_SECONDS, function()
		WorldBuilder.setLockLight(state.BaseIndex, false)
		PlayerState.sync(player)
	end)
	PlayerState.sync(player)
	return true, "Base locked for " .. tostring(Config.LOCK_SECONDS) .. " seconds."
end

function BaseService.isLocked(player: Player): boolean
	local state = PlayerState.get(player)
	if state == nil then
		return false
	end
	return os.clock() < state.LockUntil
end

return BaseService
