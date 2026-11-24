--!strict
-- Capas de rareza que no son partículas (Biblia p. 26 y 120: Aura = ParticleEmitter +
-- Beam + Highlight según la rareza, nunca geometría extra):
-- * contorno (Highlight) al atacar desde Raro;
-- * haz vertical detrás del cuerpo en el Legendario;
-- * halo iridiscente detrás de la cabeza en el Único (anillo de dos Beam);
-- * emisivo animado (los surcos Neon laten) desde Épico.
-- Todo sale del pool y vuelve a él con el dueño del aura.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local BeamShapes = require(script.Parent.BeamShapes)

local RarityEffects = {}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

function RarityEffects.color(rarityColor: { number }?): Color3
	return rgb(rarityColor or { 255, 255, 255 })
end

-- Luz de contorno (Highlight sobre el modelo). Devuelve la instancia o nil si no hay hueco.
function RarityEffects.rim(
	pool: any,
	owner: any,
	model: Model,
	spec: any,
	color: Color3,
	brightness: number
): Highlight?
	local h = pool:acquire("Highlight", model, owner) :: Highlight?
	if not h then
		return nil
	end
	h.Adornee = model
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.FillTransparency = spec.fill or 1
	h.OutlineColor = color
	h.OutlineTransparency = 1 - (1 - (spec.outline or 0.2)) * brightness
	h.Enabled = true
	return h
end

-- Haz vertical del Legendario detrás de la espalda (no cruza la cara)
function RarityEffects.beam(
	pool: any,
	owner: any,
	rig: any,
	spec: any,
	color: Color3,
	scale: number,
	brightness: number
): any
	local parent = rig.primary
	if not parent then
		return nil
	end
	local back: Vector3 = rig.anchors.back
	local p0 = back - Vector3.new(0, back.Y * 0.6, 0)
	local p1 = back + Vector3.new(0, spec.height * scale, 0)
	local inv = rig.primaryOffset:Inverse()
	local line = BeamShapes.line(pool, owner, parent, inv * p0, inv * p1, {
		width = spec.width * scale,
		width1 = 0,
		segments = 1,
		color = ColorSequence.new(color),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 1 - (1 - spec.transparency) * brightness),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lightEmission = spec.lightEmission or 1,
	})
	return line
end

-- Halo iridiscente del Único: anillo vertical detrás de la cabeza cuyo color va girando
function RarityEffects.halo(pool: any, owner: any, rig: any, spec: any, color: Color3, scale: number): any
	local parent = rig.primary
	if not parent then
		return nil
	end
	local iri = rgb((VFX.ImpactColors :: any)[spec.colorTo or "iridescent"])
	local frame = rig.primaryOffset:Inverse() * CFrame.new(rig.anchors.top) * CFrame.Angles(math.pi / 2, 0, 0)
	local ring = BeamShapes.ring(pool, owner, parent, frame, spec.radius * scale, {
		width = spec.width * scale,
		segments = spec.segments,
		color = ColorSequence.new(color, iri),
		transparency = NumberSequence.new(0.35),
		lightEmission = 1,
	})
	if not ring then
		return nil
	end
	local r = ring :: any
	local t = 0
	-- Iridiscencia: el degradado se desplaza despacio (10 veces por segundo, no cada frame)
	r.update = function(dt: number)
		t += dt
		local k = math.floor(t * 10)
		if k ~= r.lastK then
			r.lastK = k
			local w = (math.sin(t * 1.3) + 1) / 2
			ring.setColor(ColorSequence.new(color:Lerp(iri, w), iri:Lerp(color, w)))
		end
	end
	return r
end

-- Emisivo animado: las piezas Neon («Glow», «Gill») laten un poco hacia el blanco
function RarityEffects.glowParts(creature: any): { any }
	local list = {}
	for _, rec in ipairs(creature.parts or {}) do
		if rec.kind == "Glow" or rec.kind == "Gill" then
			table.insert(list, rec)
		end
	end
	return list
end

function RarityEffects.pulse(list: { any }, t: number, amount: number)
	local k = (math.sin(t * 3) + 1) / 2 * amount
	for _, rec in ipairs(list) do
		rec.part.Color = rec.baseColor:Lerp(Color3.new(1, 1, 1), k)
	end
end

function RarityEffects.restore(list: { any })
	for _, rec in ipairs(list) do
		rec.part.Color = rec.baseColor
	end
end

return RarityEffects
