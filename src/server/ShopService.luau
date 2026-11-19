-- ShopService: buying off the belt, and buying upgrades.
-- Every purchase is validated on the server: the cash, the free slot and the
-- brainrot still being on the belt are all checked here, never on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local StealService = require(script.Parent:WaitForChild("StealService"))

local ShopService = {}

-- Buy a brainrot off the conveyor belt.
function ShopService.tryBuy(player: Player, uid: number): (boolean, string)
	local state = PlayerState.get(player)
	if state == nil then
		return false, "No state."
	end
	local record = Conveyor.getBeltBrainrot(uid)
	if record == nil then
		return false, "That brainrot is gone."
	end
	if state.Cash < record.Def.Cost then
		return false, "You need $" .. tostring(record.Def.Cost) .. "."
	end
	if state.BaseIndex == nil then
		return false, "You have no base yet."
	end
	if PlayerState.freeSlot(state) == nil then
		return false, "Your base is full."
	end
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local brainRoot = record.Model.PrimaryPart
	if myRoot == nil or brainRoot == nil then
		return false, "Too far away."
	end
	if (myRoot.Position - brainRoot.Position).Magnitude > Config.BUY_RANGE + 2 then
		return false, "Walk up to the belt first."
	end
	state.Cash -= record.Def.Cost
	Conveyor.removeFromBelt(uid)
	local owned: PlayerState.OwnedBrainrot = {
		Uid = record.Uid,
		DefId = record.Def.Id,
		Name = record.Def.Name,
		Rarity = record.Def.Rarity,
		Mutation = record.Mutation,
		Multiplier = record.Multiplier,
		Rate = record.Rate,
		SlotIndex = 0,
		Model = record.Model,
	}
	local slot = BaseService.placeBrainrot(player, owned)
	if slot == nil then
		state.Cash += record.Def.Cost
		return false, "Your base is full."
	end
	StealService.armBaseBrainrot(owned, player)
	PlayerState.sync(player)
	return true, "You bought " .. record.Def.Name .. "!"
end

-- Buy an upgrade: Speed Boots or a Base Extension.
function ShopService.tryBuyUpgrade(player: Player, kind: string): (boolean, string)
	local state = PlayerState.get(player)
	if state == nil then
		return false, "No state."
	end
	local def = BrainrotData.UPGRADES[kind]
	if def == nil then
		return false, "No such upgrade."
	end
	local level = kind == "Speed" and state.SpeedLevel or state.SlotsLevel
	if level >= def.MaxLevel then
		return false, def.Name .. " is maxed out."
	end
	local cost = BrainrotData.upgradeCost(kind, level)
	if state.Cash < cost then
		return false, def.Name .. " costs $" .. tostring(cost) .. "."
	end
	state.Cash -= cost
	if kind == "Speed" then
		state.SpeedLevel += 1
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.BASE_WALK_SPEED + state.SpeedLevel * 2
		end
	else
		state.SlotsLevel += 1
	end
	PlayerState.sync(player)
	return true, def.Name .. " level " .. tostring(level + 1) .. "!"
end

-- Wire the belt's buy prompts to this service.
function ShopService.start()
	Conveyor.BuyRequested.Event:Connect(function(player, uid)
		local ok, _message = ShopService.tryBuy(player, uid)
		if not ok then
			-- A failed buy is quiet feedback, not a banner.
			PlayerState.sync(player)
		end
	end)
end

return ShopService
