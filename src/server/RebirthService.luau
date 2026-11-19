-- RebirthService: trade everything for a permanent boost.
-- Once a player has earned enough, they can rebirth: their cash and their
-- brainrots are wiped, and their income multiplier rises by 25% forever.
-- The price climbs with each rebirth, so the ladder never ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local RebirthService = {}

function RebirthService.tryRebirth(player: Player): (boolean, string)
	local state = PlayerState.get(player)
	if state == nil then
		return false, "No state."
	end
	local cost = BrainrotData.rebirthCost(state.Rebirths)
	if state.Cash < cost then
		return false, "Rebirth costs $" .. tostring(cost) .. "."
	end
	for _, owned in ipairs(state.Owned) do
		owned.Model:Destroy()
	end
	table.clear(state.Owned)
	state.Cash = Config.START_CASH
	state.Rebirths += 1
	local board = player:FindFirstChild("leaderstats")
	if board then
		local rebirthValue = board:FindFirstChild("Rebirths") :: IntValue?
		if rebirthValue then
			rebirthValue.Value = state.Rebirths
		end
	end
	local mult = BrainrotData.rebirthMultiplier(state.Rebirths)
	PlayerState.sync(player)
	PlayerState.announce(
		player.Name .. " REBIRTHED! Income is now x" .. tostring(mult) .. " forever!",
		"Gold",
		6
	)
	return true, "Rebirth " .. tostring(state.Rebirths) .. "! Income x" .. tostring(mult) .. "."
end

return RebirthService
