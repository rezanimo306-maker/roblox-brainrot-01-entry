-- WorldBuilder: the parts of the map that are built when the server starts.
-- The big shapes (baseplate, conveyor, base floors, trees) are static in the
-- Rojo project; this module adds the details that need code to place: the
-- slot pads on every base, the base name signs, the lock lights, the
-- conveyor chevrons and the scattered rocks and bushes.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

local worldFolder: Folder

local function part(name: string, size: Vector3, color: Color3, position: Vector3, parent: Instance): Part
	local made = Instance.new("Part")
	made.Name = name
	made.Size = size
	made.Color = color
	made.Material = Enum.Material.SmoothPlastic
	made.TopSurface = Enum.SurfaceType.Smooth
	made.BottomSurface = Enum.SurfaceType.Smooth
	made.Anchored = true
	made.CanCollide = false
	made.Parent = parent
	made.Position = position
	return made
end

local function textOn(partToLabel: Part, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.Parent = partToLabel
	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(25, 25, 30)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.Parent = gui
	return label
end

-- Twelve slot pads per base: six open from the start, six more unlocked by
-- the Base Extension upgrade. A pad glows faintly so a player can see where
-- a brainrot will land.
local function buildSlots()
	for _, found in ipairs(Config.BASES) do
		for slotIndex = 1, Config.MAX_SLOTS do
			local off = Config.SLOT_OFFSETS[slotIndex]
			if off == nil then
				break
			end
			local center = Vector3.new(found.Center.X + off.X, 1.15, found.Center.Z + off.Z)
			local pad = part(
				"SlotPad_" .. tostring(found.Index) .. "_" .. tostring(slotIndex),
				Config.SLOT_SIZE,
				found.Color,
				center,
				worldFolder
			)
			pad.Transparency = 0.45
			pad.Material = Enum.Material.Neon
		end
	end
end

-- A sign post at the back of each base: "BASE 1" .. "BASE 8", plus a lock
-- light that turns red while the base is locked.
local function buildBaseSigns()
	for _, found in ipairs(Config.BASES) do
		local back = found.Center.Z + 11
		local post = part(
			"BaseSignPost_" .. tostring(found.Index),
			Vector3.new(1, 7, 1),
			Color3.fromRGB(90, 70, 50),
			Vector3.new(found.Center.X, 4.5, back),
			worldFolder
		)
		post.CanCollide = false
		local board = part(
			"BaseSign_" .. tostring(found.Index),
			Vector3.new(9, 3, 0.5),
			Color3.fromRGB(245, 245, 245),
			Vector3.new(found.Center.X, 8, back),
			worldFolder
		)
		textOn(board, "BASE " .. tostring(found.Index))
		local light = part(
			"LockLight_" .. tostring(found.Index),
			Vector3.new(1.5, 1.5, 1.5),
			Color3.fromRGB(60, 220, 90),
			Vector3.new(found.Center.X, 9.5, back),
			worldFolder
		)
		light.Material = Enum.Material.Neon
	end
end

-- Chevrons on the belt so the conveyor's direction reads at a glance.
local function buildConveyorChevrons()
	for x = -50, 50, 10 do
		local chevron = part(
			"Chevron_" .. tostring(x),
			Vector3.new(2, 0.15, 4),
			Color3.fromRGB(255, 220, 60),
			Vector3.new(x, 1.05, Config.CONVEYOR.Z),
			worldFolder
		)
		chevron.Material = Enum.Material.Neon
	end
end

-- Rocks and bushes scattered where they never block a path.
local function buildDecor()
	local rocks = {
		Vector3.new(-65, 1, 0),
		Vector3.new(65, 1, 55),
		Vector3.new(-60, 1, 55),
		Vector3.new(65, 1, -25),
		Vector3.new(-25, 1, -28),
		Vector3.new(25, 1, 55),
	}
	for i, pos in ipairs(rocks) do
		part("Rock_" .. tostring(i), Vector3.new(3, 2, 3), Color3.fromRGB(140, 140, 150), pos, worldFolder)
	end
	local bushes = {
		Vector3.new(-68, 0.8, 25),
		Vector3.new(68, 0.8, 25),
		Vector3.new(-68, 0.8, -15),
		Vector3.new(68, 0.8, 50),
		Vector3.new(-35, 0.8, 55),
		Vector3.new(35, 0.8, -25),
	}
	for i, pos in ipairs(bushes) do
		part("Bush_" .. tostring(i), Vector3.new(4, 1.6, 4), Color3.fromRGB(40, 140, 60), pos, worldFolder)
	end
end

-- The shop sign's text: the kiosk in the middle of the map.
local function buildShopSign()
	local signPart = Workspace:WaitForChild("ShopSign")
	textOn(signPart, "SHOP")
end

function WorldBuilder.build()
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "WorldParts"
	worldFolder.Parent = Workspace
	buildSlots()
	buildBaseSigns()
	buildConveyorChevrons()
	buildDecor()
	buildShopSign()
	return worldFolder
end

-- Flip one base's lock light: green open, red locked.
function WorldBuilder.setLockLight(baseIndex: number, locked: boolean)
	if worldFolder == nil then
		return
	end
	local light = worldFolder:FindFirstChild("LockLight_" .. tostring(baseIndex)) :: Part?
	if light then
		light.Color = locked and Color3.fromRGB(230, 40, 40) or Color3.fromRGB(60, 220, 90)
	end
end

return WorldBuilder
