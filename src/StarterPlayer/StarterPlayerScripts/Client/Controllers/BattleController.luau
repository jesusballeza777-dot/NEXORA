--!strict
-- Presentación del combate PvE. El servidor resuelve; aquí solo se anima.
-- Flujo: BattleStart → el jugador elige → "Battle.Act" → BattleTurn (eventos +
-- instantánea) → animación evento a evento → ... → BattleEnd (resultado, recompensa).
-- Presentación (Fase 3): cada jugada reproduce su secuencia de seis fases con el perfil
-- de su elemento y el impacto adecuado (CombatVFXController), la cámara apoya la lectura
-- (CameraDirector: sacudida ≤ 0,3, sin movimiento con «movimiento reducido») y todo se
-- puede saltar con el botón ⏩. Los eventos del servidor no cambian: solo se leen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared.Config:WaitForChild("World"))
local VFX = require(Shared.Config:WaitForChild("VFX"))
local Encounters = require(Shared.Config:WaitForChild("Encounters"))
local Abilities = require(Shared.Config:WaitForChild("Abilities"))
local ElementChart = require(Shared.Domain:WaitForChild("ElementChart"))

local Client = script.Parent.Parent
local CreatureBuilder = require(Client.Creatures.CreatureBuilder)
local CreatureAnimator = require(Client.Animation.CreatureAnimator)
local AuraController = require(Client.VFX.AuraController)
local CombatVFXController = require(Client.VFX.CombatVFXController)
local ImpactVFXController = require(Client.VFX.ImpactVFXController)
local CameraDirector = require(Client.VFX.CameraDirector)
local VFXPlan = require(Client.VFX.VFXPlan)
local Kit = require(Client.UI.Kit)
local Net = require(Client.Net)

type Creature = CreatureBuilder.Creature

local BattleController = {}

local STATUS =
	{ Burn = "Quemadura", Paralysis = "Parálisis", Stun = "Aturdido", Sleep = "Dormido", Confuse = "Confusión" }
local KIND = { Basic = "Básico · +1 Savia", Special = "Especial", Signature = "Firma", Nexo = "Golpe Nexo" }

local gui: ScreenGui
-- Números flotantes aparte: render() vacía `gui` en cada turno y no debe cortarlos
local fx: Folder
local hooks: { [string]: any }
local battle: any = nil
local queue: { any } = {}
local playing = false

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

function BattleController.init(h: { [string]: any })
	hooks = h
	gui = Kit.screen("NexoBattle", 15)
	gui.Enabled = false
	fx = Instance.new("Folder")
	fx.Name = "NexoBattleFx"
	fx.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	Net.on("BattleStart", function(payload)
		BattleController.begin(payload)
	end)
	Net.on("BattleTurn", function(payload)
		table.insert(queue, { kind = "turn", payload = payload })
		BattleController.pump()
	end)
	Net.on("BattleEnd", function(payload)
		table.insert(queue, { kind = "end", payload = payload })
		BattleController.pump()
	end)
end

local function combatant(snapshot: any, side: number): any
	local s = snapshot.sides[side]
	return s.team[s.active]
end

local function card(c: any, mine: boolean, parent: Instance, anchor: Vector2, position: UDim2): Frame
	local pct = c.hp / c.maxHp
	local color = if pct < 0.25
		then Kit.Color.danger
		elseif pct < 0.55 then Color3.fromRGB(224, 177, 60)
		else Kit.Color.ok
	local statuses = {}
	for k, v in pairs(c.statuses) do
		if v > 0 then
			table.insert(statuses, STATUS[k] or k)
		end
	end
	for _, m in ipairs(c.mods) do
		table.insert(statuses, string.format("%s %s", m.stat, if m.amount > 0 then "▲" else "▼"))
	end
	-- Regla del Valle: raíces visibles para entender por qué se cura
	if c.rooted then
		table.insert(statuses, "🌿 Raíces: se cura cada turno (un golpe eficaz las corta)")
	end
	if c.phase and c.phase > 1 then
		table.insert(statuses, "🏮 Fase " .. tostring(c.phase))
	end
	if mine and battle and battle.snapshot.fieldAccuracy and battle.snapshot.fieldAccuracy[1] < 0 then
		table.insert(
			statuses,
			string.format(
				"Faroles apagados: %d %% precisión",
				math.floor(battle.snapshot.fieldAccuracy[1] * 100 + 0.5)
			)
		)
	end
	local side = if battle then battle.snapshot.sides[if mine then 1 else 2] else nil
	if side and #side.team > 1 then
		local dots = {}
		for _, m in ipairs(side.team) do
			table.insert(dots, if m.fainted then "○" else "●")
		end
		table.insert(statuses, 1, "Equipo " .. table.concat(dots, ""))
	end
	local bar = Kit.bar(pct, color, 12)
	local frame = Kit.panel({
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = anchor,
		Position = position,
		Parent = parent,
		Kit.padding(10),
		Kit.list(Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Left),
		Kit.text(
			string.format("<b>%s</b>   Nv %d", Kit.escape(c.name), c.level),
			17,
			{ FontFace = Kit.Font.title, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }
		),
		Kit.text(
			table.concat(c.elements, " · "),
			13,
			{ TextColor3 = Kit.Color.muted, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2 }
		),
		Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 3, bar }),
		Kit.text(
			string.format(
				"%d / %d PV%s",
				math.max(0, c.hp),
				c.maxHp,
				if mine
					then string.format("     Savia %s", string.rep("●", c.savia) .. string.rep("○", 3 - c.savia))
					else ""
			),
			13,
			{ TextColor3 = Kit.Color.jadeSoft, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4 }
		),
		Kit.text(
			table.concat(statuses, "  "),
			12,
			{ TextColor3 = Kit.Color.copalSoft, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 5 }
		),
	})
	return frame
end

function BattleController.render(caption: string?)
	if not battle then
		return
	end
	gui:ClearAllChildren()
	local scale = Kit.new("UIScale", { Parent = gui })
	local cam = Workspace.CurrentCamera
	scale.Scale = math.clamp((if cam then cam.ViewportSize.Y else 900) / 900, 0.72, 1.35)
	local snap = battle.snapshot
	local me, foe = combatant(snap, 1), combatant(snap, 2)
	card(foe, false, gui, Vector2.new(1, 0), UDim2.new(1, -12, 0, 60))
	card(me, true, gui, Vector2.new(0, 1), UDim2.new(0, 12, 1, -190))
	Kit.button("Huir", "secondary", function()
		local current = battle
		if current and not current.busy then
			current.busy = true
			local r = Net.request("Battle.Forfeit", current.id)
			if not r.ok and battle == current then
				current.busy = false
				hooks.toast(Net.message(r.err))
				BattleController.render(nil)
			end
		end
	end, { Size = UDim2.fromOffset(90, 44), Position = UDim2.fromOffset(12, 60), Parent = gui })
	if playing or (battle and battle.presenting) then
		-- Todo se puede saltar (también el Golpe Nexo)
		Kit.button("⏩ Saltar", "secondary", function()
			if battle then
				battle.skip = true
				if battle.seq then
					battle.seq.skip()
				end
			end
		end, {
			Size = UDim2.fromOffset(110, 48),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12),
			Parent = gui,
		})
	end
	if caption then
		Kit.panel({
			Size = UDim2.fromOffset(420, 52),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Parent = gui,
			Kit.text(caption, 18, { FontFace = Kit.Font.title, Size = UDim2.fromScale(1, 1) }),
		})
	end
	local moves = Kit.new("Frame", {
		Size = UDim2.new(1, -24, 0, 156),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		BackgroundTransparency = 1,
		Parent = gui,
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(640, 156) }),
		Kit.new("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 72), CellPadding = UDim2.fromOffset(10, 10) }),
	})
	for _, opt in ipairs(snap.options or {}) do
		local mv = Abilities.ById[opt.moveId]
		local color = hooks.elementColor(mv.element)
		local eff = if mv.power > 0
			then ElementChart.classify(ElementChart.multiplier(mv.element, foe.elements, mv.kind == "Nexo"))
			else "Neutral"
		local tag = if eff == "Strong" then "  ▲ Eficaz" elseif eff == "Weak" then "  ▼ Poco" else ""
		local enabled = opt.usable and not battle.busy
		local b = Kit.new("TextButton", {
			BackgroundColor3 = color,
			AutoButtonColor = enabled,
			Text = "",
			Parent = moves,
			Kit.corner(16),
			Kit.padding(8),
			Kit.list(Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Left),
			Kit.text(
				string.format("<b>%s</b>%s", mv.name, tag),
				16,
				{ FontFace = Kit.Font.title, TextColor3 = Kit.Color.ink, TextXAlignment = Enum.TextXAlignment.Left }
			),
			Kit.text(
				string.format(
					"%s%s%s",
					KIND[mv.kind],
					if mv.power > 0 then " · " .. mv.power else "",
					if opt.cost > 0 then " · " .. string.rep("●", opt.cost) else ""
				),
				12,
				{
					TextColor3 = Kit.Color.ink,
					TextXAlignment = Enum.TextXAlignment.Left,
				}
			),
		})
		if not enabled then
			b.BackgroundTransparency = 0.55
		end
		b.Activated:Connect(function()
			if battle and not battle.busy and opt.usable then
				battle.busy = true
				BattleController.render(nil)
				local r = Net.request("Battle.Act", battle.id, battle.snapshot.turn + 1, opt.moveId)
				if not r.ok then
					battle.busy = false
					hooks.toast(Net.message(r.err))
					BattleController.render(nil)
				end
			end
		end)
	end
end

-- Construye el modelo de un combatiente (los Seres Sagrados usan su propio blockout)
local function buildFor(c: any, isFoe: boolean): Creature
	local id = c.guardianId or c.speciesId
	local creature = CreatureBuilder.build(id, c.form, { opaco = isFoe and c.isOpaco })
	AuraController.attach(creature, { battle = true })
	return creature
end

-- Lado visual de un combatiente: criatura, animador, aura y uid del servidor
local function sideFor(creature: Creature, uid: string?): any
	return { creature = creature, anim = CreatureAnimator.new(creature), aura = AuraController.get(creature), uid = uid }
end

local function pause(seconds: number)
	local t = 0
	local limit = if battle and battle.skip then math.min(seconds, 0.15) else seconds
	while t < limit do
		t += task.wait()
		if battle and battle.skip then
			limit = math.min(limit, 0.15)
		end
	end
end

function BattleController.begin(payload: any)
	local enc = Encounters.ById[payload.encounterId]
	-- Las etapas del mapa luchan en la Linde de su región (las de la Fase 1, en su marcador)
	local marker = World.Encounters[enc.worldMarker or ("Encounter" .. tostring(math.clamp(enc.region, 1, 3)))]
	local center = v3(marker.position)
	hooks.suspendWorld(true)
	hooks.setHud(false)
	local me, foe = combatant(payload, 1), combatant(payload, 2)
	local mine = buildFor(me, false)
	local theirs = buildFor(foe, true)
	battle = {
		id = payload.battleId,
		snapshot = payload,
		busy = false,
		center = center,
		mine = mine,
		theirs = theirs,
		mineSide = sideFor(mine, me.uid),
		theirsSide = sideFor(theirs, foe.uid),
		homeMine = center + Vector3.new(-4.5, 0, 2.5),
		homeTheirs = center + Vector3.new(4.5, 0, -2),
		t = 0,
		skip = false,
		seq = nil,
		seqMine = true,
	}
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local follow = VFX.Camera.follow
	local director = CameraDirector.new(camera)
	director:setBase(
		center + Vector3.new(follow.offset[1], follow.offset[2], follow.offset[3]),
		center + Vector3.new(follow.look[1], follow.look[2], follow.look[3])
	)
	battle.director = director
	-- Transición suave desde la cámara del jugador al encuadre de combate
	local startCF = camera.CFrame
	local intro = 0
	battle.loop = game:GetService("RunService").RenderStepped:Connect(function(dt)
		battle.t += dt
		local dir = battle.homeTheirs - battle.homeMine
		local faceTheirs = math.atan2(dir.X, dir.Z)
		-- Embestida del atacante durante su secuencia
		local seq = battle.seq
		local lunge = if seq and not seq.done then seq.lunge else 0
		local offMine = if battle.seqMine then dir.Unit * lunge else Vector3.zero
		local offTheirs = if battle.seqMine then Vector3.zero else -dir.Unit * lunge
		local ms, ts = battle.mineSide, battle.theirsSide
		ms.anim:setLookTarget(battle.homeTheirs + Vector3.new(0, 1.5, 0))
		ts.anim:setLookTarget(battle.homeMine + Vector3.new(0, 1.5, 0))
		ms.anim:update(dt, CFrame.new(battle.homeMine + offMine) * CFrame.Angles(0, faceTheirs, 0), { speed = 0 })
		ts.anim:update(
			dt,
			CFrame.new(battle.homeTheirs + offTheirs) * CFrame.Angles(0, faceTheirs + math.pi, 0),
			{ speed = 0 }
		)
		local final = director:update(dt)
		if intro < 0.8 then
			intro += dt
			local k = math.clamp(intro / 0.8, 0, 1)
			camera.CFrame = startCF:Lerp(final, k * k * (3 - 2 * k))
		end
	end)
	gui.Enabled = true
	if foe.guardianId then
		-- Presentación del Ser Sagrado: la cámara la recorre de abajo arriba (se puede saltar)
		battle.theirsSide.anim:trigger("Warn", VFX.Camera.boss.duration)
		director:beat("Boss", battle.homeTheirs, VFX.Camera.boss.duration)
		battle.presenting = true
		BattleController.render(string.format("%s, guardiana del Valle, despierta opacada…", Kit.escape(foe.name)))
		pause(VFX.Camera.boss.duration + 0.2)
		if battle.skip then
			director:clear()
		end
		battle.presenting = false
		battle.skip = false
	end
	local count = #payload.sides[2].team
	BattleController.render(
		if count > 1
			then string.format("¡%d Opacos aparecen entre la niebla!", count)
			else string.format("¡Un %s aparece entre la niebla!", Kit.escape(foe.name))
	)
end

-- Faroles apagados (fase 2 de Copalia): el escenario se oscurece de verdad
local function dimLights(on: boolean)
	local grade = Lighting:FindFirstChild("NexoBattleDim") :: ColorCorrectionEffect?
	if on and not grade then
		local g = Instance.new("ColorCorrectionEffect")
		g.Name = "NexoBattleDim"
		g.Parent = Lighting
		TweenService:Create(g, TweenInfo.new(1.2), {
			Brightness = -0.18,
			Saturation = -0.25,
			TintColor = Color3.fromRGB(170, 180, 230),
		}):Play()
	elseif not on and grade then
		grade:Destroy()
	end
end

local function combatantByUid(uid: string): any
	for _, side in ipairs(battle.snapshot.sides) do
		for _, c in ipairs(side.team) do
			if c.uid == uid then
				return c
			end
		end
	end
	return nil
end

local function floater(isMine: boolean, text: string, color: Color3)
	local creature: Creature = if isMine then battle.mine else battle.theirs
	local anchor = creature.parts[1].part
	local bb = Kit.new("BillboardGui", {
		Size = UDim2.fromOffset(140, 50),
		StudsOffset = Vector3.new(0, 4, 0),
		AlwaysOnTop = true,
		Adornee = anchor,
		Parent = fx,
	})
	local label = Kit.text(text, 30, {
		FontFace = Kit.Font.title,
		TextColor3 = color,
		Size = UDim2.fromScale(1, 1),
		TextStrokeTransparency = 0.4,
		Parent = bb,
	})
	TweenService:Create(bb, TweenInfo.new(1), { StudsOffset = Vector3.new(0, 7, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.05, function()
		bb:Destroy()
	end)
end

local function nameOf(uid: string): string
	for _, side in ipairs(battle.snapshot.sides) do
		for _, c in ipairs(side.team) do
			if c.uid == uid then
				return Kit.escape(c.name)
			end
		end
	end
	return ""
end

-- Espera a que la secuencia llegue a una fase (o termine, o se salte)
local function waitSeq(seq: any, phase: string)
	while seq and not seq.reached(phase) do
		if battle and battle.skip then
			seq.skip()
			break
		end
		task.wait()
	end
end

local function sideOf(uid: string?): any
	return if uid ~= nil and string.sub(uid, 1, 2) == "S1" then battle.mineSide else battle.theirsSide
end

-- Impacto suelto (fin de turno: quemadura, raíces, restauración…)
local function impactOn(e: any, uid: string?)
	local side = sideOf(uid)
	local r = ImpactVFXController.forEvent(e, nil, side.creature, { owner = battle })
	if r.reaction then
		side.anim:trigger(r.reaction)
	end
	if r.shake > 0 then
		battle.director:shake(r.shake)
	end
end

-- Estados que se ven en la postura: aturdido/paralizado/dormido y cansado
local function syncHolds(snapshot: any)
	for index, side in ipairs({ battle.mineSide, battle.theirsSide }) do
		local c = combatant(snapshot, index)
		if c then
			local st = c.statuses or {}
			local stunned = (st.Stun or 0) > 0 or (st.Paralysis or 0) > 0 or (st.Sleep or 0) > 0
			side.anim:hold(if c.fainted then "Defeat" elseif stunned then "Stun" else nil)
		end
	end
end

local function playTurn(payload: any)
	battle.skip = false -- saltar vale para el turno que se está viendo
	for i, e in ipairs(payload.events) do
		local caption: string? = nil
		local isMine = function(uid: string?): boolean
			return uid ~= nil and string.sub(uid, 1, 2) == "S1"
		end
		if e.t == "Move" then
			local mv = Abilities.ById[e.move]
			waitSeq(battle.seq, "Done")
			BattleController.render(string.format("%s usa <b>%s</b>", nameOf(e.actor), mv.name))
			local attacker = sideOf(e.actor)
			local target = if attacker == battle.mineSide then battle.theirsSide else battle.mineSide
			battle.seqMine = isMine(e.actor)
			battle.seq = CombatVFXController.play({
				move = mv,
				attacker = attacker,
				target = target,
				events = VFXPlan.moveGroup(payload.events, i),
				camera = battle.director,
			})
			if battle.skip then
				battle.seq.skip()
			end
			-- Las cifras y los textos salen en el impacto
			waitSeq(battle.seq, "Impact")
		elseif e.t == "Damage" then
			floater(
				isMine(e.target),
				"-" .. tostring(e.amount),
				if e.crit then Kit.Color.copalGlow else Kit.Color.cream
			)
			caption = if e.crit
				then "¡Golpe crítico!"
				elseif e.eff == "Strong" then "¡Es muy eficaz!"
				elseif e.eff == "Weak" then "No es muy eficaz…"
				else nil
		elseif e.t == "Heal" then
			floater(isMine(e.target), "+" .. tostring(e.amount), Kit.Color.ok)
			caption = nameOf(e.target) .. " recupera vida"
		elseif e.t == "Status" then
			caption = string.format("%s: %s", nameOf(e.target), STATUS[e.status] or e.status)
		elseif e.t == "StatusTick" then
			impactOn(e, e.target)
			floater(isMine(e.target), "-" .. tostring(e.amount), Kit.Color.clay)
		elseif e.t == "Skip" then
			impactOn(e, e.actor)
			caption = string.format("%s no puede actuar", nameOf(e.actor))
		elseif e.t == "Block" then
			caption = string.format("¡%s bloquea el golpe!", nameOf(e.target))
		elseif e.t == "Miss" then
			caption = nameOf(e.actor) .. " falla"
		elseif e.t == "Faint" then
			sideOf(e.target).anim:hold("Defeat")
			caption = if isMine(e.target) then nameOf(e.target) .. " está cansado" else "¡La niebla gris se debilita!"
		elseif e.t == "Switch" then
			local c = combatantByUid(e.to)
			if c then
				local foeSide = e.side == 2
				waitSeq(battle.seq, "Done")
				local old = if foeSide then battle.theirs else battle.mine
				old:destroy()
				local fresh = buildFor(c, foeSide)
				if foeSide then
					battle.theirs = fresh
					battle.theirsSide = sideFor(fresh, c.uid)
				else
					battle.mine = fresh
					battle.mineSide = sideFor(fresh, c.uid)
				end
				caption = if foeSide
					then "¡Otro Opaco entra en combate!"
					else Kit.escape(c.name) .. " entra en combate"
			end
		elseif e.t == "Roots" then
			impactOn(e, e.target)
			caption = "🌿 Las raíces curan a " .. nameOf(e.target)
		elseif e.t == "RootsCut" then
			floater(isMine(e.target), "✂ raíces", Kit.Color.copalGlow)
			caption = "✂ ¡Raíces cortadas! " .. nameOf(e.target) .. " ya no se curará"
		elseif e.t == "RootsEnd" then
			caption = nameOf(e.target) .. " arranca sus raíces"
		elseif e.t == "Phase" then
			dimLights(true)
			caption = "🏮 " .. tostring(e.text)
		elseif e.t == "Restored" then
			caption = "✨ ¡El monstruo recupera su color!"
			waitSeq(battle.seq, "Done")
			for k = 10, 0, -1 do
				CreatureBuilder.setOpaco(battle.theirs, k / 10)
				pause(0.08)
			end
			battle.theirsSide.anim:hold(nil)
			battle.theirsSide.anim:trigger("Happy")
			impactOn(e, e.target)
		end
		if caption then
			BattleController.render(caption)
			pause(0.65)
		end
	end
	waitSeq(battle.seq, "Done")
	syncHolds(payload.snapshot)
	battle.snapshot = payload.snapshot
	battle.snapshot.options = payload.snapshot.options
	battle.busy = false
	BattleController.render(nil)
end

local function finish(payload: any)
	local text = if payload.won
		then "¡Victoria! Nadie muere en NEXORA: el Opaco fue restaurado."
		elseif payload.reason == "Forfeit" then "Te retiras para entrenar."
		else "Tu monstruo necesita descansar. ¡Inténtalo de nuevo!"
	waitSeq(battle.seq, "Done")
	-- Victoria: el monstruo celebra con copal; derrota: queda cansado (nunca dramático)
	if payload.won then
		battle.mineSide.anim:hold("Victory")
		ImpactVFXController.play({ "Victory" }, { creature = battle.mine }, { owner = battle })
	elseif payload.reason ~= "Forfeit" then
		battle.mineSide.anim:hold("Defeat")
	end
	BattleController.render(text)
	pause(1.6)
	table.clear(queue)
	battle.loop:Disconnect()
	battle.director:clear()
	battle.mine:destroy()
	battle.theirs:destroy()
	dimLights(false)
	battle = nil
	gui.Enabled = false
	gui:ClearAllChildren()
	fx:ClearAllChildren()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	local character = Players.LocalPlayer.Character
	if character then
		camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
	end
	hooks.suspendWorld(false)
	hooks.setHud(true)
	if payload.won and payload.result and hooks.showStageResult then
		hooks.showStageResult(payload)
	elseif payload.result and payload.result.rewardId then
		hooks.showReward(payload.result.rewardId)
	end
end

function BattleController.pump()
	if playing or not battle then
		return
	end
	playing = true
	task.spawn(function()
		while #queue > 0 do
			local item = table.remove(queue, 1)
			if item.kind == "turn" then
				playTurn(item.payload)
			elseif item.kind == "end" then
				finish(item.payload)
				break
			end
		end
		playing = false
	end)
end

function BattleController.active(): boolean
	return battle ~= nil
end

return BattleController
