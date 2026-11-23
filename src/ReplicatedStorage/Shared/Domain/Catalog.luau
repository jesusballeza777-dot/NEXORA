--!strict
-- Catálogo maestro (Genesis F2 §6.1): una ficha completa por especie, reuniendo en un
-- solo punto Config/Species (tabla maestra), Config/SpeciesLore (fichas de la Biblia),
-- Config/Abilities (repertorio por elemento), Config/Visuals (arte) y las fuentes de la
-- beta (cofres, rescates, Acto I). Lógica pura y de solo lectura: ninguna especie es un
-- script propio. Lo que la Biblia no documenta aparece como "Pendiente".

local Config = script.Parent.Parent.Config
local Species = require(Config.Species)
local SpeciesLore = require(Config.SpeciesLore)
local Abilities = require(Config.Abilities)
local Talents = require(Config.Talents)
local Rarities = require(Config.Rarities)
local Visuals = require(Config.Visuals)
local Chests = require(Config.Chests)
local Encounters = require(Config.Encounters)
local Onboarding = require(Config.Onboarding)

local Catalog = {}

export type Entry = {
	speciesId: string,
	number: number,
	broteName: string,
	talladoName: string,
	rarity: string,
	elements: { string },
	role: string,
	family: string,
	biome: string,
	stats: { [string]: number },
	statBudget: number,
	basics: { string },
	specials: { string },
	nexo: string,
	talent: string,
	signature: string,
	description: string,
	mythicMix: string,
	anatomy: string,
	distinctiveTrait: string,
	assetRef: string,
	artStatus: string,
	availability: { string },
	playableInBeta: boolean,
}

local PENDING = "Pendiente"

-- Fuentes de la beta por especie (cofres, rescates, enemigos, iniciales)
local sources: { [string]: { string } } = {}
local function addSource(id: string, text: string)
	sources[id] = sources[id] or {}
	if not table.find(sources[id], text) then
		table.insert(sources[id], text)
	end
end
for _, egg in ipairs(Onboarding.StarterEggs) do
	addSource(egg.speciesId, "Inicial (huevo de copal)")
end
for rarity, pool in pairs(Chests.EggPools) do
	for _, id in ipairs(pool) do
		addSource(id, "Huevo de cofre (" .. Rarities.ById[rarity].name .. ")")
	end
end
for _, encId in ipairs(Encounters.Order) do
	local enc = Encounters.ById[encId]
	if enc.rescue then
		addSource(enc.rescue.speciesId, "Rescate del Acto I (10 % de huevo)")
	end
	for _, opp in ipairs(enc.opponents) do
		if opp.speciesId and Species.ById[opp.speciesId] then
			addSource(opp.speciesId, "Opaco del Acto I")
		end
		for _, sp in pairs(opp.byStarterElement or {}) do
			addSource(sp, "Opaco del Acto I")
		end
	end
end

local function names(ids: { string }): { string }
	local out = {}
	for _, id in ipairs(ids) do
		local m = Abilities.ById[id]
		table.insert(out, if m then m.name else id)
	end
	return out
end

function Catalog.entry(speciesId: string): Entry
	local sp = Species.ById[speciesId]
	assert(sp, "Especie desconocida: " .. speciesId)
	local lore = SpeciesLore.ById[speciesId]
	local rarity = Rarities.ById[sp.rarity]
	local basics, specials = {}, {}
	local nexo = PENDING
	for i, element in ipairs(sp.elements) do
		local rep = Abilities.ByElement[element]
		if rep then
			for _, id in ipairs(rep.basics) do
				table.insert(basics, id)
			end
			for _, id in ipairs(rep.specials) do
				table.insert(specials, id)
			end
			if i == 1 then
				nexo = Abilities.ById[rep.nexo].name
			end
		end
	end
	-- Sin elementos fijos (Nexum, Misterio): el repertorio no está documentado
	if #basics == 0 then
		table.insert(basics, PENDING)
	end
	if #specials == 0 then
		table.insert(specials, PENDING)
	end
	local talent = if sp.talent and Talents.ById[sp.talent]
		then Talents.ById[sp.talent].name
		elseif lore and lore.talentText ~= "" then lore.talentText
		else PENDING
	local signature = if sp.signature and Abilities.ById[sp.signature]
		then Abilities.ById[sp.signature].name
		elseif lore and lore.signatureText ~= "" then lore.signatureText
		else PENDING
	local vis = Visuals.ById[speciesId]
	local artStatus = if not vis
		then "Sin modelo: silueta en el Álbum"
		elseif
			string.find(vis.signatureFeature, "prestado", 1, true)
		then "Blockout provisional (arquetipo prestado), no aprobado"
		else "Blockout procedural, pendiente de aprobación"
	local available = sources[speciesId] or {}
	return {
		speciesId = speciesId,
		number = sp.number,
		broteName = sp.broteName,
		talladoName = sp.talladoName,
		rarity = sp.rarity,
		elements = table.clone(sp.elements),
		role = sp.role,
		family = sp.family,
		biome = sp.biome,
		stats = table.clone(sp.stats) :: any,
		statBudget = rarity.statBudget,
		basics = if basics[1] == PENDING then basics else names(basics),
		specials = if specials[1] == PENDING then specials else names(specials),
		nexo = nexo,
		talent = talent,
		signature = signature,
		description = if lore then lore.concept else PENDING,
		mythicMix = if lore then lore.mythicMix else PENDING,
		anatomy = if lore then lore.anatomy else PENDING,
		distinctiveTrait = if lore then lore.distinctiveTrait else PENDING,
		assetRef = if vis then "Config/Visuals · arquetipo " .. vis.archetype else PENDING,
		artStatus = artStatus,
		availability = if #available > 0
			then table.clone(available)
			else { "Bloqueada en la beta (sin arte aprobado)" },
		playableInBeta = vis ~= nil and #available > 0,
	}
end

function Catalog.all(): { Entry }
	local out = {}
	for _, id in ipairs(Species.Order) do
		table.insert(out, Catalog.entry(id))
	end
	return out
end

return Catalog
