--!strict
-- Cofres: catálogo, validación de tablas, obtención con contenido fijado al obtenerlo y
-- apertura idempotente (Genesis F2 §9).
-- * grant: el contenido (incluida la especie del huevo) se decide AL OBTENER el cofre y se
--   guarda en el perfil. Abrir solo entrega lo guardado: reconectar o repetir la
--   solicitud no cambia nada ni duplica.
-- * open: borra el cofre y entrega su contenido en una sola operación; si no cabe un
--   huevo, no se abre (nada se pierde).
-- * Modo aleatorio: solo con tabla completa (100 %), sin huecos ni duplicados y aprobada.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Chests = require(Shared.Config.Chests)
local Economy = require(Shared.Config.Economy)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)
local EggRules = require(script.Parent.EggRules)
local HistoryRules = require(script.Parent.HistoryRules)

type Profile = Types.Profile

local ChestRules = {}

export type TableReport = { ok: boolean, total: number, issues: { string } }

-- Valida una tabla de probabilidades del premio principal.
function ChestRules.validateTable(rows: { Chests.OddsRow }): TableReport
	local issues = {}
	local total = 0
	local seen: { [string]: boolean } = {}
	for _, row in ipairs(rows) do
		if seen[row.prize] then
			table.insert(issues, "Premio duplicado: " .. row.prize)
		end
		seen[row.prize] = true
		if row.percent == nil then
			table.insert(issues, "Porcentaje faltante: " .. row.prize)
		elseif row.percent < 0 then
			table.insert(issues, "Porcentaje negativo: " .. row.prize)
		else
			total += row.percent :: number
		end
		if row.status ~= "Biblia" then
			table.insert(issues, "Dato no aprobado (" .. row.status .. "): " .. row.prize)
		end
	end
	if math.abs(total - 100) > 1e-9 then
		table.insert(issues, string.format("La tabla suma %.2f %%, no 100 %%", total))
	end
	return { ok = #issues == 0, total = total, issues = issues }
end

function ChestRules.canUseRandom(chestType: string): boolean
	local def = Chests.ById[chestType]
	return def ~= nil and def.approved and ChestRules.validateTable(def.bibleTable).ok
end

-- Especie del huevo de un grupo: la primera que el jugador aún no tiene ni espera (en
-- huevos o cofres guardados); si las tiene todas, la que menos copias tiene.
local function pickFromPool(p: Profile, pool: { string }, reserved: { [string]: boolean }): string
	local pending: { [string]: number } = {}
	for _, egg in pairs(p.eggs) do
		pending[egg.speciesId] = (pending[egg.speciesId] or 0) + 1
	end
	for _, chest in pairs(p.chests) do
		for _, e in ipairs(chest.contents.eggs) do
			pending[e.speciesId] = (pending[e.speciesId] or 0) + 1
		end
	end
	for _, id in ipairs(pool) do
		local e = p.collection[id]
		local owned = e ~= nil and e.broteAt ~= nil
		if not owned and not pending[id] and not reserved[id] then
			return id
		end
	end
	local best, bestCount = pool[1], math.huge
	for _, id in ipairs(pool) do
		local e = p.collection[id]
		local n = ((e and e.count) or 0) + (pending[id] or 0) + (if reserved[id] then 1 else 0)
		if n < bestCount then
			best, bestCount = id, n
		end
	end
	return best
end

-- Contenido que mostraría el cofre ahora mismo para este jugador (vista previa honesta).
function ChestRules.contentsFor(p: Profile, chestType: string)
	local def = Chests.ById[chestType]
	assert(def and def.fixed, "Cofre sin contenido fijo: " .. chestType)
	local fixed = def.fixed :: any
	local eggs = {}
	local reserved: { [string]: boolean } = {}
	for _, egg in ipairs(fixed.eggs) do
		local pool = (Chests.EggPools :: any)[egg.pool]
		local speciesId = pickFromPool(p, pool, reserved)
		reserved[speciesId] = true
		table.insert(eggs, { speciesId = speciesId })
	end
	return {
		currencies = table.clone(fixed.currencies),
		items = table.clone(fixed.items),
		eggs = eggs,
		codex = if fixed.codex then table.clone(fixed.codex) else nil,
	}
end

function ChestRules.count(p: Profile): number
	local n = 0
	for _ in pairs(p.chests) do
		n += 1
	end
	return n
end

function ChestRules.grant(p: Profile, chestType: string, source: Types.AcquisitionSource, now: number): Result.Result
	local def = Chests.ById[chestType]
	if not def then
		return Result.fail("UnknownChest")
	end
	if not def.activeInBeta then
		return Result.fail("ChestNotActive")
	end
	if def.mode ~= "Fixed" then
		return Result.fail("RandomChestsDisabled") -- sin tabla completa y aprobada no hay azar
	end
	if ChestRules.count(p) >= Chests.MaxStoredChests then
		return Result.fail("ChestStorageFull")
	end
	local id = string.format("C%d-%d", p.userId, p.nextChestSerial)
	p.nextChestSerial += 1
	p.counters.chestsObtained = (p.counters.chestsObtained or 0) + 1
	local contents = ChestRules.contentsFor(p, chestType)
	p.chests[id] = {
		id = id,
		chestType = chestType,
		contents = { currencies = contents.currencies, items = contents.items, eggs = contents.eggs },
		source = source,
		obtainedAt = now,
	}
	(p.chests[id] :: any).codex = contents.codex
	HistoryRules.add(p, { kind = "Chest", ref = id, rarity = chestType, at = now, source = source.kind })
	return Result.ok({ chestId = id, chestType = chestType })
end

function ChestRules.open(p: Profile, chestId: string, now: number): Result.Result
	local chest = p.chests[chestId]
	if not chest then
		return Result.fail("ChestNotFound")
	end
	local contents = chest.contents
	if not EggRules.hasRoom(p, #contents.eggs) then
		return Result.fail("EggStorageFull")
	end
	-- Se borra primero: aunque algo falle después, el cofre nunca se abre dos veces
	p.chests[chestId] = nil
	for cur, v in pairs(contents.currencies) do
		p.currencies[cur] = math.min((Economy.MaxBalance :: any)[cur] or math.huge, (p.currencies[cur] or 0) + v)
	end
	for item, v in pairs(contents.items) do
		p.items[item] = math.min(Economy.MaxItemStack, (p.items[item] or 0) + v)
	end
	local eggIds = {}
	for _, e in ipairs(contents.eggs) do
		local g = EggRules.grant(p, e.speciesId, { kind = "Chest", ref = chestId, at = now }, now)
		if g.ok then
			table.insert(eggIds, (g.data :: any).eggId)
		end
	end
	local codex = (chest :: any).codex or {}
	for _, entryId in ipairs(codex) do
		p.codex[entryId] = p.codex[entryId] or now
	end
	HistoryRules.add(p, {
		kind = "ChestOpened",
		ref = chestId,
		rarity = chest.chestType,
		detail = string.format("%d Monedas, %d huevos", contents.currencies.Monedas or 0, #eggIds),
		at = now,
		source = chest.source.kind,
	})
	return Result.ok({
		chestId = chestId,
		chestType = chest.chestType,
		currencies = contents.currencies,
		items = contents.items,
		eggIds = eggIds,
		eggs = contents.eggs,
		codex = codex,
	})
end

-- Lo que se enseña ANTES de abrir: contenido exacto o tabla con porcentajes (p. 13).
function ChestRules.odds(p: Profile, chestId: string)
	local chest = p.chests[chestId]
	if not chest then
		return nil
	end
	local def = Chests.ById[chest.chestType]
	return {
		mode = def.mode,
		contents = chest.contents,
		note = if def.mode == "Fixed"
			then "Contenido fijo: 100 % — lo que ves es lo que te llevas."
			else "Probabilidades visibles antes de abrir.",
		bibleTable = def.bibleTable,
	}
end

return ChestRules
