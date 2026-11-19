-- Brainrot Bay: server bootstrap.
-- Starts the world, the belt, the wave and the events, gives every joining
-- player a base, and wires every RemoteEvent to the service that answers it.
-- One script starts everything, so the server's boot order is readable here.

local Players = game:GetService("Players")

local Remotes = require(script.Parent:WaitForChild("Remotes"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local StealService = require(script.Parent:WaitForChild("StealService"))
local WaveService = require(script.Parent:WaitForChild("WaveService"))
local RebirthService = require(script.Parent:WaitForChild("RebirthService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local EventService = require(script.Parent:WaitForChild("EventService"))

Remotes.init()
WorldBuilder.build()
Conveyor.start()
StealService.start()
WaveService.start()
EventService.start()
ShopService.start()
PlayerState.startIncomeLoop()

-- A base for every player who joins, and the same again for anyone already
-- here when the server started.
local function welcome(player: Player)
	local baseIndex = BaseService.assignBase(player)
	if baseIndex ~= nil then
		PlayerState.announce(player.Name .. " joined the bay!", "White", 3)
	else
		PlayerState.announce("All bases are taken! " .. player.Name .. " is waiting for a spot.", "Red", 5)
	end
	PlayerState.sync(player)
end

Players.PlayerAdded:Connect(welcome)
Players.PlayerRemoving:Connect(function(player)
	StealService.dropCarried(player)
	BaseService.freeBase(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	BaseService.assignBase(player)
	PlayerState.sync(player)
end

-- Every client request lands here and is answered by its service.
Remotes.get("SlapPlayer").OnServerEvent:Connect(function(player)
	StealService.trySlap(player)
end)
Remotes.get("ToggleLock").OnServerEvent:Connect(function(player)
	local ok, _message = BaseService.lockBase(player)
	if not ok then
		PlayerState.sync(player)
	end
end)
Remotes.get("BuyUpgrade").OnServerEvent:Connect(function(player, kind)
	if typeof(kind) == "string" then
		ShopService.tryBuyUpgrade(player, kind)
	end
end)
Remotes.get("Rebirth").OnServerEvent:Connect(function(player)
	RebirthService.tryRebirth(player)
end)

print("Brainrot Bay is live: the belt is rolling and the wave is coming.")
