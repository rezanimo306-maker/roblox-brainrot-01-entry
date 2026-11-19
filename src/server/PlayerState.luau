-- PlayerState: the single store for everything about a player.
-- Cash, brainrots, rebirths, upgrades, locks and what they carry all live
-- here, so no service ever keeps its own copy of a player's money or pets.
-- Income ticks here too: one loop, once a second, for every player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local PlayerState = {}

export type OwnedBrainrot = {
	Uid: number,
	DefId: string,
	Name: string,
	Rarity: string,
	Mutation: string,
	Multiplier: number,
	Rate: number,
	SlotIndex: number,
	Model: Model,
}

export type State = {
	Cash: number,
	IncomePerSecond: number,
	Rebirths: number,
	SpeedLevel: number,
	SlotsLevel: number,
	BaseIndex: number?,
	LockUntil: number,
	LockCooldownUntil: number,
	SlapCooldownUntil: number,
	CarryingUid: number?,
	Owned: { OwnedBrainrot },
}

local states: { [Player]: State } = {}
local goldenHour = false
local waveSecondsLeft = Config.WAVE.CycleSeconds

function PlayerState.setWaveSeconds(seconds: number)
	waveSecondsLeft = seconds
end

function PlayerState.setGoldenHour(active: boolean)
	goldenHour = active
end

function PlayerState.isGoldenHour(): boolean
	return goldenHour
end

function PlayerState.newPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = Config.START_CASH
	cashValue.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats

	states[player] = {
		Cash = Config.START_CASH,
		IncomePerSecond = 0,
		Rebirths = 0,
		SpeedLevel = 0,
		SlotsLevel = 0,
		BaseIndex = nil,
		LockUntil = 0,
		LockCooldownUntil = 0,
		SlapCooldownUntil = 0,
		CarryingUid = nil,
		Owned = {},
	}
end

function PlayerState.removePlayer(player: Player)
	states[player] = nil
end

function PlayerState.get(player: Player): State?
	return states[player]
end

function PlayerState.allPlayers(): { Player }
	local list = {}
	for player, _ in pairs(states) do
		table.insert(list, player)
	end
	return list
end

function PlayerState.maxSlots(state: State): number
	return Config.SLOTS_PER_BASE + state.SlotsLevel * BrainrotData.UPGRADES.Slots.SlotsPerLevel
end

function PlayerState.freeSlot(state: State): number?
	local taken = {}
	for _, owned in ipairs(state.Owned) do
		taken[owned.SlotIndex] = true
	end
	for i = 1, PlayerState.maxSlots(state) do
		if not taken[i] then
			return i
		end
	end
	return nil
end

-- Dollars per second for one player: every brainrot's rate, times the
-- rebirth multiplier, times the Golden Hour multiplier when it runs.
function PlayerState.incomeRate(state: State): number
	local sum = 0
	for _, owned in ipairs(state.Owned) do
		sum += owned.Rate
	end
	local rate = sum * BrainrotData.rebirthMultiplier(state.Rebirths)
	if goldenHour then
		rate *= Config.GOLDEN_HOUR.IncomeMultiplier
	end
	return math.floor(rate)
end

-- One tick of income for every player, once a second.
function PlayerState.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(Config.INCOME_TICK_SECONDS)
			for player, state in pairs(states) do
				local rate = PlayerState.incomeRate(state)
				state.IncomePerSecond = rate
				if rate > 0 then
					state.Cash += rate
				end
				local board = player:FindFirstChild("leaderstats")
				if board then
					local cashValue = board:FindFirstChild("Cash") :: IntValue?
					if cashValue then
						cashValue.Value = state.Cash
					end
					local rebirthValue = board:FindFirstChild("Rebirths") :: IntValue?
					if rebirthValue then
						rebirthValue.Value = state.Rebirths
					end
				end
				PlayerState.sync(player)
			end
		end
	end)
end

-- Send one player their full state snapshot for the HUD.
function PlayerState.sync(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local ownedSummary = {}
	for _, owned in ipairs(state.Owned) do
		table.insert(ownedSummary, {
			Uid = owned.Uid,
			Name = owned.Name,
			Rarity = owned.Rarity,
			Mutation = owned.Mutation,
			Rate = owned.Rate,
			SlotIndex = owned.SlotIndex,
		})
	end
	Remotes.get("StateSync"):FireClient(player, {
		Cash = state.Cash,
		IncomePerSecond = state.IncomePerSecond,
		Rebirths = state.Rebirths,
		SpeedLevel = state.SpeedLevel,
		SlotsLevel = state.SlotsLevel,
		BaseIndex = state.BaseIndex,
		LockRemaining = math.max(0, state.LockUntil - os.clock()),
		LockCooldown = math.max(0, state.LockCooldownUntil - os.clock()),
		CarryingUid = state.CarryingUid,
		Owned = ownedSummary,
		Top = PlayerState.topByCash(5),
		GoldenHour = goldenHour,
		WaveSeconds = waveSecondsLeft,
	})
end

function PlayerState.topByCash(count: number): { { Name: string, Cash: number, Rebirths: number } }
	local rows = {}
	for player, state in pairs(states) do
		table.insert(rows, { Name = player.Name, Cash = state.Cash, Rebirths = state.Rebirths })
	end
	table.sort(rows, function(a, b)
		return a.Cash > b.Cash
	end)
	while #rows > count do
		table.remove(rows)
	end
	return rows
end

-- Broadcast a banner to every player.
function PlayerState.announce(text: string, colorName: string, seconds: number)
	Remotes.get("Announce"):FireAllClients(text, colorName, seconds)
end

Players.PlayerAdded:Connect(function(player)
	PlayerState.newPlayer(player)
end)
Players.PlayerRemoving:Connect(function(player)
	PlayerState.removePlayer(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	PlayerState.newPlayer(player)
end

return PlayerState
