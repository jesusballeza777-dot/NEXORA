--!strict
-- Accesos rápidos (Genesis F2 §16): llegar a cada función sin caminar hasta su estación.
-- Las estaciones físicas alrededor del Gran Nexo abren las mismas pantallas.

local Kit = require(script.Parent.Kit)
local Modals = require(script.Parent.Modals)
local State = require(script.Parent.Parent.State)
local Collection = require(script.Parent.Screens.Collection)
local Breeding = require(script.Parent.Screens.Breeding)
local Adventure = require(script.Parent.Screens.Adventure)
local SanctuaryPlus = require(script.Parent.Screens.SanctuaryPlus)
local EffectsSettings = require(script.Parent.Screens.EffectsSettings)

local QuickMenu = {}

local function badge(n: number): string
	return if n > 0 then string.format("  (%d)", n) else ""
end

function QuickMenu.open(openTree: () -> (), openSanctuary: () -> ())
	local view = State.view
	if not view then
		return
	end
	local readyEggs, questsReady = 0, 0
	for _, slot in ipairs(view.incubators) do
		if slot.ready then
			readyEggs += 1
		end
	end
	for _, q in ipairs(view.quests.daily) do
		if q.complete and not q.claimed then
			questsReady += 1
		end
	end
	local achievementsReady = 0
	for _, a in ipairs(view.achievements or {}) do
		if a.rewardPending then
			achievementsReady += 1
		end
	end
	local entries = {
		{ "🗺", "Aventura", Adventure.map, 0 },
		{
			"📖",
			"Álbum",
			function()
				Collection.album(nil, nil)
			end,
			0,
		},
		{ "🥚", "Criadero", Breeding.incubator, readyEggs },
		{ "🎁", "Cofres", Breeding.chests, #view.chests },
		{ "📋", "Encargos", Breeding.quests, questsReady },
		{ "📜", "Códice", Collection.codex, 0 },
		{ "🏅", "Logros", Collection.achievements, achievementsReady },
		{ "🏡", "Santuario", openSanctuary, 0 },
		{ "🪴", "Decorar", SanctuaryPlus.decor, 0 },
		{ "🏆", "Vitrina", SanctuaryPlus.showcase, 0 },
		{ "🌳", "Árbol", openTree, #view.pendingRewards },
		{ "🕘", "Historial", Breeding.history, 0 },
		{ "✨", "Efectos", EffectsSettings.open, 0 },
	}
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Gran Nexo")
		local grid = Kit.new("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = ui.order(),
			Parent = content,
			Kit.new("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 64), CellPadding = UDim2.fromOffset(10, 10) }),
		})
		for _, e in ipairs(entries) do
			Kit.button(e[1] .. "  " .. e[2] .. badge(e[4]), if e[4] > 0 then "primary" else "secondary", e[3], {
				Parent = grid,
			})
		end
	end)
end

return QuickMenu
