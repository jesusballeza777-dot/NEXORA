--!strict
-- Formas hechas con Beam (sin geometría extra, Biblia p. 120):
-- * ring: círculo con dos Beam de Bézier entre dos attachments opuestos. Cada Beam es una
--   semicircunferencia: puntos de control a ±(4/3)·r a lo largo del eje del attachment.
--   `segments` bajo da un polígono (anillo hexagonal del Metal, octogonal del Artificio).
-- * line: haz recto o curvo entre dos puntos (corriente de Agua, raíces, rayo de Luz, arcos).
-- En Roblox el punto de control de un Beam es Attachment0.WorldPosition +
-- Attachment0.WorldAxis·CurveSize0 y Attachment1.WorldPosition − Attachment1.WorldAxis·CurveSize1.
-- VERIFICAR EN STUDIO el aspecto (signo de CurveSize1 y grosor con FaceCamera).

local BeamShapes = {}

local K = 4 / 3
-- El eje (X) del attachment apunta hacia +Z del plano del anillo
local AXIS_TO_Z = CFrame.Angles(0, -math.pi / 2, 0)

export type BeamSpec = {
	width: number,
	width1: number?,
	segments: number?,
	color: ColorSequence,
	transparency: NumberSequence?,
	lightEmission: number?,
	faceCamera: boolean?,
}

local function setup(beam: Beam, a0: Attachment, a1: Attachment, spec: BeamSpec)
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = spec.width
	beam.Width1 = spec.width1 or spec.width
	beam.Segments = spec.segments or 16
	beam.Color = spec.color
	beam.Transparency = spec.transparency or NumberSequence.new(0)
	beam.LightEmission = spec.lightEmission or 1
	beam.LightInfluence = 0
	beam.FaceCamera = spec.faceCamera ~= false
	beam.Texture = ""
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.Enabled = true
end

export type Ring = {
	set: (frame: CFrame, radius: number) -> (),
	setTransparency: (t: NumberSequence) -> (),
	setColor: (c: ColorSequence) -> (),
	release: () -> (),
	beams: { Beam },
}

-- frame: CFrame del centro del anillo en el espacio de `parent` (Y = normal del plano)
function BeamShapes.ring(pool: any, owner: any, parent: Instance, frame: CFrame, radius: number, spec: BeamSpec): Ring?
	local a0 = pool:acquire("Attachment", parent, owner) :: Attachment?
	local a1 = pool:acquire("Attachment", parent, owner) :: Attachment?
	local b1 = pool:acquire("Beam", parent, owner) :: Beam?
	local b2 = pool:acquire("Beam", parent, owner) :: Beam?
	if not (a0 and a1 and b1 and b2) then
		for _, inst in ipairs({ a0, a1, b1, b2 } :: { any }) do
			pool:release(inst)
		end
		return nil
	end
	setup(b1, a0, a1, spec)
	setup(b2, a0, a1, spec)
	local function set(f: CFrame, r: number)
		a0.CFrame = f * CFrame.new(-r, 0, 0) * AXIS_TO_Z
		a1.CFrame = f * CFrame.new(r, 0, 0) * AXIS_TO_Z
		b1.CurveSize0 = K * r
		b1.CurveSize1 = -K * r
		b2.CurveSize0 = -K * r
		b2.CurveSize1 = K * r
	end
	set(frame, radius)
	return {
		set = set,
		setTransparency = function(t: NumberSequence)
			b1.Transparency = t
			b2.Transparency = t
		end,
		setColor = function(c: ColorSequence)
			b1.Color = c
			b2.Color = c
		end,
		release = function()
			pool:release(b1)
			pool:release(b2)
			pool:release(a0)
			pool:release(a1)
		end,
		beams = { b1, b2 },
	}
end

export type Line = {
	set: (p0: Vector3, p1: Vector3, curve: number?) -> (),
	setWidth: (w0: number, w1: number) -> (),
	setTransparency: (t: NumberSequence) -> (),
	release: () -> (),
	beam: Beam,
}

-- Haz de p0 a p1 (en el espacio de `parent`); curve = altura del arco hacia +Y
function BeamShapes.line(pool: any, owner: any, parent: Instance, p0: Vector3, p1: Vector3, spec: BeamSpec): Line?
	local a0 = pool:acquire("Attachment", parent, owner) :: Attachment?
	local a1 = pool:acquire("Attachment", parent, owner) :: Attachment?
	local b = pool:acquire("Beam", parent, owner) :: Beam?
	if not (a0 and a1 and b) then
		for _, inst in ipairs({ a0, a1, b } :: { any }) do
			pool:release(inst)
		end
		return nil
	end
	setup(b, a0, a1, spec)
	-- Los ejes de ambos attachments apuntan hacia arriba: CurveSize levanta el arco
	local UP = CFrame.Angles(0, 0, math.pi / 2)
	local function set(q0: Vector3, q1: Vector3, curve: number?)
		a0.CFrame = CFrame.new(q0) * UP
		a1.CFrame = CFrame.new(q1) * UP
		local c = curve or 0
		b.CurveSize0 = c
		b.CurveSize1 = -c
	end
	set(p0, p1, 0)
	return {
		set = set,
		setWidth = function(w0: number, w1: number)
			b.Width0 = w0
			b.Width1 = w1
		end,
		setTransparency = function(t: NumberSequence)
			b.Transparency = t
		end,
		release = function()
			pool:release(b)
			pool:release(a0)
			pool:release(a1)
		end,
		beam = b,
	}
end

return BeamShapes
