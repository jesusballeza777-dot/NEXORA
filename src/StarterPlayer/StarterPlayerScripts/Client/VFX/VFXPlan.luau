--!strict
-- Reglas PURAS de presentación (sin APIs de motor): qué efectos tocan según rareza, forma,
-- calidad, distancia, combate y opacado; qué secuencia usa cada jugada y cuánto dura cada
-- fase; qué impacto corresponde a cada evento del servidor. Los controladores de
-- Client/VFX solo aplican lo que decide este módulo (y las pruebas lo verifican sin Studio).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local VFXPlan = {}

export type AuraEmitter = {
	style: string, -- id de VFX.Styles
	layer: number, -- posición en la lista de la rareza
	rate: number, -- multiplicador de la tasa (el emisor nunca pasa de 20/s)
	burst: number, -- multiplicador de los brotes por pulso
	size: number, -- multiplicador del tamaño
	brightness: number, -- multiplicador del brillo (combate: 60 %)
}

export type AuraPlan = {
	key: string, -- cambia solo cuando hay que rehacer el aura
	lod: string,
	emitters: { AuraEmitter },
	rim: boolean, -- luz de contorno (Highlight) activa
	beam: any?, -- haz del Legendario
	halo: any?, -- halo del Único
	glowPulse: boolean, -- emisivo animado (Épico+)
	brightness: number,
	size: number,
}

export type AuraContext = {
	quality: string?,
	battle: boolean?,
	attacking: boolean?,
	opaco: boolean?,
	lod: string?,
	element: string?,
}

function VFXPlan.quality(q: string?): any
	return (VFX.Quality :: any)[q or VFX.DefaultQuality] or (VFX.Quality :: any)[VFX.DefaultQuality]
end

-- Perfil del elemento (Eco si el ataque no tiene elemento o el id no existe)
function VFXPlan.profile(elementId: string?): any
	return if elementId then (VFX.Elements :: any)[elementId] or VFX.Neutral else VFX.Neutral
end

-- "$element:N" → N-ésimo estilo del aura del elemento; cualquier otro texto es un id fijo.
function VFXPlan.resolveLayer(layer: string, elementId: string?): string
	local n = string.match(layer, "^%$element:(%d+)$")
	if n then
		local aura = VFXPlan.profile(elementId).aura
		return aura[math.clamp(tonumber(n) :: number, 1, #aura)]
	end
	return layer
end

function VFXPlan.clampRate(rate: number): number
	return math.clamp(rate, 0, VFX.Budget.maxRatePerEmitter)
end

-- Nivel de detalle por distancia a la cámara, con histéresis para no parpadear en el borde.
local function tierFor(d: number, full: number, reduced: number): string
	return if d <= full then "Full" elseif d <= reduced then "Reduced" else "None"
end
function VFXPlan.lod(distance: number, previous: string?): string
	local L = VFX.LOD
	local h = L.hysteresis
	if previous == "Full" then
		return tierFor(distance, L.full + h, L.reduced + h)
	elseif previous == "Reduced" then
		if distance < L.full - h then
			return "Full"
		elseif distance > L.reduced + h then
			return "None"
		end
		return "Reduced"
	elseif previous == "None" then
		return tierFor(distance, L.full - h, L.reduced - h)
	end
	return tierFor(distance, L.full, L.reduced)
end

-- Presupuesto del aura (p. 26 y 120; Genesis §6 y §9).
function VFXPlan.aura(rarityId: string?, form: string, ctx: AuraContext?): AuraPlan
	local c: AuraContext = ctx or {}
	local qualityId = c.quality or VFX.DefaultQuality
	local q = VFXPlan.quality(qualityId)
	local lod = c.lod or "Full"
	local B = VFX.Budget
	local rp = if rarityId then (VFX.Rarities :: any)[rarityId] else nil
	local brote = form ~= "Tallado"
	local size = if brote then B.broteSize else 1
	local brightness = if c.battle then B.battleIntensity else 1
	local plan: AuraPlan = {
		key = "",
		lod = lod,
		emitters = {},
		rim = false,
		beam = nil,
		halo = nil,
		glowPulse = false,
		brightness = brightness,
		size = size,
	}
	local visible = rp ~= nil and not c.opaco and lod == "Full"
	if visible then
		local count = rp.emitters[qualityId] or rp.emitters[VFX.DefaultQuality]
		if brote then
			count = math.min(count, B.broteMaxEmitters)
		end
		if rp.attackOnly and not c.attacking then
			count = 0
		end
		local rate = q.rate * (if brote then B.broteRate else 1) * brightness
		local burst = q.burst * (if brote then B.broteRate else 1) * brightness
		for i = 1, math.min(count, #rp.layers) do
			table.insert(plan.emitters, {
				style = VFXPlan.resolveLayer(rp.layers[i], c.element),
				layer = i,
				rate = rate,
				burst = burst,
				size = size,
				brightness = brightness,
			})
		end
		plan.rim = rp.rim ~= nil and c.attacking == true and q.highlights
		plan.beam = if rp.beam and not brote and q.beams then rp.beam else nil
		plan.halo = if rp.halo and not brote and q.beams then rp.halo else nil
		plan.glowPulse = rp.glowPulse == true
	end
	local styles = {}
	for _, e in ipairs(plan.emitters) do
		table.insert(styles, e.style)
	end
	plan.key = table.concat({
		rarityId or "-",
		form,
		qualityId,
		lod,
		if c.battle then "B" else "W",
		if c.attacking then "A" else "-",
		if c.opaco then "O" else "-",
		table.concat(styles, ","),
	}, "|")
	return plan
end

-- ======================================================================
-- Secuencias de ataque
-- ======================================================================
local GUARD = { Shield = true, ShieldFromDamage = true, Block = true, Reflect = true, Dodge = true }
local HEAL = { Heal = true, HealOverTime = true }

function VFXPlan.sequenceKind(move: any): string
	if move.kind == "Nexo" then
		return "Nexo"
	end
	if (move.power or 0) > 0 then
		return if move.kind == "Basic" then "Basic" else "Special"
	end
	for _, e in ipairs(move.effects or {}) do
		if HEAL[e.type] then
			return "Heal"
		end
	end
	for _, e in ipairs(move.effects or {}) do
		if GUARD[e.type] then
			return "Shield"
		end
	end
	return "Status"
end

export type PhaseSlot = { id: string, start: number, duration: number }
export type Timeline = {
	kind: string,
	phases: { PhaseSlot },
	total: number,
	hitAt: number,
	limit: number,
	skippable: boolean,
}

-- fast = modo «combate rápido» de los ajustes (todas las fases al 60 %).
function VFXPlan.timeline(kind: string, opts: { fast: boolean? }?): Timeline
	local seq = (VFX.Sequences :: any)[kind] or VFX.Sequences.Basic
	local speed = if opts and opts.fast then 0.6 else 1
	local phases: { PhaseSlot } = {}
	local t = 0
	local hitAt = 0
	for _, id in ipairs(VFX.PhaseOrder) do
		local d = (seq.phases[id] or 0) * speed
		table.insert(phases, { id = id, start = t, duration = d })
		if id == "Impact" then
			hitAt = t
		end
		t += d
	end
	return {
		kind = seq.id,
		phases = phases,
		total = t,
		hitAt = hitAt,
		limit = if seq.id == "Nexo" then VFX.Budget.nexoMaxSeconds else VFX.Budget.attackMaxSeconds,
		skippable = true, -- todo se puede saltar (el Golpe Nexo también)
	}
end

-- Fase activa en el instante t (nil antes de empezar; "Done" al terminar).
function VFXPlan.phaseAt(tl: Timeline, t: number): (string?, number)
	if t < 0 then
		return nil, 0
	end
	for _, p in ipairs(tl.phases) do
		if t < p.start + p.duration then
			return p.id, if p.duration > 0 then (t - p.start) / p.duration else 1
		end
	end
	return "Done", 1
end

-- ======================================================================
-- Impactos por evento del servidor (los eventos no cambian: solo se leen)
-- ======================================================================
local STATUS_IMPACT = { Burn = "Burn", Paralysis = "Paralyze", Stun = "Stun", Sleep = "Stun", Confuse = "Stun" }

function VFXPlan.impactsFor(e: any, move: any?): { string }
	local t = e.t
	if t == "Damage" then
		local base = if move and move.element and not move.contact then "Elemental" else "Physical"
		if e.crit then
			return { base, "Crit" }
		end
		return { base }
	elseif t == "ShieldAbsorb" or t == "Block" or t == "Shield" then
		return { "Shield" }
	elseif t == "Guard" then
		return { if e.kind == "Reflect" then "Reflect" else "Shield" }
	elseif t == "Heal" or t == "Regen" or t == "Roots" then
		return { "Heal" }
	elseif t == "Status" then
		local id = STATUS_IMPACT[e.status]
		return if id then { id } else {}
	elseif t == "StatusTick" then
		return { STATUS_IMPACT[e.status or "Burn"] or "Burn" }
	elseif t == "Reflect" then
		return { "Reflect" }
	elseif t == "Skip" then
		return { "Stun" }
	elseif t == "Restored" then
		return { "Victory" }
	end
	return {}
end

-- Eventos que pertenecen a la jugada que empieza en events[i] (hasta la siguiente "Move")
function VFXPlan.moveGroup(events: { any }, i: number): { any }
	local group = {}
	for k = i + 1, #events do
		local e = events[k]
		if e.t == "Move" then
			break
		end
		table.insert(group, e)
	end
	return group
end

return VFXPlan
