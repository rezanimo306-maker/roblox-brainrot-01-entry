-- BrainrotData: the one table that defines every brainrot in Brainrot Bay.
-- The server (Conveyor, BaseService, StealService) and the client (HUD
-- labels) both read this module, so a name, a price or a rate is never
-- typed twice. All characters are original: absurd meme-born creatures of
-- our own invention, none copied from Steal a Brainrot or any other game.

local BrainrotData = {}

export type RarityName = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

export type BrainrotDef = {
	Id: string,
	Name: string,
	Blurb: string,
	Rarity: RarityName,
	Rate: number, -- dollars earned per second while it sits on a base
	Cost: number, -- dollars to buy it off the conveyor
	BodyColor: Color3,
	BellyColor: Color3,
	Size: number, -- body block size in studs (bigger = rarer)
	Accessory: string, -- "Hat" | "TopHat" | "Headphones" | "Crown" | "Sneakers" | "Halo" | "None"
}

BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

BrainrotData.RARITY_COLORS = {
	Common = Color3.fromRGB(150, 150, 150),
	Rare = Color3.fromRGB(60, 130, 255),
	Epic = Color3.fromRGB(170, 80, 255),
	Legendary = Color3.fromRGB(255, 160, 30),
	Mythic = Color3.fromRGB(255, 60, 110),
	Secret = Color3.fromRGB(20, 20, 20),
}

-- Weighted spawn chances. Common is the daily bread; Secret is a rumour.
BrainrotData.RARITY_WEIGHTS = {
	Common = 42,
	Rare = 28,
	Epic = 16,
	Legendary = 9,
	Mythic = 4,
	Secret = 1,
}

-- One row per character: id, name, joke, rarity, $/s, price, body colour,
-- belly colour, size, accessory. The factory builds the 3D model from this.
local function char(
	id: string,
	name: string,
	blurb: string,
	rarity: RarityName,
	rate: number,
	cost: number,
	body: Color3,
	belly: Color3,
	size: number,
	accessory: string
): BrainrotDef
	return {
		Id = id,
		Name = name,
		Blurb = blurb,
		Rarity = rarity,
		Rate = rate,
		Cost = cost,
		BodyColor = body,
		BellyColor = belly,
		Size = size,
		Accessory = accessory,
	}
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

BrainrotData.CHARACTERS = {
	char("captain_capybara", "Captain Capybara",
		"A capybara in a tiny captain's hat. He has seen things. Mostly ponds.",
		"Common", 6, 50, rgb(150, 105, 70), rgb(210, 180, 140), 3, "Hat"),
	char("sir_quackington", "Sir Quackington III",
		"A duck in a top hat who files formal complaints about the pond.",
		"Common", 9, 90, rgb(250, 225, 90), rgb(255, 245, 200), 3, "TopHat"),
	char("dj_dill", "DJ Dill",
		"A pickle who drops beats, not brine. The jar is his stage.",
		"Rare", 18, 200, rgb(90, 170, 60), rgb(160, 220, 110), 3, "Headphones"),
	char("drama_llama", "Drama Llama",
		"A llama that gasps at everything. Everything is a scandal.",
		"Rare", 25, 350, rgb(235, 220, 200), rgb(255, 250, 240), 4, "None"),
	char("sneaker_shark", "Sneaker Shark",
		"A shark in limited-edition sneakers. He does not swim. He struts.",
		"Epic", 45, 800, rgb(90, 130, 200), rgb(200, 220, 240), 4, "Sneakers"),
	char("spaghetti_yeti", "Spaghetti Yeti",
		"A yeti made entirely of noodles. Al dente, always.",
		"Epic", 60, 1200, rgb(245, 215, 130), rgb(255, 240, 200), 4, "None"),
	char("disco_potato", "Disco Potato",
		"A potato that never stops dancing. The floor is lava. He is the lava.",
		"Legendary", 110, 2500, rgb(215, 165, 90), rgb(240, 205, 140), 4, "Headphones"),
	char("ninja_noodle", "Ninja Noodle",
		"A noodle. A ninja. Both. You never saw him. He saw you.",
		"Legendary", 150, 4000, rgb(60, 60, 70), rgb(120, 120, 140), 5, "None"),
	char("golden_gooseberry", "Golden Gooseberry",
		"A gooseberry made of solid gold. It hums. Nobody knows the tune.",
		"Mythic", 300, 10000, rgb(255, 205, 40), rgb(255, 235, 150), 5, "Crown"),
	char("almighty_air_fryer", "The Almighty Air Fryer",
		"It fries. It rules. It judges your snacks and finds them wanting.",
		"Secret", 750, 30000, rgb(40, 40, 45), rgb(255, 120, 40), 6, "Halo"),
}

-- Mutations roll when a brainrot spawns. The multiplier applies to its rate.
BrainrotData.MUTATIONS = {
	{ Name = "Normal", Multiplier = 1, Chance = 84.5 },
	{ Name = "Golden", Multiplier = 3, Chance = 10 },
	{ Name = "Diamond", Multiplier = 5, Chance = 4 },
	{ Name = "Rainbow", Multiplier = 10, Chance = 1.5 },
	{ Name = "Cosmic", Multiplier = 20, Chance = 0.5 },
}

BrainrotData.MUTATION_COLORS = {
	Normal = Color3.fromRGB(255, 255, 255),
	Golden = Color3.fromRGB(255, 205, 40),
	Diamond = Color3.fromRGB(140, 220, 255),
	Rainbow = Color3.fromRGB(255, 90, 200),
	Cosmic = Color3.fromRGB(150, 80, 255),
}

-- Rebirth: reset cash and brainrots for a permanent income multiplier.
-- The price grows with each rebirth; the multiplier is +25% per rebirth.
function BrainrotData.rebirthCost(rebirths: number): number
	return 100000 * (rebirths + 1)
end

function BrainrotData.rebirthMultiplier(rebirths: number): number
	return 1 + 0.25 * rebirths
end

-- Base upgrades, bought from the shop panel.
BrainrotData.UPGRADES = {
	Speed = { Name = "Speed Boots", BaseCost = 500, MaxLevel = 3, WalkSpeedPerLevel = 2 },
	Slots = { Name = "Base Extension", BaseCost = 1000, MaxLevel = 2, SlotsPerLevel = 3 },
}

function BrainrotData.upgradeCost(kind: string, level: number): number
	local def = BrainrotData.UPGRADES[kind]
	if def == nil then
		return 0
	end
	return def.BaseCost * (level + 1)
end

-- Pick one character definition: first a rarity, weighted, then a
-- character inside that rarity.
function BrainrotData.rollCharacter(): BrainrotDef
	local totalWeight = 0
	for _, w in pairs(BrainrotData.RARITY_WEIGHTS) do
		totalWeight += w
	end
	local roll = math.random() * totalWeight
	local rarity: RarityName = "Common"
	for _, name in ipairs(BrainrotData.RARITY_ORDER) do
		roll -= BrainrotData.RARITY_WEIGHTS[name]
		if roll <= 0 then
			rarity = name :: RarityName
			break
		end
	end
	local pool = {}
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		if def.Rarity == rarity then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation for a fresh spawn.
function BrainrotData.rollMutation(): (string, number)
	local roll = math.random() * 100
	local acc = 0
	for _, m in ipairs(BrainrotData.MUTATIONS) do
		acc += m.Chance
		if roll <= acc then
			return m.Name, m.Multiplier
		end
	end
	return "Normal", 1
end

function BrainrotData.findById(id: string): BrainrotDef?
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		if def.Id == id then
			return def
		end
	end
	return nil
end

return BrainrotData
