--!strict
-- Tablón de Encargos: definición (Config/Quests) → instancia en el perfil (QuestSlot con
-- progreso y recompensa congelada) → rotación diaria/semanal con el reloj del servidor.
-- * La selección es determinista por jugador y día (misma cuenta, mismo día ⇒ mismos
--   encargos): reconectar no "vuelve a tirar".
-- * El reloj del dispositivo no interviene: day/week salen de ctx.now (servidor).
-- * Progreso solo por eventos internos (QuestRules.track) emitidos por Actions.
-- * Cada encargo se reclama una vez; los tres diarios reclamados dan un Cofre de Madera.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local Rng = require(Shared.Domain.Rng)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)
local ChestRules = require(script.Parent.ChestRules)
local HistoryRules = require(script.Parent.HistoryRules)

type Profile = Types.Profile

local QuestRules = {}

local DAY = 86400

function QuestRules.dayIndex(now: number): number
	return math.floor((now - Quests.ResetHourUtc * 3600) / DAY)
end

function QuestRules.weekIndex(now: number): number
	return math.floor((QuestRules.dayIndex(now) + Quests.WeekOffsetDays) / 7)
end

function QuestRules.nextDailyReset(now: number): number
	return (QuestRules.dayIndex(now) + 1) * DAY + Quests.ResetHourUtc * 3600
end

function QuestRules.nextWeeklyReset(now: number): number
	local week = QuestRules.weekIndex(now)
	return ((week + 1) * 7 - Quests.WeekOffsetDays) * DAY + Quests.ResetHourUtc * 3600
end

local function eligible(p: Profile, def: Quests.QuestDef): boolean
	if def.requiresUnlock == "HasEgg" then
		return next(p.eggs) ~= nil or (p.counters.eggsObtained or 0) > 0
	elseif def.requiresUnlock == "HasChest" then
		return next(p.chests) ~= nil or (p.counters.chestsObtained or 0) > 0
	end
	return true
end

local function slotFor(def: Quests.QuestDef): Types.QuestSlot
	return { questId = def.id, progress = 0, target = def.target, coins = def.coins, claimed = false }
end

-- Elige los diarios del día: uno por dificultad, sin repetir, determinista.
local function pickDaily(p: Profile, day: number): { Types.QuestSlot }
	local rng = Rng.new(p.userId * 7919 + day * 104729 + 17)
	local out = {}
	for _, difficulty in ipairs(Quests.DailyMix) do
		local options = {}
		for _, def in ipairs(Quests.Daily) do
			if def.difficulty == difficulty and eligible(p, def) then
				table.insert(options, def)
			end
		end
		if #options > 0 then
			table.insert(out, slotFor(options[rng:int(1, #options)]))
		end
	end
	return out
end

local function pickWeekly(p: Profile, week: number): Types.QuestSlot?
	local rng = Rng.new(p.userId * 3571 + week * 6151 + 29)
	local options = {}
	for _, def in ipairs(Quests.Weekly) do
		if eligible(p, def) then
			table.insert(options, def)
		end
	end
	if #options == 0 then
		return nil
	end
	return slotFor(options[rng:int(1, #options)])
end

-- Rotación: se llama al cargar y antes de usar el tablón. Devuelve si cambió algo.
function QuestRules.refresh(p: Profile, now: number): boolean
	local changed = false
	local day, week = QuestRules.dayIndex(now), QuestRules.weekIndex(now)
	if p.quests.day ~= day then
		p.quests.day = day
		p.quests.daily = pickDaily(p, day)
		p.quests.dailyBonusClaimed = false
		changed = true
	end
	if p.quests.week ~= week then
		p.quests.week = week
		p.quests.weekly = pickWeekly(p, week)
		changed = true
	end
	return changed
end

function QuestRules.def(questId: string): Quests.QuestDef?
	for _, d in ipairs(Quests.Daily) do
		if d.id == questId then
			return d
		end
	end
	for _, d in ipairs(Quests.Weekly) do
		if d.id == questId then
			return d
		end
	end
	return nil
end

-- Suma progreso por un evento interno. Devuelve los encargos que se completaron ahora.
function QuestRules.track(p: Profile, event: string, amount: number, now: number): { string }
	QuestRules.refresh(p, now)
	local completed = {}
	local function bump(slot: Types.QuestSlot?)
		if not slot or slot.claimed then
			return
		end
		local def = QuestRules.def(slot.questId)
		if not def or def.event ~= event or slot.progress >= slot.target then
			return
		end
		slot.progress = math.min(slot.target, slot.progress + amount)
		if slot.progress >= slot.target then
			table.insert(completed, slot.questId)
		end
	end
	for _, slot in ipairs(p.quests.daily) do
		bump(slot)
	end
	bump(p.quests.weekly)
	return completed
end

-- kind: "Daily" (index 1..3) | "Weekly"
function QuestRules.claim(p: Profile, kind: string, index: number, now: number): Result.Result
	QuestRules.refresh(p, now)
	local slot: Types.QuestSlot? = if kind == "Weekly" then p.quests.weekly else p.quests.daily[index]
	if not slot then
		return Result.fail("UnknownQuest")
	end
	if slot.claimed then
		return Result.fail("AlreadyClaimed")
	end
	if slot.progress < slot.target then
		return Result.fail("QuestNotComplete")
	end
	-- Cofres primero (pueden fallar por espacio): así nada se cobra a medias
	local chestType: string? = nil
	if kind == "Weekly" then
		chestType = Quests.WeeklyChest
	else
		local others = 0
		for i, s in ipairs(p.quests.daily) do
			if i ~= index and s.claimed then
				others += 1
			end
		end
		if others == #p.quests.daily - 1 and not p.quests.dailyBonusClaimed then
			chestType = Quests.DailyBonusChest
		end
	end
	local chestId: string? = nil
	if chestType then
		local g = ChestRules.grant(p, chestType, { kind = "Quest", ref = slot.questId, at = now }, now)
		if not g.ok then
			return g
		end
		chestId = (g.data :: any).chestId
		if kind ~= "Weekly" then
			p.quests.dailyBonusClaimed = true
		end
	end
	slot.claimed = true
	p.currencies.Monedas = (p.currencies.Monedas or 0) + slot.coins
	HistoryRules.add(p, {
		kind = "Quest",
		ref = slot.questId,
		detail = string.format("%d Monedas", slot.coins),
		at = now,
		source = kind,
	})
	return Result.ok({ questId = slot.questId, coins = slot.coins, chestId = chestId, chestType = chestType })
end

return QuestRules
