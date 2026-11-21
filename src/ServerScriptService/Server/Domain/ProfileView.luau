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
		stats = pet.stats,
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
		})
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
	}
end

return ProfileView
