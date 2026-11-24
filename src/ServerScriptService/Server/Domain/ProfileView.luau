--!strict
-- Proyección del perfil que se envía al cliente: solo lo necesario para la interfaz,
-- con datos derivados ya calculados por el servidor (nivel, próximo objetivo, etc.).
-- El cliente nunca recibe el registro de recompensas ni metadatos internos.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local SpeciesConfig = require(Shared.Config.Species)
local Encounters = require(Shared.Config.Encounters)
local Progression = require(Shared.Config.Progression)
local Leveling = require(Shared.Domain.Leveling)
local Stats = require(Shared.Domain.Stats)
local Types = require(Shared.Types)
local SanctuaryRules = require(script.Parent.SanctuaryRules)
local EncounterRules = require(script.Parent.EncounterRules)
local PetRules = require(script.Parent.PetRules)
local EggRules = require(script.Parent.EggRules)
local QuestRules = require(script.Parent.QuestRules)
local ChestRules = require(script.Parent.ChestRules)
local CollectionRules = require(script.Parent.CollectionRules)
local AchievementRules = require(script.Parent.AchievementRules)
local Incubation = require(Shared.Config.Incubation)
local Chests = require(Shared.Config.Chests)

type Profile = Types.Profile

local ProfileView = {}

function ProfileView.pet(p: Profile, pet: Types.PetInstance): { [string]: any }
	local species = SpeciesConfig.ById[pet.speciesId]
	local canEvolve, evolveReason = Leveling.canEvolve(pet)
	local hid, slot = SanctuaryRules.locationOf(p, pet.id)
	local eff = Stats.effective(pet.speciesId, pet.form, pet.level)
	return {
		id = pet.id,
		speciesId = pet.speciesId,
		form = pet.form,
		name = pet.nickname or (if pet.form == "Tallado" then species.talladoName else species.broteName),
		speciesName = if pet.form == "Tallado" then species.talladoName else species.broteName,
		level = pet.level,
		xp = pet.xp,
		xpToNext = Leveling.xpToNext(pet.level),
		bond = pet.bond,
		hearts = Leveling.bondHearts(pet.bond),
		maxHearts = #Progression.Bond.Thresholds,
		nextBond = Leveling.nextBondThreshold(pet.bond),
		formStats = Stats.formBase(pet.speciesId, pet.form),
		maxHp = Stats.maxHp(eff.VID),
		objective = Leveling.nextObjective(pet),
		canEvolve = canEvolve,
		evolveBlocker = evolveReason,
		playReadyAt = pet.lastPlayedAt + Progression.Bond.PlayCooldownSeconds,
		habitat = hid,
		slot = slot,
		isCompanion = p.companionPetId == pet.id,
		inTeam = table.find(p.team, pet.id) ~= nil,
		stats = pet.stats,
		rarity = species.rarity,
		elements = species.elements,
		traits = pet.traits,
		acquired = pet.acquired,
		talladoLevel = Leveling.talladoLevel(pet.speciesId),
		nexoLevel = Progression.NexoUnlockLevel,
		moves = pet.loadout,
	}
end

local function adventureView(p: Profile, now: number)
	local stages = {}
	local totalStars = 0
	for _, id in ipairs(Encounters.Order) do
		local cleared = p.story.cleared[id]
		local st = p.story.stars[id] or { false, false, false }
		for _, b in ipairs(st) do
			if b then
				totalStars += 1
			end
		end
		stages[id] = {
			unlocked = EncounterRules.isUnlocked(p, id),
			cleared = cleared ~= nil,
			wins = if cleared then cleared.wins else 0,
			stars = st,
			bestTurns = p.story.bestTurns[id],
			opponent = EncounterRules.opponentSpecies(p, id),
			opponents = EncounterRules.opponentsFor(p, id),
			attempts = p.story.treasureAttempts[id],
		}
	end
	local regions = {}
	for _, region in ipairs(Encounters.Regions) do
		table.insert(regions, {
			index = region.index,
			cleared = EncounterRules.regionCleared(p, region.index),
			allStars = EncounterRules.regionAllStars(p, region.index),
		})
	end
	return {
		stages = stages,
		regions = regions,
		totalStars = totalStars,
		maxStars = #Encounters.Order * 3,
		guardians = p.guardians,
		repeatsLeft = Encounters.Repeat.DailyRewardedRepeats
			- (if p.story.repeatDay == math.floor(now / 86400) then p.story.repeatCount else 0),
	}
end

function ProfileView.build(p: Profile, now: number): { [string]: any }
	local pets = {}
	for _, pet in pairs(p.pets) do
		table.insert(pets, ProfileView.pet(p, pet))
	end
	table.sort(pets, function(a, b)
		return a.id < b.id
	end)
	local habitats = {}
	for lotId, lot in pairs(p.lots) do
		for hid, h in pairs(lot.habitats) do
			habitats[hid] = {
				id = hid,
				lot = lotId,
				unlocked = lot.unlocked,
				slots = h.slots,
				pendingCoins = SanctuaryRules.preview(p, hid, now),
				ratePerHour = SanctuaryRules.habitatRate(p, hid),
			}
		end
	end
	local encounters = {}
	for _, id in ipairs(Encounters.Order) do
		local cleared = p.story.cleared[id]
		encounters[id] = {
			unlocked = EncounterRules.isUnlocked(p, id),
			cleared = cleared ~= nil,
			wins = if cleared then cleared.wins else 0,
			opponent = EncounterRules.opponentSpecies(p, id),
		}
	end
	local pending = {}
	for id, r in pairs(p.rewards.pending) do
		table.insert(pending, {
			id = id,
			title = r.title,
			currencies = r.currencies,
			items = r.items,
			petXp = r.petXp,
			unlocks = r.unlocks,
			source = r.source,
			chests = r.chests,
			eggs = r.eggs,
			decor = r.decor,
			titles = r.titles,
			frames = r.frames,
		})
	end
	table.sort(pending, function(a, b)
		return a.id < b.id
	end)
	local eggs = {}
	for _, egg in pairs(p.eggs) do
		table.insert(eggs, {
			id = egg.id,
			speciesId = egg.speciesId,
			rarity = egg.rarity,
			state = egg.state,
			slot = egg.slot,
			obtainedAt = egg.obtainedAt,
			source = egg.source.kind,
			seconds = EggRules.seconds(egg.rarity),
		})
	end
	table.sort(eggs, function(a, b)
		return a.id < b.id
	end)
	local incubators = {}
	for i, slot in ipairs(p.incubators) do
		local egg = if slot.eggId then p.eggs[slot.eggId :: string] else nil
		local rule = Incubation.Slots[i]
		table.insert(incubators, {
			slot = i,
			unlocked = slot.unlocked,
			eggId = slot.eggId,
			speciesId = if egg then egg.speciesId else nil,
			rarity = if egg then egg.rarity else nil,
			startedAt = if egg then egg.startedAt else nil,
			readyAt = if egg then egg.readyAt else nil,
			progress = if egg then EggRules.progress(egg, now) else 0,
			ready = egg ~= nil and now >= (egg.readyAt or math.huge),
			unlockLabel = rule.label,
			buyable = not slot.unlocked and rule.availableInBeta and rule.unlock == "Monedas",
			price = rule.price,
		})
	end
	local chests = {}
	for _, chest in pairs(p.chests) do
		local def = Chests.ById[chest.chestType]
		table.insert(chests, {
			id = chest.id,
			chestType = chest.chestType,
			name = def.name,
			tier = def.tier,
			contents = chest.contents,
			codex = (chest :: any).codex,
			source = chest.source.kind,
			obtainedAt = chest.obtainedAt,
			odds = ChestRules.odds(p, chest.id),
		})
	end
	table.sort(chests, function(a, b)
		return a.id < b.id
	end)
	-- La rotación del tablón es idempotente: refrescar aquí muestra siempre el del día
	QuestRules.refresh(p, now)
	local function questView(slot: Types.QuestSlot?, kind: string, index: number)
		if not slot then
			return nil
		end
		local def = QuestRules.def(slot.questId)
		return {
			kind = kind,
			index = index,
			questId = slot.questId,
			title = if def then def.title else slot.questId,
			description = if def then def.description else "",
			difficulty = if def then def.difficulty else "Easy",
			progress = slot.progress,
			target = slot.target,
			coins = slot.coins,
			claimed = slot.claimed,
			complete = slot.progress >= slot.target,
		}
	end
	local daily = {}
	for i, slot in ipairs(p.quests.daily) do
		table.insert(daily, questView(slot, "Daily", i))
	end
	local history = {}
	for i = #p.history, math.max(1, #p.history - 29), -1 do
		table.insert(history, p.history[i])
	end
	return {
		serverTime = now,
		currencies = p.currencies,
		items = p.items,
		pets = pets,
		petCount = PetRules.petCount(p),
		inventoryUsed = PetRules.inventoryUsed(p),
		inventoryCapacity = p.inventoryCapacity,
		companionPetId = p.companionPetId,
		team = p.team,
		habitats = habitats,
		onboarding = { step = p.onboarding.step, completed = p.onboarding.completed },
		unlocks = p.unlocks,
		encounters = encounters,
		pendingRewards = pending,
		-- Fase 2
		collection = p.collection,
		collectionProgress = CollectionRules.progress(p),
		eggs = eggs,
		eggStorage = { used = EggRules.storedCount(p), capacity = Incubation.EggStorageCapacity },
		incubators = incubators,
		chests = chests,
		history = history,
		quests = {
			daily = daily,
			weekly = questView(p.quests.weekly, "Weekly", 1),
			dailyBonusClaimed = p.quests.dailyBonusClaimed,
			nextDailyReset = QuestRules.nextDailyReset(now),
			nextWeeklyReset = QuestRules.nextWeeklyReset(now),
		},
		adventure = adventureView(p, now),
		codex = p.codex,
		decor = p.decor,
		showcase = p.showcase,
		titles = p.titles,
		frames = p.frames,
		guardians = p.guardians,
		achievements = AchievementRules.view(p),
	}
end

return ProfileView
