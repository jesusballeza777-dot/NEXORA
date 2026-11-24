--!strict
-- Logros (Config/Achievements, D-033). Regla pura sobre el perfil:
-- * La métrica se calcula a partir del estado del perfil (colección, estrellas,
--   guardianes, contadores del servidor). El cliente no informa de progreso.
-- * Al alcanzar la meta: p.achievements[id] = hora del servidor y recompensa pendiente
--   "achievement:<id>" por RewardRules (idempotente: si ya existía, no se repite).
-- * Se evalúa al final de cada caso de uso (Actions.finish) y al cargar el perfil, así
--   que los jugadores que ya cumplían la meta antes de la v3 la reciben al entrar.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Achievements = require(Shared.Config.Achievements)
local Encounters = require(Shared.Config.Encounters)
local Types = require(Shared.Types)
local CollectionRules = require(script.Parent.CollectionRules)
local RewardRules = require(script.Parent.RewardRules)

type Profile = Types.Profile

local AchievementRules = {}

function AchievementRules.rewardId(achievementId: string): string
	return "achievement:" .. achievementId
end

function AchievementRules.metric(p: Profile, metric: string): number
	local n = 0
	if metric == "SpeciesDiscovered" then
		for _, e in pairs(p.collection) do
			if CollectionRules.isDiscovered(e) then
				n += 1
			end
		end
	elseif metric == "SpeciesRestored" then
		for _, e in pairs(p.collection) do
			if e.restoredAt ~= nil then
				n += 1
			end
		end
	elseif metric == "Tallados" then
		for _, e in pairs(p.collection) do
			if e.talladoAt ~= nil then
				n += 1
			end
		end
	elseif metric == "EggsHatched" then
		n = p.counters.eggsHatched or 0
	elseif metric == "Stars" then
		for encounterId, marks in pairs(p.story.stars) do
			local enc = Encounters.ById[encounterId]
			if enc and enc.act == "ActoI" then
				for _, got in ipairs(marks) do
					if got then
						n += 1
					end
				end
			end
		end
	elseif metric == "Guardians" then
		for _ in pairs(p.guardians) do
			n += 1
		end
	end
	return n
end

-- Marca los logros cumplidos y crea sus recompensas pendientes. Devuelve los nuevos.
function AchievementRules.refresh(p: Profile, now: number): { string }
	local unlocked = {}
	for _, id in ipairs(Achievements.Order) do
		local def = Achievements.ById[id]
		if p.achievements[id] == nil and AchievementRules.metric(p, def.metric) >= def.goal then
			local created = RewardRules.create(p, AchievementRules.rewardId(id), {
				title = "Logro: " .. def.name,
				currencies = def.reward.currencies,
				chests = def.reward.chests,
				eggs = def.reward.eggs,
				titles = def.reward.titles,
			}, { kind = "Achievement", ref = id }, now)
			if created.ok then
				p.achievements[id] = now
				table.insert(unlocked, id)
			end
		end
	end
	return unlocked
end

-- Vista para el cliente: progreso (acotado a la meta), cuándo se logró y si el premio
-- sigue pendiente de reclamar.
function AchievementRules.view(p: Profile): { { [string]: any } }
	local out = {}
	for _, id in ipairs(Achievements.Order) do
		local def = Achievements.ById[id]
		table.insert(out, {
			id = id,
			goal = def.goal,
			progress = math.min(def.goal, AchievementRules.metric(p, def.metric)),
			unlockedAt = p.achievements[id],
			rewardId = AchievementRules.rewardId(id),
			rewardPending = p.rewards.pending[AchievementRules.rewardId(id)] ~= nil,
		})
	end
	return out
end

return AchievementRules
