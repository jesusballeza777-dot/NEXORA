--!strict
-- Secuencia del Tallado en la ceremonia (Config/VFX.Evolution; Biblia p. 20, regla 8
-- «mismo monstruo»). Fases: preparación corporal (el Brote se agacha) → energía del
-- elemento (chispas que convergen) → transición de materiales (el Brote se oscurece hasta
-- la silueta y luego brilla) → luz (destello) → revelación (aparece el Tallado, que es OTRO
-- modelo, y recupera sus materiales) → presentación (giro y pose de victoria).
-- Trabaja dentro de ViewportFrame, donde no hay partículas ni luces: todo se hace con
-- color, material, transparencia, cámara y piezas 2D. Duración ≤ 5 s y se puede saltar.
-- Pregunta 12 de la Biblia (corta o cinemática) abierta: esta es la versión corta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))
local Species = require(Config:WaitForChild("Species"))
local Elements = require(Config:WaitForChild("Elements"))

local VFXSettings = require(script.Parent.VFXSettings)
local CreatureBuilder = require(script.Parent.Parent.Creatures.CreatureBuilder)
local CreatureAnimator = require(script.Parent.Parent.Animation.CreatureAnimator)

local EvolutionVFXController = {}
EvolutionVFXController.__index = EvolutionVFXController

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- Retrato con la criatura accesible (para animarla y cambiar sus materiales)
local function viewport(
	parent: Instance,
	speciesId: string,
	form: string,
	size: number
): (ViewportFrame, any, Camera, CFrame)
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.fromOffset(size, size)
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromScale(0.5, 0.42)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 170, 150)
	vp.LightColor = Color3.fromRGB(255, 236, 210)
	vp.LightDirection = Vector3.new(-1, -1.4, -1)
	local c = CreatureBuilder.build(speciesId, form, { parent = vp })
	CreatureBuilder.pose(c, CFrame.Angles(0, math.rad(-35), 0))
	local cam = Instance.new("Camera")
	local extent = c.model:GetExtentsSize()
	local d = math.max(extent.X, extent.Y, extent.Z) * 1.9
	local center = Vector3.new(0, extent.Y * 0.45, 0)
	cam.FieldOfView = 34
	local camCF = CFrame.lookAt(center + Vector3.new(d * 0.2, d * 0.22, d), center)
	cam.CFrame = camCF
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
	return vp, c, cam, camCF
end

export type Options = {
	onPhase: ((phase: string) -> ())?,
	onFlash: (() -> ())?,
	sound: any?,
	size: number?,
	reducedMotion: boolean?,
}

function EvolutionVFXController.new(root: GuiObject, speciesId: string, opts: Options?): any
	local o: Options = opts or {}
	local sp = Species.ById[speciesId]
	local element = sp and sp.elements[1] or "Fuego"
	local profile = (VFX.Elements :: any)[element] or VFX.Neutral
	local phases = {}
	local t = 0
	for _, ph in ipairs(VFX.Evolution.phases) do
		table.insert(phases, { id = ph.id, start = t, duration = ph.duration })
		t += ph.duration
	end
	local size = o.size or 300
	local vp, brote, cam, camCF = viewport(root, speciesId, "Brote", size)
	local self = setmetatable({
		root = root,
		speciesId = speciesId,
		rarity = sp and sp.rarity,
		size = size,
		phases = phases,
		total = t,
		t = 0,
		phase = nil :: string?,
		entered = {} :: { [string]: boolean },
		done = false,
		opts = o,
		reduced = if o.reducedMotion ~= nil then o.reducedMotion else VFXSettings.get().reducedMotion,
		glow = rgb(Elements.ById[element] and Elements.ById[element].color or { 255, 200, 120 }),
		dark = rgb(profile.palette.dark),
		broteVp = vp :: ViewportFrame?,
		brote = brote,
		broteAnim = CreatureAnimator.new(brote, { seed = 7 }),
		cam = cam,
		camCF = camCF,
		talladoVp = nil :: ViewportFrame?,
		tallado = nil :: any,
		talladoAnim = nil :: any,
		talladoCamCF = CFrame.identity,
		sparks = {} :: { any },
		flashFrame = nil :: Frame?,
		materials = {} :: { [BasePart]: Enum.Material },
	}, EvolutionVFXController)
	for _, rec in ipairs(brote.parts) do
		self.materials[rec.part] = rec.part.Material
	end
	return self
end

local function cue(self: any, id: string)
	if self.opts.sound then
		self.opts.sound:play(id)
	end
end

function EvolutionVFXController.enter(self: any, id: string)
	if self.entered[id] then
		return
	end
	self.entered[id] = true
	self.phase = id
	if id == "Preparation" then
		self.broteAnim:trigger("Nexo", self.phases[1].duration + self.phases[2].duration)
	elseif id == "Energy" then
		-- Chispas 2D del color del elemento que convergen hacia la criatura
		for i = 1, VFX.Evolution.sparks do
			local f = Instance.new("Frame")
			f.Size = UDim2.fromOffset(10, 10)
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.BackgroundColor3 = self.glow
			f.BorderSizePixel = 0
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = f
			f.Parent = self.root
			table.insert(self.sparks, { frame = f, angle = i * 2.39996, delay = (i % 5) * 0.12 })
		end
	elseif id == "Light" then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = Color3.new(1, 1, 1)
		flash.BorderSizePixel = 0
		flash.BackgroundTransparency = if self.reduced then 0.6 else 0
		flash.ZIndex = 5
		flash.Parent = self.root
		self.flashFrame = flash
		if self.opts.onFlash and not self.reduced then
			self.opts.onFlash()
		end
		cue(self, "SFX_CR_" .. self.speciesId .. "_Evolve")
	elseif id == "Reveal" then
		self:clearBrote()
		local vp, c, _, camCF = viewport(self.root, self.speciesId, "Tallado", self.size)
		self.talladoVp, self.tallado, self.talladoCamCF = vp, c, camCF
		self.talladoAnim = CreatureAnimator.new(c, { seed = 9 })
		vp.ImageTransparency = 1
		for _, rec in ipairs(c.parts) do
			self.materials[rec.part] = rec.part.Material
			rec.part.Material = Enum.Material.Neon
			rec.part.Color = self.glow
		end
		cue(self, "SFX_UI_Evolve")
	elseif id == "Presentation" then
		if self.talladoAnim then
			self.talladoAnim:trigger("Victory", self.phases[6].duration)
		end
	end
	if self.opts.onPhase then
		self.opts.onPhase(id)
	end
end

function EvolutionVFXController.clearBrote(self: any)
	for _, s in ipairs(self.sparks) do
		s.frame:Destroy()
	end
	table.clear(self.sparks)
	if self.broteVp then
		self.broteVp:Destroy()
		self.broteVp = nil
	end
end

-- Restaura colores y materiales del Tallado (al revelarse del todo o al saltar)
local function settle(self: any)
	if not self.tallado then
		return
	end
	for _, rec in ipairs(self.tallado.parts) do
		rec.part.Material = self.materials[rec.part] or rec.part.Material
		rec.part.Color = rec.baseColor
	end
	if self.talladoVp then
		self.talladoVp.ImageTransparency = 0
		self.talladoVp.Size = UDim2.fromOffset(self.size, self.size)
	end
end

function EvolutionVFXController.step(self: any, dt: number)
	if self.done then
		return
	end
	self.t += dt
	for _, ph in ipairs(self.phases) do
		if self.t >= ph.start and not self.entered[ph.id] then
			self:enter(ph.id)
		end
	end
	local ph = nil
	for _, p in ipairs(self.phases) do
		if self.t >= p.start and self.t < p.start + p.duration then
			ph = p
		end
	end
	if not ph then
		settle(self)
		self.done = true
		self.phase = "Done"
		if self.flashFrame then
			self.flashFrame:Destroy()
			self.flashFrame = nil
		end
		if self.opts.onPhase then
			self.opts.onPhase("Done")
		end
		return
	end
	local u = math.clamp((self.t - ph.start) / ph.duration, 0, 1)
	local id = ph.id
	if self.broteVp then
		-- El Brote se agacha y tiembla de energía (animador en modo directo)
		self.broteAnim:update(dt, CFrame.Angles(0, math.rad(-35), 0), { speed = 0 })
	end
	if id == "Preparation" and not self.reduced then
		self.cam.CFrame = self.camCF:Lerp(self.camCF * CFrame.new(0, 0, -0.6), u)
	elseif id == "Energy" then
		local local_t = self.t - ph.start
		for _, s in ipairs(self.sparks) do
			local k = math.clamp((local_t - s.delay) / (ph.duration - s.delay), 0, 1)
			local r = 260 * (1 - k)
			s.frame.Position = UDim2.new(0.5, math.cos(s.angle) * r, 0.42, math.sin(s.angle) * r)
			s.frame.BackgroundTransparency = k
		end
		if self.broteVp then
			self.broteVp.ImageColor3 = Color3.new(1, 1, 1):Lerp(self.glow, 0.35 * u)
		end
	elseif id == "Transition" and self.brote then
		-- Primero se oscurece hasta la silueta y después brilla con el color del elemento
		local sil = VFX.Evolution.silhouette
		for _, rec in ipairs(self.brote.parts) do
			if u < sil then
				rec.part.Color = rec.baseColor:Lerp(self.dark, u / sil)
			else
				rec.part.Material = Enum.Material.Neon
				rec.part.Color = self.dark:Lerp(self.glow:Lerp(Color3.new(1, 1, 1), 0.3), (u - sil) / (1 - sil))
			end
		end
	elseif id == "Light" and self.flashFrame then
		local start = if self.reduced then 0.6 else 0
		self.flashFrame.BackgroundTransparency = start + (1 - start) * u
	elseif id == "Reveal" and self.tallado then
		if self.flashFrame then
			self.flashFrame:Destroy()
			self.flashFrame = nil
		end
		local vp = self.talladoVp :: ViewportFrame
		vp.ImageTransparency = 1 - u
		local grow = 0.8 + 0.2 * u
		vp.Size = UDim2.fromOffset(self.size * grow, self.size * grow)
		for _, rec in ipairs(self.tallado.parts) do
			rec.part.Color = self.glow:Lerp(rec.baseColor, u)
			if u > 0.6 then
				rec.part.Material = self.materials[rec.part] or rec.part.Material
			end
		end
	elseif id == "Presentation" and self.tallado then
		settle(self)
		-- Giro de presentación y pose de victoria (Misterio: «glitch» de cámara)
		local angle = math.rad(-35) + u * math.rad(if self.reduced then 20 else 60)
		self.talladoAnim:update(dt, CFrame.Angles(0, angle, 0), { speed = 0 })
		local glitch = (VFX.Rarities :: any)[self.rarity or ""]
		if glitch and glitch.cameraGlitch and not self.reduced then
			local a = glitch.cameraGlitch.amplitude
			local cam = (self.talladoVp :: ViewportFrame).CurrentCamera
			if cam then
				cam.CFrame = self.talladoCamCF
					+ Vector3.new(math.floor(self.t * 30) % 2 * a, math.floor(self.t * 23) % 2 * a, 0)
			end
		end
	end
end

-- Salta a la presentación final: el Tallado queda visible con sus materiales
function EvolutionVFXController.skip(self: any)
	if self.done then
		return
	end
	if not self.tallado then
		self.entered.Light = true
		self.entered.Energy = true
		self.entered.Transition = true
		self:enter("Reveal")
	end
	self:clearBrote()
	if self.flashFrame then
		self.flashFrame:Destroy()
		self.flashFrame = nil
	end
	settle(self)
	self.t = self.total
	self.done = true
	self.phase = "Done"
	if self.opts.onPhase then
		self.opts.onPhase("Done")
	end
end

return EvolutionVFXController
