--!strict
-- Álbum del Nexo y Bestiario (Biblia compacta p. 25 y 114).
-- * Cada especie tiene dos cartas: Brote y Tallado. Las no descubiertas se muestran como
--   silueta oscura con su número.
-- * El Bestiario revela información por niveles:
--     0 desconocida · 1 vista (Opaco o en el mundo) · 2 restaurada u obtenida
--     3 Tallado obtenido (lore completo).
-- * Completar un bioma da un marco especial (p. 25).
-- Todas las marcas son timestamps del servidor y nunca se borran.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local SpeciesConfig = require(Shared.Config.Species)
local Types = require(Shared.Types)

type Profile = Types.Profile

local CollectionRules = {}

local function entry(p: Profile, speciesId: string): Types.CollectionEntry
	local e = p.collection[speciesId]
	if not e then
		e = {}
		p.collection[speciesId] = e
	end
	return e
end

local function isDiscovered(e: Types.CollectionEntry?): boolean
	return e ~= nil and (e.seenAt ~= nil or e.restoredAt ~= nil or e.broteAt ~= nil or e.talladoAt ~= nil)
end

CollectionRules.isDiscovered = isDiscovered

-- Devuelve true si es la primera vez que se descubre la especie.
function CollectionRules.see(p: Profile, speciesId: string, now: number): boolean
	if not SpeciesConfig.ById[speciesId] then
		return false
	end
	local before = isDiscovered(p.collection[speciesId])
	local e = entry(p, speciesId)
	e.seenAt = e.seenAt or now
	return not before
end

function CollectionRules.restore(p: Profile, speciesId: string, now: number): boolean
	if not SpeciesConfig.ById[speciesId] then
		return false
	end
	local before = isDiscovered(p.collection[speciesId])
	local e = entry(p, speciesId)
	e.seenAt = e.seenAt or now
	e.restoredAt = e.restoredAt or now
	return not before
end

-- Obtener un ejemplar (eclosión, inicial, rescate…) o tallarlo: registra la carta.
-- Devuelve { newSpecies, newCard }.
function CollectionRules.obtain(p: Profile, speciesId: string, form: string, now: number, countIt: boolean?)
	local before = isDiscovered(p.collection[speciesId])
	local e = entry(p, speciesId)
	local newCard = false
	if form == "Tallado" then
		newCard = e.talladoAt == nil
		e.talladoAt = e.talladoAt or now
	else
		newCard = e.broteAt == nil
		e.broteAt = e.broteAt or now
	end
	if countIt ~= false and form ~= "Tallado" then
		e.count = (e.count or 0) + 1
	end
	return { newSpecies = not before, newCard = newCard }
end

function CollectionRules.bestiaryTier(e: Types.CollectionEntry?): number
	if not e then
		return 0
	end
	if e.talladoAt then
		return 3
	end
	if e.restoredAt or e.broteAt then
		return 2
	end
	if e.seenAt then
		return 1
	end
	return 0
end

export type BiomeProgress = { biome: string, discovered: number, cards: number, total: number, complete: boolean }

-- Progreso global y por bioma: especies descubiertas y cartas (Brote + Tallado).
function CollectionRules.progress(p: Profile)
	local byBiome: { [string]: BiomeProgress } = {}
	local discovered, cards, total = 0, 0, 0
	for _, id in ipairs(SpeciesConfig.Order) do
		local sp = SpeciesConfig.ById[id]
		local b = byBiome[sp.biome]
		if not b then
			b = { biome = sp.biome, discovered = 0, cards = 0, total = 0, complete = false }
			byBiome[sp.biome] = b
		end
		total += 1
		b.total += 1
		local e = p.collection[id]
		if isDiscovered(e) then
			discovered += 1
			b.discovered += 1
		end
		if e and e.broteAt then
			cards += 1
			b.cards += 1
		end
		if e and e.talladoAt then
			cards += 1
			b.cards += 1
		end
	end
	for _, b in pairs(byBiome) do
		b.complete = b.cards >= b.total * 2
	end
	return { discovered = discovered, cards = cards, totalSpecies = total, totalCards = total * 2, byBiome = byBiome }
end

return CollectionRules
