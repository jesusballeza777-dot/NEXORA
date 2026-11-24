--!strict
-- Aplica un estilo de Config/VFX.Styles a un ParticleEmitter. Fija TODAS las propiedades
-- (también las que el estilo no menciona) para que un emisor reutilizado del pool nunca
-- arrastre valores del uso anterior. La tasa nunca pasa de VFX.Budget.maxRatePerEmitter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local ParticleStyles = {}

export type Scale = { rate: number?, size: number?, brightness: number?, burst: number? }
export type Colors = { palette: { [string]: { number } }, rarity: { number }? }

-- Dirección relativa a la criatura/objetivo (+Z = delante) → NormalId del emisor
local DIRECTION: { [string]: Enum.NormalId } = {
	Up = Enum.NormalId.Top,
	Down = Enum.NormalId.Bottom,
	Forward = Enum.NormalId.Back, -- +Z
	Behind = Enum.NormalId.Front, -- −Z
	Left = Enum.NormalId.Right, -- +X es la izquierda de la criatura (convención de asset.json)
	Right = Enum.NormalId.Left,
}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- Color de una clave: paleta del elemento → color de rareza → colores fijos de impacto
function ParticleStyles.color(key: string?, colors: Colors): Color3
	local k = key or "primary"
	local c = colors.palette[k]
	if not c and k == "rarity" then
		c = colors.rarity
	end
	if not c then
		c = (VFX.ImpactColors :: any)[k]
	end
	return rgb(c or colors.palette.primary or { 255, 255, 255 })
end

local function sequence(keys: { { number } }, mult: number): NumberSequence
	local points = {}
	for _, k in ipairs(keys) do
		table.insert(points, NumberSequenceKeypoint.new(k[1], k[2] * mult))
	end
	return NumberSequence.new(points)
end

local function range(r: { number }?, default: number): NumberRange
	if not r then
		return NumberRange.new(default)
	end
	return NumberRange.new(math.min(r[1], r[2]), math.max(r[1], r[2]))
end

function ParticleStyles.style(id: string): any
	local s = (VFX.Styles :: any)[id]
	assert(s, "Estilo de VFX inexistente: " .. id)
	return s
end

-- Tasa efectiva de un estilo con su escala (0 para los de pulsos o brotes)
function ParticleStyles.rate(style: any, scale: Scale?): number
	if style.tick then
		return 0
	end
	return math.clamp(style.rate * (scale and scale.rate or 1), 0, VFX.Budget.maxRatePerEmitter)
end

-- Partículas por brote o por pulso, con escala y un mínimo de 1
function ParticleStyles.burst(style: any, base: number?, scale: Scale?): number
	local n = (base or style.burst or 6) * (scale and scale.burst or 1)
	return math.max(1, math.floor(n + 0.5))
end

function ParticleStyles.apply(emitter: ParticleEmitter, style: any, colors: Colors, scale: Scale?)
	local sizeMul = scale and scale.size or 1
	local bright = scale and scale.brightness or 1
	emitter.Texture = (VFX.Textures :: any)[style.texture] or VFX.Textures.Sparkle
	emitter.Rate = ParticleStyles.rate(style, scale)
	emitter.Lifetime = range(style.lifetime, 1)
	emitter.Speed = range(style.speed, 0)
	emitter.SpreadAngle = Vector2.new(style.spread[1], style.spread[2])
	emitter.EmissionDirection = DIRECTION[style.direction or "Up"] or Enum.NormalId.Top
	emitter.Shape = (Enum.ParticleEmitterShape :: any)[style.shape or "Box"]
	emitter.ShapeStyle = (Enum.ParticleEmitterShapeStyle :: any)[style.shapeStyle or "Volume"]
	emitter.ShapeInOut = (Enum.ParticleEmitterShapeInOut :: any)[style.shapeInOut or "Outward"]
	emitter.ShapePartial = 1
	local a = style.acceleration or { 0, 0, 0 }
	emitter.Acceleration = Vector3.new(a[1], a[2], a[3])
	emitter.Drag = style.drag or 0
	emitter.Size = sequence(style.size, sizeMul)
	emitter.Transparency = sequence(style.transparency or { { 0, 0 }, { 1, 1 } }, 1)
	emitter.Squash = sequence(style.squash or { { 0, 0 }, { 1, 0 } }, 1)
	emitter.Rotation = range(style.rotation, 0)
	emitter.RotSpeed = range(style.rotSpeed, 0)
	emitter.Orientation = (Enum.ParticleOrientation :: any)[style.orientation or "FacingCamera"]
	emitter.LightEmission = style.lightEmission * bright
	emitter.LightInfluence = style.lightInfluence or 0
	emitter.Brightness = (style.brightness or 1) * bright
	-- El aura se dibuja detrás de la criatura (no tapa la cara)
	emitter.ZOffset = style.zOffset or (if style.anchor == "Back" or style.anchor == "Orbit" then -0.5 else 0)
	emitter.LockedToPart = style.lockedToPart == true
	emitter.VelocityInheritance = 0
	emitter.TimeScale = 1
	local c0 = ParticleStyles.color(style.color, colors)
	local c1 = if style.colorTo then ParticleStyles.color(style.colorTo, colors) else c0
	emitter.Color = ColorSequence.new(c0, c1)
end

return ParticleStyles
