--!strict
-- Aura de rareza de una criatura (Biblia p. 26 y 120; Genesis §6 y §9).
-- * Cuántos emisores y cuáles: VFXPlan.aura (rareza × forma × calidad × combate × opacado
--   × distancia). Común 0 · Raro 1 solo al atacar + contorno · Épico 1–2 · Legendario
--   2–3 + haz · Único hasta 3 + halo · Misterio propios. Brote: 80 % de tamaño, mitad de
--   partículas, como mucho 1 emisor. Combate: 60 %. Tasa ≤ 20/s por emisor.
-- * El sabor lo pone el elemento (VFX.Elements[...].aura) y el color de la rareza.
-- * La cara nunca se tapa: los puntos de emisión están detrás del cuerpo (Z < 0), detrás de
--   la cabeza (halo) o en la órbita exterior, que no emite mientras pasa por delante.
-- * Todo sale de VFXPool y vuelve a él: al cambiar el plan, al destruir el aura o al
--   destruir la criatura (se envuelve su destroy).
-- Sustituye al emisor provisional que creaba CreatureBuilder (se retira al adjuntar).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))
local Species = require(Config:WaitForChild("Species"))
local Guardians = require(Config:WaitForChild("Guardians"))
local Rarities = require(Config:WaitForChild("Rarities"))

local VFXPlan = require(script.Parent.VFXPlan)
local VFXContext = require(script.Parent.VFXContext)
local VFXSettings = require(script.Parent.VFXSettings)
local ParticleStyles = require(script.Parent.ParticleStyles)
local RarityEffects = require(script.Parent.RarityEffects)
local CreatureRig = require(script.Parent.Parent.Creatures.CreatureRig)

local AuraController = {}

local Aura = {}
Aura.__index = Aura

local GOLDEN = 2.3999632 -- ángulo áureo: saltos que no se repiten
local FRONT_COS = math.cos(math.rad(60)) -- sector frontal (±60°) donde la órbita no emite

local registry: { [any]: any } = {} -- criatura → aura

local function speciesInfo(id: string): (string?, string?)
	local sp = Species.ById[id]
	if sp then
		return sp.rarity, sp.elements[1]
	end
	local g = Guardians.ById[id]
	if g then
		return g.rarity, g.elements[1]
	end
	return nil, nil
end

export type AttachOptions = {
	battle: boolean?,
	pool: any?,
	quality: string?,
	rarity: string?,
	element: string?,
	rig: any?,
}

function AuraController.attach(creature: any, opts: AttachOptions?): any
	local o: AttachOptions = opts or {}
	local existing = registry[creature]
	if existing then
		existing:setBattle(o.battle == true)
		return existing
	end
	-- El emisor provisional del constructor deja paso al aura gestionada
	if creature.aura then
		creature.aura:Destroy()
		creature.aura = nil
	end
	local rarityId, element = speciesInfo(creature.speciesId)
	local rid = o.rarity or rarityId
	local rarityDef = if rid then Rarities.ById[rid] else nil
	local profile = VFXPlan.profile(o.element or element)
	local self = setmetatable({
		creature = creature,
		rig = o.rig or CreatureRig.get(creature),
		pool = o.pool or VFXContext.pool(),
		rarity = rid,
		element = o.element or element,
		form = creature.form,
		scale = creature.scale or 1,
		battle = o.battle == true,
		attacking = false,
		quality = o.quality,
		lod = "Full",
		plan = nil :: any,
		inputs = "",
		slots = {} :: { any },
		extras = {} :: { any },
		colors = { palette = profile.palette, rarity = if rarityDef then rarityDef.frameColor else nil },
		rimColor = RarityEffects.color(if rarityDef then rarityDef.frameColor else nil),
		glow = RarityEffects.glowParts(creature),
		glowing = false,
		t = 0,
		destroyed = false,
	}, Aura)
	-- Limpieza garantizada: destruir la criatura devuelve antes todo al pool
	local originalDestroy = creature.destroy
	creature.destroy = function(c: any)
		self:destroy()
		originalDestroy(c)
	end
	registry[creature] = self
	self:refresh()
	return self
end

function AuraController.get(creature: any): any
	return registry[creature]
end

function AuraController.count(): number
	local n = 0
	for _ in pairs(registry) do
		n += 1
	end
	return n
end

function Aura.context(self: any): VFXPlan.AuraContext
	return {
		quality = self.quality or VFXSettings.get().quality,
		battle = self.battle,
		attacking = self.attacking,
		opaco = (self.creature.opaco or 0) >= 0.5,
		lod = self.lod,
		element = self.element,
	}
end

function Aura.clearLayers(self: any)
	self.pool:releaseOwner(self)
	table.clear(self.slots)
	table.clear(self.extras)
end

local function anchorFor(rig: any, name: string): Vector3
	local a = rig.anchors
	if name == "Ground" then
		return a.ground
	elseif name == "Top" then
		return a.top
	end
	return a.back
end

-- Coloca el punto de emisión (y avanza su órbita). Devuelve si puede emitir ahora.
function Aura.place(self: any, slot: any, dt: number): boolean
	local style = slot.style
	local rig = self.rig
	local a = rig.anchors
	local pos: Vector3
	local free = true
	local o = style.orbit
	if o then
		local plane = o.plane or "Horizontal"
		local r = o.radius * self.scale
		if plane ~= "Vertical" then
			-- La inclinación acorta el radio horizontal: se compensa para seguir fuera del cuerpo
			local cosTilt = math.max(0.5, math.cos(math.rad(o.tilt or 0)))
			r = math.max(r, VFX.Budget.faceClearance * a.bodyRadius / cosTilt)
		end
		if o.step and o.step > 0 then
			slot.stepAcc += dt
			if slot.stepAcc >= o.step then
				slot.stepAcc -= o.step
				slot.theta += GOLDEN
				for _ = 1, 3 do
					if plane == "Horizontal" and math.cos(slot.theta) > FRONT_COS then
						slot.theta += GOLDEN
					end
				end
			end
		else
			slot.theta += (o.speed or 0) * dt
		end
		local th = slot.theta
		local bob = (o.bob or 0) * math.sin(self.t * 2 + slot.layer)
		if plane == "Vertical" then
			pos = a.top + Vector3.new(r * math.cos(th), r * math.sin(th), 0)
		else
			local tilt = math.rad(o.tilt or 0)
			local x, z = r * math.sin(th), r * math.cos(th)
			local base = if plane == "Ground" then Vector3.new(a.center.X, a.ground.Y, a.center.Z) else a.center
			pos = base + Vector3.new(x, z * math.sin(tilt) + bob, z * math.cos(tilt))
			-- La órbita alrededor del cuerpo no emite mientras pasa por delante de la cara
			free = plane == "Ground" or math.cos(th) <= FRONT_COS
		end
	else
		pos = anchorFor(rig, style.anchor)
	end
	slot.att.CFrame = CreatureRig.toPrimary(rig, pos)
	slot.free = free
	slot.pos = pos
	if not style.tick then
		slot.emitter.Enabled = free
	end
	return free
end

function Aura.refresh(self: any)
	if self.destroyed then
		return
	end
	local ctx = self:context()
	local inputs = string.format(
		"%s|%s|%s|%s|%s",
		ctx.quality or "",
		tostring(ctx.battle),
		tostring(ctx.attacking),
		tostring(ctx.opaco),
		ctx.lod or ""
	)
	if inputs == self.inputs then
		return
	end
	self.inputs = inputs
	local plan = VFXPlan.aura(self.rarity, self.form, ctx)
	if self.plan and plan.key == self.plan.key then
		self.plan = plan
		return
	end
	self:clearLayers()
	if self.glowing and not plan.glowPulse then
		self.glowing = false
		if (self.creature.opaco or 0) <= 0.01 then
			RarityEffects.restore(self.glow)
		end
	end
	self.plan = plan
	local rig = self.rig
	if not rig.primary then
		return
	end
	for _, e in ipairs(plan.emitters) do
		local style = ParticleStyles.style(e.style)
		local att = self.pool:acquire("Attachment", rig.primary, self)
		local em = if att then self.pool:acquire("ParticleEmitter", att, self) else nil
		if att and em then
			att.Name = "Aura_" .. e.style
			em.Name = e.style
			ParticleStyles.apply(
				em,
				style,
				self.colors,
				{ rate = e.rate, size = e.size * self.scale, brightness = e.brightness, burst = e.burst }
			)
			local slot = {
				att = att,
				emitter = em,
				style = style,
				layer = e.layer,
				theta = math.pi, -- empieza detrás
				stepAcc = 0,
				acc = 0,
				free = true,
				burst = ParticleStyles.burst(style, nil, { burst = e.burst }),
			}
			em.Enabled = true
			self:place(slot, 0)
			table.insert(self.slots, slot)
		elseif att then
			self.pool:release(att)
		end
	end
	local brightness = plan.brightness
	if plan.rim then
		local spec = (VFX.Rarities :: any)[self.rarity].rim
		local h = RarityEffects.rim(self.pool, self, self.creature.model, spec, self.rimColor, brightness)
		if h then
			table.insert(self.extras, { kind = "Rim", instance = h })
		end
	end
	if plan.beam then
		local line = RarityEffects.beam(self.pool, self, rig, plan.beam, self.rimColor, self.scale, brightness)
		if line then
			table.insert(self.extras, { kind = "Beam", line = line })
		end
	end
	if plan.halo then
		local ring = RarityEffects.halo(self.pool, self, rig, plan.halo, self.rimColor, self.scale)
		if ring then
			table.insert(self.extras, { kind = "Halo", ring = ring })
		end
	end
end

-- Un paso por frame. distance = distancia a la cámara (nil = sin cambio de LOD)
function Aura.update(self: any, dt: number, distance: number?)
	if self.destroyed then
		return
	end
	if distance then
		self.lod = VFXPlan.lod(distance, self.lod)
	end
	self:refresh()
	self.t += dt
	for _, slot in ipairs(self.slots) do
		local free = if slot.style.orbit then self:place(slot, dt) else slot.free
		local tick = slot.style.tick
		if tick then
			slot.acc += dt
			while slot.acc >= tick do
				slot.acc -= tick
				if free then
					pcall(function()
						slot.emitter:Emit(slot.burst)
					end)
				end
			end
		end
	end
	for _, extra in ipairs(self.extras) do
		if extra.ring and extra.ring.update then
			extra.ring.update(dt)
		end
	end
	local plan = self.plan
	if plan and plan.glowPulse and #self.glow > 0 and (self.creature.opaco or 0) <= 0.01 then
		self.glowing = true
		RarityEffects.pulse(self.glow, self.t, 0.18)
	end
end

function Aura.setAttacking(self: any, on: boolean)
	self.attacking = on
	self:refresh()
end

function Aura.setBattle(self: any, on: boolean)
	self.battle = on
	self:refresh()
end

function Aura.setQuality(self: any, quality: string?)
	self.quality = quality
	self:refresh()
end

function Aura.emitterCount(self: any): number
	return #self.slots
end

function Aura.destroy(self: any)
	if self.destroyed then
		return
	end
	self:clearLayers()
	if self.glowing and (self.creature.opaco or 0) <= 0.01 then
		RarityEffects.restore(self.glow)
	end
	self.destroyed = true
	registry[self.creature] = nil
end

-- Actualiza todas las auras; cameraPos para el LOD (nil = sin cambio)
function AuraController.updateAll(dt: number, cameraPos: Vector3?)
	for creature, aura in pairs(registry) do
		local model = creature.model
		if model and model.Parent then
			local d: number? = nil
			if cameraPos and aura.rig.primary then
				d = (aura.rig.primary.Position - cameraPos).Magnitude
			end
			aura:update(dt, d)
		end
	end
end

-- Registra la actualización de todas las auras en el runtime (un efecto permanente)
function AuraController.start(runtime: any, camera: () -> Vector3?)
	runtime:add({
		update = function(_, dt: number)
			AuraController.updateAll(dt, camera())
			return true
		end,
	})
end

return AuraController
