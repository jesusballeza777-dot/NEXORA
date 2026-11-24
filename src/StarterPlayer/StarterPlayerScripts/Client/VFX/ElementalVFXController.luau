--!strict
-- Efectos de los doce elementos en combate (Config/VFX.Elements): lanzamiento en el
-- atacante, viaje hasta el objetivo e impacto. Cada pieza es un efecto del VFXRuntime
-- (un paso por frame) con instancias del VFXPool que vuelven al terminar.
-- Primitivas: brotes de partículas en volúmenes invisibles orientados al objetivo, anillos
-- de dos Beam, haces, arcos que saltan, puntos que viajan con estela, luces breves y
-- contornos (Highlight). La identidad sale de la forma y el movimiento, no de texturas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local VFXPlan = require(script.Parent.VFXPlan)
local VFXContext = require(script.Parent.VFXContext)
local VFXSettings = require(script.Parent.VFXSettings)
local ParticleStyles = require(script.Parent.ParticleStyles)
local BeamShapes = require(script.Parent.BeamShapes)
local CreatureRig = require(script.Parent.Parent.Creatures.CreatureRig)

local ElementalVFXController = {}

export type Ctx = {
	owner: any?, -- dueño para cancelar todo junto (la secuencia o el combate)
	pool: any?,
	runtime: any?,
	quality: string?,
	reducedMotion: boolean?,
	scale: number?,
	colors: any?, -- { palette, rarity }
}

local function deps(ctx: Ctx?): (any, any, any, any, Ctx)
	local c: Ctx = ctx or {}
	local settings = VFXSettings.get()
	local pool = c.pool or VFXContext.pool()
	local runtime = c.runtime or VFXContext.runtime()
	local q = VFXPlan.quality(c.quality or settings.quality)
	if c.reducedMotion == nil then
		c.reducedMotion = settings.reducedMotion
	end
	return pool, runtime, q, c.owner or c, c
end

-- Puntos de una criatura en el mundo (anclajes del rig sobre su pose actual)
function ElementalVFXController.point(creature: any, anchor: string): Vector3
	local rig = CreatureRig.get(creature)
	local a = rig.anchors
	local base = if rig.primary then rig.primary.CFrame * rig.primaryOffset:Inverse() else CFrame.identity
	local local_ = if anchor == "Mouth"
		then a.mouth
		elseif anchor == "Above" then a.above
		elseif anchor == "Feet" or anchor == "CasterFeet" or anchor == "TargetFeet" then a.feet
		elseif anchor == "Back" then a.back
		else a.center
	return base * local_
end

local function rgbSeq(colors: any, keys: { string }?): ColorSequence
	local k = keys or { "primary", "secondary" }
	return ColorSequence.new(ParticleStyles.color(k[1], colors), ParticleStyles.color(k[2] or k[1], colors))
end

local function fade(from: number, to: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) })
end

-- Efecto con duración fija: onUpdate(u, dt) cada frame y onFinish al acabar
local function timed(
	runtime: any,
	owner: any,
	duration: number,
	onUpdate: ((number, number) -> ())?,
	onFinish: () -> ()
): number?
	local t = 0
	return runtime:add({
		update = function(_, dt: number)
			t += dt
			if onUpdate then
				onUpdate(math.clamp(t / math.max(duration, 1e-3), 0, 1), dt)
			end
			return t < duration
		end,
		finish = function()
			onFinish()
		end,
	}, owner)
end

-- Brote de partículas en un volumen invisible en `pos`, con +Z hacia `facing`
function ElementalVFXController.burst(use: any, pos: Vector3, facing: Vector3?, colors: any, ctx: Ctx?): number?
	local pool, runtime, q, owner, c = deps(ctx)
	local style = ParticleStyles.style(use.style)
	local vol = pool:acquire("Part", VFXContext.anchor().Parent, owner) :: BasePart?
	if not vol then
		return nil
	end
	local em = pool:acquire("ParticleEmitter", vol, owner) :: ParticleEmitter?
	if not em then
		pool:release(vol)
		return nil
	end
	local s = c.scale or 1
	local v = style.volume or { 0.4, 0.4, 0.4 }
	vol.Size = Vector3.new(v[1] * s, v[2] * s, v[3] * s)
	local dir = if facing then facing - pos else Vector3.new(0, 0, 1)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 1e-3 then
		flat = Vector3.new(0, 0, 1)
	end
	-- lookAt apunta −Z hacia su objetivo: mirando «hacia atrás», +Z (Forward) mira al objetivo
	vol.CFrame = CFrame.lookAt(pos, pos - flat.Unit)
	ParticleStyles.apply(em, style, colors, { rate = q.rate, size = s, burst = q.burst })
	em.Enabled = false
	local n = ParticleStyles.burst(style, use.burst, { burst = q.burst })
	pcall(function()
		em:Emit(n)
	end)
	-- Se suelta cuando ya no queda ninguna partícula viva
	return timed(runtime, owner, style.lifetime[2] + 0.05, nil, function()
		pool:release(vol)
	end)
end

-- Anillo que crece (y se desvanece) en `center`; tilt en grados sobre X (90 = vertical)
function ElementalVFXController.ring(spec: any, center: Vector3, colors: any, ctx: Ctx?): number?
	local pool, runtime, q, owner, c = deps(ctx)
	if not q.beams then
		return nil
	end
	local s = c.scale or 1
	local duration = spec.duration or 0.35
	local anchor = VFXContext.anchor()
	local frame = CFrame.new(center) * CFrame.Angles(math.rad(spec.tilt or 0), 0, 0)
	local r0, r1 = spec.radius[1] * s, spec.radius[2] * s
	local start = function()
		local ring = BeamShapes.ring(pool, owner, anchor, frame, r0, {
			width = spec.width * s,
			segments = spec.segments,
			color = rgbSeq(colors, { spec.color or "primary" }),
			transparency = NumberSequence.new(0.1),
			lightEmission = 1,
		})
		if not ring then
			return
		end
		local r = ring :: any
		local turn = 0
		timed(runtime, owner, duration, function(u)
			-- giro a saltos (engranaje) si spinStep
			if spec.spinStep then
				turn = math.floor(u * duration / spec.spinStep) * math.rad(45)
			end
			r.set(frame * CFrame.Angles(0, turn, 0), r0 + (r1 - r0) * (1 - (1 - u) ^ 2))
			r.setTransparency(NumberSequence.new(0.1 + 0.9 * u))
		end, function()
			r.release()
		end)
	end
	if spec.delay and spec.delay > 0 then
		return runtime:delay(spec.delay, start, owner)
	end
	start()
	return nil
end

-- Luz breve (PointLight sin sombras, rango ≤ 12). Solo con calidad que permita luces.
function ElementalVFXController.light(spec: any, pos: Vector3, colors: any, ctx: Ctx?): number?
	local pool, runtime, q, owner, c = deps(ctx)
	if not q.lights then
		return nil
	end
	local att = pool:acquire("Attachment", VFXContext.anchor(), owner) :: Attachment?
	local light = if att then pool:acquire("PointLight", att, owner) :: PointLight? else nil
	if not (att and light) then
		pool:release(att)
		return nil
	end
	att.CFrame = CFrame.new(pos)
	light.Color = ParticleStyles.color(spec.color or "primary", colors)
	light.Range = math.min(12, spec.range or 8)
	light.Shadows = false
	light.Enabled = true
	-- Movimiento reducido: sin destellos fuertes
	local peak = if c.reducedMotion then math.min(1, spec.brightness) else spec.brightness
	return timed(runtime, owner, spec.duration or 0.2, function(u)
		light.Brightness = peak * (1 - u)
	end, function()
		pool:release(att)
	end)
end

-- Contorno breve sobre un modelo (Highlight)
function ElementalVFXController.flash(spec: any, model: Model, colors: any, ctx: Ctx?): number?
	local pool, runtime, q, owner, c = deps(ctx)
	if not q.highlights then
		return nil
	end
	local h = pool:acquire("Highlight", model, owner) :: Highlight?
	if not h then
		return nil
	end
	local color = ParticleStyles.color(spec.color or "accent", colors)
	h.Adornee = model
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.FillColor = color
	h.OutlineColor = color
	h.Enabled = true
	local fill = spec.fill or 0.75
	local strength = if c.reducedMotion then 0.5 else 1
	-- Nunca más de 0,3 s sobre el objetivo
	local duration = math.min(spec.duration or 0.15, VFX.Budget.maxTargetOcclusion)
	return timed(runtime, owner, duration, function(u)
		h.FillTransparency = 1 - (1 - fill) * strength * (1 - u)
		h.OutlineTransparency = 1 - strength * (1 - u)
	end, function()
		pool:release(h)
	end)
end

-- Líneas cortas que saltan (descargas de parálisis, arcos de Rayo alrededor del objetivo)
function ElementalVFXController.arcs(spec: any, center: Vector3, colors: any, ctx: Ctx?): number?
	local pool, runtime, q, owner, c = deps(ctx)
	if not q.beams then
		return nil
	end
	local s = c.scale or 1
	local anchor = VFXContext.anchor()
	local lines = {}
	for _ = 1, spec.count or 2 do
		local line = BeamShapes.line(pool, owner, anchor, center, center, {
			width = 0.08 * s,
			width1 = 0.02 * s,
			segments = 2,
			color = rgbSeq(colors, { spec.color or "accent" }),
		})
		if line then
			table.insert(lines, line)
		end
	end
	local acc, k = 0, 0
	return timed(runtime, owner, spec.duration or 0.25, function(_, dt)
		acc += dt
		if acc >= 1 / 20 then
			acc = 0
			for i, line in ipairs(lines) do
				k += 1
				local a = k * 2.39996 + i
				local l = (spec.length or 1.2) * s
				local p0 = center
					+ Vector3.new(math.cos(a) * 0.3 * s, math.sin(a * 1.7) * 0.4 * s, math.sin(a) * 0.3 * s)
				local p1 = p0 + Vector3.new(math.cos(a + 1.2) * l, math.sin(a * 0.7) * l * 0.5, math.sin(a + 1.2) * l)
				line.set(p0, p1, (math.sin(a * 3) * 0.4) * s)
			end
		end
	end, function()
		for _, line in ipairs(lines) do
			line.release()
		end
	end)
end

-- Grecas: líneas cortas en escalón a ras de suelo alrededor del objetivo (Tierra)
local function grecas(spec: any, feet: Vector3, colors: any, ctx: Ctx?)
	local pool, runtime, q, owner, c = deps(ctx)
	if not q.beams then
		return
	end
	local s = c.scale or 1
	local anchor = VFXContext.anchor()
	local lines = {}
	for i = 0, (spec.count or 4) - 1 do
		local a = i / (spec.count or 4) * math.pi * 2
		local r = 1.1 * s
		local p0 = feet + Vector3.new(math.cos(a) * r, 0.05, math.sin(a) * r)
		local step = Vector3.new(-math.sin(a), 0, math.cos(a)) * spec.length * s
		local line = BeamShapes.line(pool, owner, anchor, p0, p0 + step, {
			width = spec.width * s,
			segments = 1,
			color = rgbSeq(colors, { spec.color or "accent" }),
			faceCamera = false,
		})
		if line then
			table.insert(lines, line)
		end
	end
	timed(runtime, owner, spec.duration or 0.4, function(u)
		for _, line in ipairs(lines) do
			line.setTransparency(NumberSequence.new(u))
		end
	end, function()
		for _, line in ipairs(lines) do
			line.release()
		end
	end)
end

-- Constelación: puntos que se unen con líneas finas, una tras otra (Astral)
local function constellation(spec: any, center: Vector3, colors: any, ctx: Ctx?)
	local pool, runtime, q, owner, c = deps(ctx)
	if not q.beams then
		return
	end
	local s = c.scale or 1
	local anchor = VFXContext.anchor()
	local pts = {}
	for i = 1, spec.points do
		local a = i * 2.39996
		table.insert(
			pts,
			center
				+ Vector3.new(
					math.cos(a) * spec.radius * s,
					0.6 * s + math.sin(a * 1.3) * 0.5 * s,
					math.sin(a) * spec.radius * s * 0.4 - 0.4 * s
				)
		)
	end
	local lines = {}
	for i = 1, #pts - 1 do
		local line = BeamShapes.line(pool, owner, anchor, pts[i], pts[i], {
			width = spec.width * s,
			segments = 1,
			color = rgbSeq(colors, { spec.color or "secondary" }),
		})
		if line then
			table.insert(lines, line)
		end
	end
	timed(runtime, owner, spec.duration, function(u)
		local grow = u * #lines
		for i, line in ipairs(lines) do
			local k = math.clamp(grow - (i - 1), 0, 1)
			line.set(pts[i], pts[i]:Lerp(pts[i + 1], k), 0)
		end
	end, function()
		for _, line in ipairs(lines) do
			line.release()
		end
	end)
end

-- Capa "cast" o "impact" de un elemento en un punto (emisores, anillos, luz, contorno…)
function ElementalVFXController.layer(elementId: string?, phase: string, at: any, ctx: Ctx?)
	local profile = VFXPlan.profile(elementId)
	local layer = profile[phase]
	if not layer then
		return
	end
	local c: Ctx = ctx or {}
	local colors = c.colors or { palette = profile.palette }
	local creature = at.creature
	local facing: Vector3? = at.facing
	for _, use in ipairs(layer.emitters or {}) do
		local anchor = use.anchor or ParticleStyles.style(use.style).anchor
		local pos = if creature then ElementalVFXController.point(creature, anchor) else at.position
		ElementalVFXController.burst(use, pos, facing, colors, c)
	end
	local center = if creature then ElementalVFXController.point(creature, "Center") else at.position
	local feet = if creature then ElementalVFXController.point(creature, "Feet") else at.position
	for _, ring in ipairs(layer.rings or {}) do
		ElementalVFXController.ring(
			ring,
			if (ring.tilt or 0) == 0 then feet + Vector3.new(0, 0.08, 0) else center,
			colors,
			c
		)
	end
	if layer.light then
		ElementalVFXController.light(layer.light, center, colors, c)
	end
	if layer.flash and creature then
		ElementalVFXController.flash(layer.flash, creature.model, colors, c)
	end
	if layer.grecas then
		grecas(layer.grecas, feet, colors, c)
	end
	if layer.constellation then
		constellation(layer.constellation, center, colors, c)
	end
end

-- Viaje del ataque de p0 a p1 en `duration` segundos según travel.kind
function ElementalVFXController.travel(
	elementId: string?,
	p0: Vector3,
	p1: Vector3,
	duration: number,
	ctx: Ctx?
): number?
	local pool, runtime, q, owner, c = deps(ctx)
	local profile = VFXPlan.profile(elementId)
	local tr = profile.travel
	local colors = c.colors or { palette = profile.palette }
	local s = c.scale or 1
	local anchor = VFXContext.anchor()
	local kind = tr.kind
	local dir = p1 - p0
	local side = Vector3.new(-dir.Z, 0, dir.X)
	side = if side.Magnitude > 1e-3 then side.Unit else Vector3.new(1, 0, 0)
	-- Los viajes a ras de suelo (Tierra, Sombra, raíces) van de pies a pies
	local cx = c :: any
	local ground0: Vector3 = cx.feet0 or Vector3.new(p0.X, p0.Y - 1.2 * s, p0.Z)
	local ground1: Vector3 = cx.feet1 or Vector3.new(p1.X, ground0.Y, p1.Z)

	-- Punto que viaja con emisor (y estela opcional)
	local head = pool:acquire("Attachment", anchor, owner) :: Attachment?
	local em: ParticleEmitter? = nil
	if head and tr.emitter then
		em = pool:acquire("ParticleEmitter", head, owner) :: ParticleEmitter?
		if em then
			local style = ParticleStyles.style(tr.emitter)
			ParticleStyles.apply(em, style, colors, { rate = q.rate, size = s, burst = q.burst })
			em.Rate = math.max(em.Rate, math.min(VFX.Budget.maxRatePerEmitter, 14 * q.rate))
			em.Enabled = true
		end
	end
	local trail: Trail? = nil
	local tail: Attachment? = nil
	if head and tr.trail and q.trails then
		tail = pool:acquire("Attachment", anchor, owner) :: Attachment?
		trail = pool:acquire("Trail", anchor, owner) :: Trail?
		if tail and trail then
			trail.Attachment0 = head
			trail.Attachment1 = tail
			trail.Lifetime = tr.trail.lifetime
			trail.Color = rgbSeq(colors, tr.trail.color)
			trail.Transparency = fade(0.1, 1)
			trail.WidthScale = fade(1, 0)
			trail.LightEmission = 1
			trail.FaceCamera = true
			trail.Enabled = true
		end
	end
	-- Haz (Beam, Roots) o arco (Arc) entre el origen y la cabeza
	local lines = {}
	if (kind == "Beam" or kind == "Roots" or kind == "Arc") and q.beams then
		local segs = if kind == "Arc" then tr.segments else 1
		for _ = 1, segs do
			local line = BeamShapes.line(pool, owner, anchor, p0, p0, {
				width = (tr.width and tr.width[1] or 0.3) * s,
				width1 = (tr.width and tr.width[2] or 0.2) * s,
				segments = if kind == "Arc" then 2 else (tr.segments or 10),
				color = rgbSeq(colors, tr.color),
				transparency = fade(0.05, 0.4),
			})
			if line then
				table.insert(lines, line)
			end
		end
	end
	local rippleAt = 0
	local hopAcc = 0
	local jitterAcc = 0
	local jitter: { Vector3 } = {}
	return timed(runtime, owner, duration, function(u, dt)
		local pos: Vector3
		if kind == "Projectile" then
			pos = p0:Lerp(p1, u) + Vector3.new(0, 4 * (tr.arc or 0) * s * u * (1 - u), 0)
		elseif kind == "Ground" or kind == "Roots" then
			pos = ground0:Lerp(ground1, u) + side * (tr.sway or 0) * s * math.sin(u * math.pi * 3)
		elseif kind == "Spiral" or kind == "Orbit" then
			local a = u * math.pi * 2 * (tr.turns or 2)
			local r = (tr.radius or 0.5) * s * math.sin(math.pi * u)
			pos = p0:Lerp(p1, u) + side * math.cos(a) * r + Vector3.new(0, math.sin(a) * r, 0)
		else
			pos = p0:Lerp(p1, u)
		end
		if head then
			head.CFrame = CFrame.new(pos) * CFrame.Angles(0, u * (tr.spin or 0), 0)
		end
		if tail then
			tail.CFrame = CFrame.new(pos + Vector3.new(0, (tr.trail and tr.trail.width or 0.3) * s, 0))
		end
		-- Tierra avanza «a saltos»: un brote de polvo cada `hop` segundos
		if kind == "Ground" and tr.hop and em then
			hopAcc += dt
			if hopAcc >= tr.hop then
				hopAcc = 0
				pcall(function()
					(em :: ParticleEmitter):Emit(2)
				end)
			end
		end
		if kind == "Beam" or kind == "Roots" then
			local curve = (tr.arc or 0.1) * s * (1 + (tr.wobble or 0) * math.sin(u * 20))
			for _, line in ipairs(lines) do
				line.set(if kind == "Roots" then ground0 else p0, pos, curve)
			end
		elseif kind == "Arc" then
			jitterAcc += dt
			if jitterAcc >= 1 / (tr.jitterHz or 20) or #jitter == 0 then
				jitterAcc = 0
				table.clear(jitter)
				for i = 0, #lines do
					local k = i / #lines
					local off = if i == 0 or i == #lines
						then Vector3.zero
						else Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
							* 2
							* tr.jitter
							* s
					table.insert(jitter, p0:Lerp(pos, k) + off)
				end
			end
			for i, line in ipairs(lines) do
				line.set(jitter[i], jitter[i + 1], 0)
			end
		elseif kind == "Ripple" then
			local every = 1 / math.max(1, tr.count)
			if u >= rippleAt and rippleAt < 1 then
				rippleAt += every
				ElementalVFXController.ring({
					radius = tr.radius,
					width = 0.08,
					segments = 20,
					tilt = 90,
					color = tr.color[1],
					duration = 0.3,
				}, pos, colors, c)
			end
		end
	end, function()
		for _, line in ipairs(lines) do
			line.release()
		end
		pool:release(trail)
		pool:release(tail)
		if em then
			em.Enabled = false
		end
		-- El emisor del punto espera a que se apaguen sus partículas antes de volver al pool
		local life = if tr.emitter then ParticleStyles.style(tr.emitter).lifetime[2] else 0
		if head then
			if life > 0 then
				runtime:delay(life, function()
					pool:release(head)
				end, owner)
			else
				pool:release(head)
			end
		end
	end)
end

-- Tiempo de viaje: distancia / velocidad del elemento, dentro de la fase de ejecución
function ElementalVFXController.travelTime(elementId: string?, distance: number, maxSeconds: number): number
	local tr = VFXPlan.profile(elementId).travel
	return math.clamp(distance / math.max(1, tr.speed), 0.08, math.max(0.08, maxSeconds))
end

return ElementalVFXController
