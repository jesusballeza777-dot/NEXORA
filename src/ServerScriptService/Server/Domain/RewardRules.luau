--!strict
-- Sistema de recompensas reutilizable.
-- Flujo: create (pendiente, persistida) → claim (aplicada una sola vez).
-- * Idempotente: el mismo rewardId nunca se concede dos veces (pending + ledger).
-- * Procedencia: cada recompensa guarda source = {kind, ref, battleId}.
-- * Una recompensa pendiente sobrevive a desconexiones: se reclama al volver.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local RewardsConfig = require(Shared.Config.Rewards)
local Types = require(Shared.Types)
local Chests = require(Shared.Config.Chests)
local Decor = require(Shared.Config.Decor)
local SpeciesConfig = require(Shared.Config.Species)
local Result = require(script.Parent.Result)
local PetRules = require(script.Parent.PetRules)
local ChestRules = require(script.Parent.ChestRules)
local EggRules = require(script.Parent.EggRules)
local DecorRules = require(script.Parent.DecorRules)

type Profile = Types.Profile
type PendingReward = Types.PendingReward

local RewardRules = {}

RewardRules.LEDGER_LIMIT = 500

export type RewardSpec = {
	bundleId: string?,
	title: string?,
	currencies: { [string]: number }?,
	items: { [string]: number }?,
	petXp: number?,
	petIds: { string }?,
	unlocks: { string }?,
	chests: { string }?,
	eggs: { string }?,
	decor: { string }?,
	titles: { string }?,
	frames: { string }?,
}

local function addInto(dst: { [string]: number }, src: { [string]: number }?)
	if src then
		for k, v in pairs(src) do
			dst[k] = (dst[k] or 0) + v
		end
	end
end

function RewardRules.isKnown(p: Profile, rewardId: string): boolean
	return p.rewards.pending[rewardId] ~= nil or p.rewards.ledger[rewardId] ~= nil
end

function RewardRules.create(
	p: Profile,
	rewardId: string,
	spec: RewardSpec,
	source: { kind: string, ref: string, battleId: string? },
	now: number
): Result.Result
	if RewardRules.isKnown(p, rewardId) then
		return { ok = true, err = nil, data = { rewardId = rewardId, duplicate = true } }
	end
	local currencies, items = {}, {}
	local unlocks: { string } = {}
	local title = spec.title
	if spec.bundleId then
		local bundle = RewardsConfig.ById[spec.bundleId]
		if not bundle then
			return Result.fail("UnknownBundle")
		end
		addInto(currencies, bundle.currencies)
		addInto(items, bundle.items)
		for _, u in ipairs(bundle.unlocks or {}) do
			table.insert(unlocks, u)
		end
		title = title or bundle.title
	end
	addInto(currencies, spec.currencies)
	addInto(items, spec.items)
	for _, u in ipairs(spec.unlocks or {}) do
		table.insert(unlocks, u)
	end
	for cur, v in pairs(currencies) do
		if not Economy.Currencies[cur] or v < 0 or math.floor(v) ~= v then
			return Result.fail("BadRewardCurrency")
		end
	end
	for item, v in pairs(items) do
		if not Economy.Foods[item] or v < 0 or math.floor(v) ~= v then
			return Result.fail("BadRewardItem")
		end
	end
	for _, c in ipairs(spec.chests or {}) do
		if not Chests.ById[c] then
			return Result.fail("BadRewardChest")
		end
	end
	for _, sp in ipairs(spec.eggs or {}) do
		if not SpeciesConfig.ById[sp] then
			return Result.fail("BadRewardEgg")
		end
	end
	for _, d in ipairs(spec.decor or {}) do
		if not Decor.ById[d] then
			return Result.fail("BadRewardDecor")
		end
	end
	local reward: PendingReward = {
		id = rewardId,
		bundleId = spec.bundleId,
		title = title or "Recompensa",
		currencies = currencies,
		items = items,
		petXp = math.max(0, math.floor(spec.petXp or 0)),
		petIds = spec.petIds or {},
		unlocks = unlocks,
		source = source,
		createdAt = now,
		chests = if spec.chests and #spec.chests > 0 then table.clone(spec.chests) else nil,
		eggs = if spec.eggs and #spec.eggs > 0 then table.clone(spec.eggs) else nil,
		decor = if spec.decor and #spec.decor > 0 then table.clone(spec.decor) else nil,
		titles = if spec.titles and #spec.titles > 0 then table.clone(spec.titles) else nil,
		frames = if spec.frames and #spec.frames > 0 then table.clone(spec.frames) else nil,
	}
	p.rewards.pending[rewardId] = reward
	return Result.ok({ rewardId = rewardId, reward = reward })
end

local function remember(p: Profile, rewardId: string, now: number)
	p.rewards.ledger[rewardId] = now
	table.insert(p.rewards.ledgerOrder, rewardId)
	while #p.rewards.ledgerOrder > RewardRules.LEDGER_LIMIT do
		local old = table.remove(p.rewards.ledgerOrder, 1) :: string
		p.rewards.ledger[old] = nil
	end
end

function RewardRules.claim(p: Profile, rewardId: string, ctx: PetRules.Ctx): Result.Result
	if p.rewards.ledger[rewardId] then
		return Result.fail("AlreadyClaimed")
	end
	local r = p.rewards.pending[rewardId]
	if not r then
		return Result.fail("UnknownReward")
	end
	-- Comprobar espacio ANTES de aplicar nada: o se entrega todo o queda pendiente
	local eggs = r.eggs or {}
	local chests = r.chests or {}
	if #eggs > 0 and not EggRules.hasRoom(p, #eggs) then
		return Result.fail("EggStorageFull")
	end
	if ChestRules.count(p) + #chests > Chests.MaxStoredChests then
		return Result.fail("ChestStorageFull")
	end
	for cur, v in pairs(r.currencies) do
		p.currencies[cur] = math.min((Economy.MaxBalance :: any)[cur] or math.huge, (p.currencies[cur] or 0) + v)
	end
	for item, v in pairs(r.items) do
		p.items[item] = math.min(Economy.MaxItemStack, (p.items[item] or 0) + v)
	end
	local petResults = {}
	if r.petXp > 0 then
		for _, petId in ipairs(r.petIds) do
			local pet = p.pets[petId]
			if pet then
				petResults[petId] = PetRules.addXp(pet, r.petXp, ctx)
			end
		end
	end
	local newUnlocks = {}
	for _, u in ipairs(r.unlocks) do
		if not p.unlocks[u] then
			p.unlocks[u] = ctx.now
			table.insert(newUnlocks, u)
		end
	end
	local chestIds = {}
	for _, chestType in ipairs(chests) do
		local g = ChestRules.grant(p, chestType, { kind = "Reward", ref = rewardId, at = ctx.now }, ctx.now)
		if g.ok then
			table.insert(chestIds, (g.data :: any).chestId)
		end
	end
	local eggIds = {}
	for _, speciesId in ipairs(eggs) do
		local g = EggRules.grant(p, speciesId, { kind = "Rescue", ref = rewardId, at = ctx.now }, ctx.now)
		if g.ok then
			table.insert(eggIds, (g.data :: any).eggId)
		end
	end
	for _, d in ipairs(r.decor or {}) do
		DecorRules.grant(p, d, 1)
	end
	for _, t in ipairs(r.titles or {}) do
		p.titles.owned[t] = p.titles.owned[t] or ctx.now
	end
	for _, f in ipairs(r.frames or {}) do
		p.frames.owned[f] = p.frames.owned[f] or ctx.now
	end
	p.rewards.pending[rewardId] = nil
	remember(p, rewardId, ctx.now)
	return Result.ok({
		rewardId = rewardId,
		reward = r,
		pets = petResults,
		newUnlocks = newUnlocks,
		chestIds = chestIds,
		eggIds = eggIds,
	})
end

-- Conceder y reclamar en un paso (regalos que no requieren pantalla de reclamo).
function RewardRules.grant(
	p: Profile,
	rewardId: string,
	spec: RewardSpec,
	source: { kind: string, ref: string, battleId: string? },
	ctx: PetRules.Ctx
): Result.Result
	local created = RewardRules.create(p, rewardId, spec, source, ctx.now)
	if not created.ok then
		return created
	end
	if created.data and created.data.duplicate then
		return Result.fail("AlreadyGranted")
	end
	return RewardRules.claim(p, rewardId, ctx)
end

return RewardRules
